//
//  FirebaseService.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 13.10.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirebaseService {
    
    // MARK: - Singleton
    static let shared = FirebaseService()
    private init() {}
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Collection References
    private var tasksCollection: CollectionReference? {
        guard let userId = currentUserId else { return nil }
        return db.collection("users").document(userId).collection("tasks")
    }
    
    // MARK: - Public Methods
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void) {
        guard let collection = tasksCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        collection.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let tasks = documents.compactMap { doc -> Task? in
                try? doc.data(as: Task.self)
            }
            
            completion(.success(tasks))
        }
    }
    
    func observeTasks(completion: @escaping (Result<[Task], Error>) -> Void) -> ListenerRegistration? {
        guard let collection = tasksCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return nil
        }
        
        return collection.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let tasks = documents.compactMap { doc -> Task? in
                try? doc.data(as: Task.self)
            }
            
            completion(.success(tasks))
        }
    }

    func addTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = tasksCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        do {
            try collection.document(task.id.uuidString).setData(from: task) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func updateTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = tasksCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        do {
            try collection.document(task.id.uuidString).setData(from: task, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func deleteTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = tasksCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        collection.document(task.id.uuidString).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteTasks(_ tasks: [Task], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = tasksCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        let batch = db.batch()
        
        tasks.forEach { task in
            let docRef = collection.document(task.id.uuidString)
            batch.deleteDocument(docRef)
        }
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// MARK: - Custom Errors
enum FirebaseError: LocalizedError {
    case userNotAuthenticated
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Kullanıcı girişi yapılmamış"
        case .invalidData:
            return "Geçersiz veri formatı"
        }
    }
}
// MARK: - Notes (Yeni Eklenen Kısım)

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension FirebaseService {
    
    private var notesCollection: CollectionReference? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(userId).collection("notes")
    }

    func fetchNotes(completion: @escaping (Result<[JournalNote], Error>) -> Void) {
        guard let collection = notesCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        collection.order(by: "date", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let notes = snapshot?.documents.compactMap { doc -> JournalNote? in
                try? doc.data(as: JournalNote.self)
            } ?? []
            completion(.success(notes))
        }
    }

    func addNote(_ note: JournalNote, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = notesCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        do {
            let doc = collection.document(note.id.uuidString)
            try doc.setData(from: note) { error in
                if let error = error {
                    print("Firestore kayıt hatası: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print(" Not Firestore'a kaydedildi")
                    completion(.success(()))
                }
            }
        } catch {
            print("Not encode hatası: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func updateNote(_ note: JournalNote, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = notesCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        do {
            try collection.document(note.id.uuidString).setData(from: note, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteNote(_ note: JournalNote, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = notesCollection else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        collection.document(note.id.uuidString).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Not silindi")
                completion(.success(()))
            }
        }
    }

    // MARK: - Base64 Encoding/Decoding Helpers

    func encodeToBase64(data: Data) -> String {
        return data.base64EncodedString()
    }

    func decodeFromBase64(string: String) -> Data? {
        return Data(base64Encoded: string)
    }

    func compressAndEncodeImage(data: Data, quality: CGFloat = 0.5) -> String? {
        guard let image = UIImage(data: data),
              let compressedData = image.jpegData(compressionQuality: quality) else {
            return nil
        }
        return compressedData.base64EncodedString()
    }
}
