
import SwiftUI
import FirebaseCore
import Firebase
import UserNotifications

// MARK: - AppDelegate (Bildirim + Firebase)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        

        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.requestAuthorization { granted in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        completionHandler([.banner, .sound, .badge])
    }
    
 
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationService.shared.handleNotificationResponse(response, completion: completionHandler)
    }
}

//
// MARK: - MAIN APP STRUCT

@main
struct DayFlowApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var tasksViewModel = TasksViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    if authViewModel.isEmailVerified {
                        ContentView()
                            .environmentObject(tasksViewModel)
                    } else {
                        EmailVerificationView()
                    }
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(authViewModel)
        }
    }
}
