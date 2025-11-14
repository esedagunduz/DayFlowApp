//
//  NotificationService.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 2.11.2025.
//
import Foundation
import UserNotifications


final class NotificationService {
    
    // MARK: - Singleton
    static let shared = NotificationService()
    private init() {}
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print(" Bildirim izni hatası: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print(granted ? " Bildirim izni verildi" : " Bildirim izni reddedildi")
                    completion(granted)
                }
            }
        }
    }

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleNotification(for task: Task, reminderDate: Date) {
        guard let taskDueDate = task.dueDate ?? task.createdAt as Date? else {
            print("Görev tarihi bulunamadı")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Reminder🔔"
        content.body = task.title
        content.sound = .default
        content.badge = 1

        content.userInfo = [
            "taskId": task.id.uuidString,
            "taskTitle": task.title,
            "priority": task.priority.rawValue
        ]
        
        if task.priority == .urgent {
            content.categoryIdentifier = "URGENT_TASK"
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
  
        let identifier = "task_\(task.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        

        notificationCenter.add(request) { error in
            if let error = error {
                print(" Bildirim planlama hatası: \(error.localizedDescription)")
            } else {
                print(" Bildirim planlandı: \(task.title) - \(reminderDate)")
            }
        }
    }
    
 
    func cancelNotification(for task: Task) {
        let identifier = "task_\(task.id.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print(" Bildirim iptal edildi: \(task.title)")
    }
    

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print(" Tüm bildirimler iptal edildi")
    }

    func listPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print(" Bekleyen bildirimler: \(requests.count)")
            requests.forEach { request in
                print("  - \(request.identifier): \(request.content.body)")
            }
        }
    }
    
    // MARK: - Quick Reminder Options

    enum ReminderOption: String, CaseIterable {
        case at_time = "At time"
        case minutes_15 = "15 minutes before"
        case minutes_30 = "30 minutes before"
        case hour_1 = "1 hour before"
        case hours_3 = "3 hours before"
        case day_1 = "1 day before"

        
        var timeInterval: TimeInterval {
            switch self {
            case .at_time: return 0
            case .minutes_15: return -15 * 60
            case .minutes_30: return -30 * 60
            case .hour_1: return -60 * 60
            case .hours_3: return -3 * 60 * 60
            case .day_1: return -24 * 60 * 60
            }
        }
        
        var icon: String {
            switch self {
            case .at_time: return "clock"
            case .minutes_15, .minutes_30: return "clock.badge.exclamationmark"
            case .hour_1, .hours_3: return "bell"
            case .day_1: return "calendar.badge.clock"
            }
        }
    }

    func scheduleQuickReminder(for task: Task, option: ReminderOption) {
        guard let dueDate = task.dueDate else {
            print(" Görev bitiş tarihi yok")
            return
        }
        
        let reminderDate = dueDate.addingTimeInterval(option.timeInterval)

        if reminderDate < Date() {
            print("Hatırlatıcı tarihi geçmişte")
            return
        }
        
        scheduleNotification(for: task, reminderDate: reminderDate)
    }
}

// MARK: - AppDelegate Integration Helper

extension NotificationService {

    func handleNotificationResponse(_ response: UNNotificationResponse, completion: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let taskId = userInfo["taskId"] as? String {
            print("Bildirime tıklandı - Task ID: \(taskId)")
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenTaskDetail"),
                object: nil,
                userInfo: ["taskId": taskId]
            )
        }
        
        completion()
    }
}
