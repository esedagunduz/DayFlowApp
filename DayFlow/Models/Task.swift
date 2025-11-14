
import Foundation
import SwiftUI

struct Task: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var note: String?
    var priority: Priority
    var isCompleted: Bool
    var dueDate: Date?
    var iconName: String
    var estimatedMinutes: Int?
    var effort: Effort
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        priority: Priority = .normal,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        iconName: String = "book.fill",
        estimatedMinutes: Int? = nil,
        effort: Effort = .medium,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.priority = priority
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.iconName = iconName
        self.estimatedMinutes = estimatedMinutes
        self.effort = effort
        self.createdAt = createdAt
    }
    
    // MARK: - Priority Enum
    enum Priority: Int, CaseIterable, Identifiable, Codable {
        case low = 0      // ✅ Core ML: 0
        case normal = 1   // ✅ Core ML: 1
        case high = 2     // ✅ Core ML: 2
        case urgent = 3   // ✅ Core ML: 3
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
        var tint: Color {
            switch self {
            case .low: return Color.gray.opacity(0.3)
            case .normal: return Color.blue.opacity(0.3)
            case .high: return Color.orange.opacity(0.3)
            case .urgent: return Color.red.opacity(0.3)
            }
        }
    }
    
    // MARK: - Effort Enum

    enum Effort: Int, CaseIterable, Identifiable, Codable {
        case low = 0
        case medium = 1
        case high = 2     
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .low: return "Easy"
            case .medium: return "Medium"
            case .high: return "Hard"
            }
        }
        
    }
}

// MARK: - Hashable Conformance
extension Task: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Firebase Extensions
extension Task {
    init?(from dictionary: [String: Any], id: String) {
        guard let title = dictionary["title"] as? String,
              let priorityRaw = dictionary["priority"] as? Int,
              let priority = Priority(rawValue: priorityRaw),
              let isCompleted = dictionary["isCompleted"] as? Bool,
              let iconName = dictionary["iconName"] as? String,
              let effortRaw = dictionary["effort"] as? Int,
              let effort = Effort(rawValue: effortRaw),
              let createdAtTimestamp = dictionary["createdAt"] as? Double else {
            return nil
        }
        
        self.id = UUID(uuidString: id) ?? UUID()
        self.title = title
        self.note = dictionary["note"] as? String
        self.priority = priority
        self.isCompleted = isCompleted
        self.iconName = iconName
        self.estimatedMinutes = dictionary["estimatedMinutes"] as? Int
        self.effort = effort
        self.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        
        if let dueTimestamp = dictionary["dueDate"] as? Double {
            self.dueDate = Date(timeIntervalSince1970: dueTimestamp)
        } else {
            self.dueDate = nil
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "priority": priority.rawValue,
            "isCompleted": isCompleted,
            "iconName": iconName,
            "effort": effort.rawValue,
            "createdAt": createdAt.timeIntervalSince1970
        ]
        
        if let note = note {
            dict["note"] = note
        }
        
        if let dueDate = dueDate {
            dict["dueDate"] = dueDate.timeIntervalSince1970
        }
        
        if let minutes = estimatedMinutes {
            dict["estimatedMinutes"] = minutes
        }
        
        return dict
    }
}
