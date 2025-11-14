//
//  NotesViewModel.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 29.10.2025.
//
import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class NotesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var notes: [JournalNote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Dependencies
    private let firebaseService = FirebaseService.shared
    
    // MARK: - Constants
    private let maxImageSize: CGFloat = 800
    private let imageQuality: CGFloat = 0.4
    private let maxBase64Size = 800_000 
    
    // MARK: - Public Methods
    
    func loadNotes() async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let fetchedNotes = try await fetchNotes()
            notes = fetchedNotes.sorted { $0.date > $1.date }
            print(" \(notes.count) not yüklendi")
        } catch {
            errorMessage = "Notes could not be loaded: \(error.localizedDescription)"
            showError = true
            print("Notlar yüklenemedi: \(error)")
        }
        
        isLoading = false
    }
    
    func addNote(text: String, imageData: Data?, audioURL: URL?) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Note text cannot be empty"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            guard let userId = getCurrentUserId() else {
                throw NotesError.userNotAuthenticated
            }

            var imageBase64: String? = nil
            if let imageData = imageData {
                imageBase64 = try compressAndEncodeImage(data: imageData)
                let imageSize = imageBase64?.count ?? 0
                if imageSize > maxBase64Size {
                    throw NotesError.imageTooLarge
                }
            }

            var audioBase64: String? = nil
            if let audioURL = audioURL {
                
                guard FileManager.default.fileExists(atPath: audioURL.path) else {
                    throw NotesError.audioFileNotFound
                }
                
                let audioData = try Data(contentsOf: audioURL)
                let audioSize = audioData.count

                if audioSize > 500_000 {
                    throw NotesError.audioTooLarge
                }
                
                audioBase64 = audioData.base64EncodedString()
                try? FileManager.default.removeItem(at: audioURL)
            }
            
            let totalSize = (imageBase64?.count ?? 0) + (audioBase64?.count ?? 0)
            
            if totalSize > maxBase64Size {
                throw NotesError.mediaTooLarge
            }

            let note = JournalNote(
                userId: userId,
                text: text,
                imageBase64: imageBase64,
                audioBase64: audioBase64
            )
            
            try await saveNote(note)

            await loadNotes()
            
        } catch NotesError.imageTooLarge {
            errorMessage = "The image is too large. Please choose a smaller image."
            showError = true
        } catch NotesError.audioTooLarge {
            errorMessage = "Audio recording is too long. Maximum duration is 30 seconds."
            showError = true
        } catch NotesError.mediaTooLarge {
            errorMessage = "Image and audio together are too large. Add only one or use smaller files."
            showError = true
        } catch {
            errorMessage = "Note could not be added: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func deleteNote(_ note: JournalNote) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                firebaseService.deleteNote(note) { result in
                    switch result {
                    case .success():
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            await loadNotes()
            
        } catch {
            errorMessage = "Note could not be deleted: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Private Helper Methods
    
    private func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    private func fetchNotes() async throws -> [JournalNote] {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.fetchNotes { result in
                switch result {
                case .success(let notes):
                    continuation.resume(returning: notes)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func compressAndEncodeImage(data: Data) throws -> String? {
        guard let image = UIImage(data: data) else {
            throw NotesError.invalidImageData
        }
        let resizedImage = resizeImage(image: image, maxSize: maxImageSize)

        guard let compressedData = resizedImage.jpegData(compressionQuality: imageQuality) else {
            throw NotesError.imageCompressionFailed
        }
        
        var finalData = compressedData
        var quality = imageQuality
        
        while finalData.count > 400_000 && quality > 0.1 {
            quality -= 0.1
            if let newData = resizedImage.jpegData(compressionQuality: quality) {
                finalData = newData
            } else {
                break
            }
        }
        
        return finalData.base64EncodedString()
    }
    
    private func resizeImage(image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size

        if size.width <= maxSize && size.height <= maxSize {
            return image
        }

        let ratio = size.width / size.height
        var newSize: CGSize
        
        if ratio > 1 {
            newSize = CGSize(width: maxSize, height: maxSize / ratio)
        } else {
            newSize = CGSize(width: maxSize * ratio, height: maxSize)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func saveNote(_ note: JournalNote) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            firebaseService.addNote(note) { result in
                switch result {
                case .success():
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Custom Errors
    enum NotesError: LocalizedError {
        case userNotAuthenticated
        case emptyText
        case audioFileNotFound
        case invalidImageData
        case imageCompressionFailed
        case imageTooLarge
        case audioTooLarge
        case mediaTooLarge
        
        var errorDescription: String? {
             switch self {
             case .userNotAuthenticated:
                 return "User authentication not found"
             case .emptyText:
                 return "Note text cannot be empty"
             case .audioFileNotFound:
                 return "Audio file not found"
             case .invalidImageData:
                 return "Invalid image format"
             case .imageCompressionFailed:
                 return "Image could not be compressed"
             case .imageTooLarge:
                 return "Image is too large (max 800KB)"
             case .audioTooLarge:
                 return "Audio recording is too long (max 30 seconds)"
             case .mediaTooLarge:
                 return "Image and audio together are too large. Add only one."
             }
        }
    }
}
