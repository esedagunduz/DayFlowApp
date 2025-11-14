//
//  JournalNote.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 29.10.2025.

import Foundation
import UIKit


struct JournalNote: Identifiable, Equatable, Codable {
    var id: UUID
    var userId: String
    var date: Date
    var text: String
    
    var imageBase64: String?
    var audioBase64: String?
    
    // MARK: - Init
    init(
        id: UUID = UUID(),
        userId: String,
        date: Date = Date(),
        text: String,
        imageBase64: String? = nil,
        audioBase64: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.text = text
        self.imageBase64 = imageBase64
        self.audioBase64 = audioBase64
    }
    
    // MARK: - Helper Methods
    

    var decodedImage: UIImage? {
        guard let imageBase64 = imageBase64,
              let imageData = Data(base64Encoded: imageBase64) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    

    var decodedAudioData: Data? {
        guard let audioBase64 = audioBase64 else {
            return nil
        }
        return Data(base64Encoded: audioBase64)
    }
    

    var hasMedia: Bool {
        return imageBase64 != nil || audioBase64 != nil
    }
    
    var hasImage: Bool {
        return imageBase64 != nil
    }
    
    var hasAudio: Bool {
        return audioBase64 != nil
    }
}

// MARK: - Codable Keys
extension JournalNote {
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case text
        case imageBase64
        case audioBase64
    }
}
