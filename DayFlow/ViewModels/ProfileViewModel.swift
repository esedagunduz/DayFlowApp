//
//  ProfileViewModel.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 15.10.2025.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import UIKit

final class ProfileViewModel: ObservableObject {
    @Published var userEmail: String = ""
    @Published var userName: String = ""
    @Published var profileImageURL: URL?
    @Published var profileImage: UIImage?
    
    @Published var isLoading: Bool = false
    @Published var isUploadingImage: Bool = false
    
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    @Published var successMessage: String?
    @Published var showSuccess: Bool = false
    
    private let storage = Storage.storage()
    
    init() {
        loadUserData()
    }
    
    // MARK: - User Data
    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        userEmail = user.email ?? ""
        userName = user.displayName ?? ""
        
        if let photoURL = user.photoURL {
            profileImageURL = photoURL
        }
    }
    
    // MARK: - Profile Image Upload
    func uploadProfileImage(_ image: UIImage) {
        guard let user = Auth.auth().currentUser,
              let imageData = image.jpegData(compressionQuality: 0.5) else {
            handleError("Invalid image.")
            return
        }
        
        isUploadingImage = true
        
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(user.uid).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        profileImageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isUploadingImage = false
                    self?.handleError("Image upload failed: \(error.localizedDescription)")
                }
                return
            }
            
            profileImageRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    self?.isUploadingImage = false
                    
                    if let error = error {
                        self?.handleError("Failed to retrieve image URL: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let downloadURL = url else {
                        self?.handleError("Invalid download URL.")
                        return
                    }
                    
                    self?.updateUserProfile(photoURL: downloadURL)
                }
            }
        }
    }
    
    private func updateUserProfile(photoURL: URL) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.photoURL = photoURL
        
        changeRequest?.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError("Profile update failed: \(error.localizedDescription)")
                } else {
                    self?.profileImageURL = photoURL
                    self?.showSuccessMessage("Profile picture updated successfully.")
                }
            }
        }
    }
    
    // MARK: - Delete Profile Image
    func deleteProfileImage() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(user.uid).jpg")
        
        profileImageRef.delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleError("Image deletion failed: \(error.localizedDescription)")
                    return
                }

                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.photoURL = nil
                
                changeRequest?.commitChanges { error in
                    DispatchQueue.main.async {
                        if error == nil {
                            self?.profileImageURL = nil
                            self?.profileImage = nil
                            self?.showSuccessMessage("Profile picture deleted.")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Update Display Name
    func updateDisplayName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            handleError("Name cannot be empty.")
            return
        }
        
        isLoading = true
        
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = trimmed
        
        changeRequest?.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleError("Name update failed: \(error.localizedDescription)")
                } else {
                    self?.userName = trimmed
                    self?.showSuccessMessage("Name updated successfully.")
                }
            }
        }
    }
    
    // MARK: - Change Password
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            completion(.failure(.message("User not found.")))
            return
        }

        if currentPassword.isEmpty || newPassword.isEmpty {
            completion(.failure(.message("Password fields cannot be empty.")))
            return
        }
        
        if newPassword.count < 8 {
            completion(.failure(.message("New password must be at least 8 characters long.")))
            return
        }
        
        isLoading = true
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let _ = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(.failure(.message("Current password is incorrect.")))
                }
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        completion(.failure(.message(error.localizedDescription)))
                    } else {
                        self?.showSuccessMessage("Password changed successfully.")
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount(password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            completion(.failure(.message("User not found.")))
            return
        }
        
        isLoading = true
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let _ = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(.failure(.message("Incorrect password.")))
                }
                return
            }
            
            let storageRef = self?.storage.reference()
            let profileImageRef = storageRef?.child("profile_images/\(user.uid).jpg")
            profileImageRef?.delete { _ in }
            
            user.delete { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        completion(.failure(.message(error.localizedDescription)))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }
}
