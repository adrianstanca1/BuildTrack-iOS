import UIKit
import UserNotifications

@MainActor
final class PushNotificationService: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = PushNotificationService()
    
    @Published var isAuthorised = false
    @Published var deviceToken: Data?
    @Published var pendingNotifications: [AppNotification] = []
    @Published var badgeCount = 0
    
    let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Authorisation
    
    func requestAuthorisation() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            self.isAuthorised = granted
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
            return granted
        } catch {
            print("Notification auth error: \(error)")
            return false
        }
    }
    
    func checkAuthorisationStatus() async {
        let settings = await center.notificationSettings()
        self.isAuthorised = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }
    
    // MARK: - Categories
    
    func registerCategories() {
        let taskAction = UNNotificationAction(identifier: "VIEW_TASK", title: "View Task", options: .foreground)
        let completeAction = UNNotificationAction(identifier: "COMPLETE_TASK", title: "Mark Complete", options: [])
        
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, taskAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let viewAction = UNNotificationAction(identifier: "VIEW", title: "View", options: .foreground)
        let incidentCategory = UNNotificationCategory(
            identifier: "INCIDENT_ALERT",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        let inspectAction = UNNotificationAction(identifier: "VIEW_INSPECTION", title: "View", options: .foreground)
        let inspectionCategory = UNNotificationCategory(
            identifier: "INSPECTION_DUE",
            actions: [inspectAction],
            intentIdentifiers: [],
            options: []
        )
        
        let updateAction = UNNotificationAction(identifier: "VIEW_UPDATE", title: "View", options: .foreground)
        let projectCategory = UNNotificationCategory(
            identifier: "PROJECT_UPDATE",
            actions: [updateAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([taskCategory, incidentCategory, inspectionCategory, projectCategory])
    }
    
    // MARK: - Scheduling
    
    func scheduleTaskReminder(taskTitle: String, taskId: UUID, dueDate: Date, sound: UNNotificationSound? = .default) async {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "\(taskTitle) is due soon"
        content.sound = sound
        content.badge = NSNumber(value: badgeCount + 1)
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = [
            "task_id": taskId.uuidString,
            "type": "task",
            "deep_link": "buildtrack://task/\(taskId.uuidString)"
        ]
        
        // Reminder 1 hour before
        let reminderDate = dueDate.addingTimeInterval(-3600)
        guard reminderDate > Date() else { return }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "task-reminder-\(taskId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule task reminder: \(error)")
        }
    }
    
    func scheduleInspectionDue(inspectionTitle: String, inspectionId: UUID, dueDate: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Inspection Due"
        content.body = "\(inspectionTitle) is scheduled for \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        content.sound = .default
        content.badge = NSNumber(value: badgeCount + 1)
        content.categoryIdentifier = "INSPECTION_DUE"
        content.userInfo = [
            "inspection_id": inspectionId.uuidString,
            "type": "inspection",
            "deep_link": "buildtrack://inspection/\(inspectionId.uuidString)"
        ]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "inspection-due-\(inspectionId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule inspection: \(error)")
        }
    }
    
    func sendLocalNotification(title: String, body: String, type: NotificationType = .info, sound: UNNotificationSound? = .default) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.badge = NSNumber(value: badgeCount + 1)
        content.categoryIdentifier = "PROJECT_UPDATE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            badgeCount += 1
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
    
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllPending() {
        center.removeAllPendingNotificationRequests()
    }
    
    func clearBadge() {
        badgeCount = 0
        center.setBadgeCount(0) { _ in }
    }
    
    // MARK: - Pending Notifications
    
    func refreshPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        self.pendingNotifications = requests.map { request in
            let content = request.content
            let type: NotificationType = {
                switch content.categoryIdentifier {
                case "TASK_REMINDER": return .task
                case "INCIDENT_ALERT": return .incident
                case "INSPECTION_DUE": return .warning
                case "PROJECT_UPDATE": return .info
                default: return .info
                }
            }()
            
            return AppNotification(
                id: UUID(uuidString: request.identifier) ?? UUID(),
                title: content.title,
                body: content.body,
                type: type,
                isRead: false,
                createdAt: Date(),
                relatedId: content.userInfo["task_id"] as? String
                    ?? content.userInfo["inspection_id"] as? String
            )
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionId = response.actionIdentifier
        
        switch actionId {
        case "VIEW_TASK", "VIEW", "VIEW_UPDATE", "VIEW_INSPECTION":
            if let deepLink = userInfo["deep_link"] as? String {
                NotificationCenter.default.post(name: .deepLinkReceived, object: nil, userInfo: ["url": deepLink])
            }
        case "COMPLETE_TASK":
            if let taskId = userInfo["task_id"] as? String {
                NotificationCenter.default.post(name: .completeTaskFromNotification, object: nil, userInfo: ["task_id": taskId])
            }
        default:
            if let deepLink = userInfo["deep_link"] as? String {
                NotificationCenter.default.post(name: .deepLinkReceived, object: nil, userInfo: ["url": deepLink])
            }
        }
        
        badgeCount = max(0, badgeCount - 1)
        completionHandler()
    }
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
    static let completeTaskFromNotification = Notification.Name("completeTaskFromNotification")
}
