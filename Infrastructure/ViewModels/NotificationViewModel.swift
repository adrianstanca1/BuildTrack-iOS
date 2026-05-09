import SwiftUI

@MainActor
@Observable
final class NotificationViewModel {
    private(set) var notifications: [AppNotification] = []
    private(set) var unreadCount = 0
    private(set) var isLoading = false
    var showUnreadOnly = false
    
    private let pushService = PushNotificationService.shared
    
    var filteredNotifications: [AppNotification] {
        showUnreadOnly ? notifications.filter { !$0.isRead } : notifications
    }
    
    var groupedNotifications: [(String, [AppNotification])] {
        let calendar = Calendar.current
        let filtered = filteredNotifications.sorted { $0.createdAt > $1.createdAt }
        
        let groups = Dictionary(grouping: filtered) { notification -> String in
            if calendar.isDateInToday(notification.createdAt) { return "Today" }
            if calendar.isDateInYesterday(notification.createdAt) { return "Yesterday" }
            if calendar.isDate(notification.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            }
            return "Earlier"
        }
        
        let order = ["Today", "Yesterday", "This Week", "Earlier"]
        return order.compactMap { key in
            guard let items = groups[key], !items.isEmpty else { return nil }
            return (key, items)
        }
    }
    
    func loadNotifications() async {
        isLoading = true
        
        // Load demo data + pending push notifications
        await pushService.refreshPendingNotifications()
        let pending = pushService.pendingNotifications
        
        let demo = createDemoNotifications()
        
        self.notifications = (demo + pending).sorted { $0.createdAt > $1.createdAt }
        self.unreadCount = notifications.filter { !$0.isRead }.count
        self.isLoading = false
    }
    
    func markAsRead(_ notification: AppNotification) {
        guard let idx = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        let updated = AppNotification(
            id: notification.id, title: notification.title, body: notification.body,
            type: notification.type, isRead: true,
            createdAt: notification.createdAt, relatedId: notification.relatedId
        )
        notifications[idx] = updated
        unreadCount = max(0, unreadCount - 1)
    }
    
    func markAllRead() {
        notifications = notifications.map {
            AppNotification(
                id: $0.id, title: $0.title, body: $0.body,
                type: $0.type, isRead: true,
                createdAt: $0.createdAt, relatedId: $0.relatedId
            )
        }
        unreadCount = 0
    }
    
    func deleteNotification(_ notification: AppNotification) {
        if !notification.isRead { unreadCount = max(0, unreadCount - 1) }
        notifications.removeAll { $0.id == notification.id }
        pushService.cancelNotification(identifier: notification.id.uuidString)
    }
    
    func clearAll() {
        notifications.removeAll()
        unreadCount = 0
        pushService.cancelAllPending()
        pushService.clearBadge()
    }
    
    func handleDeepLink(_ url: String) -> (screen: String, id: UUID?)? {
        // buildtrack://task/{id}
        // buildtrack://project/{id}
        // buildtrack://incident/{id}
        // buildtrack://inspection/{id}
        let components = url.replacingOccurrences(of: "buildtrack://", with: "").split(separator: "/")
        guard components.count >= 2 else { return nil }
        let screen = String(components[0])
        let id = UUID(uuidString: String(components[1]))
        return (screen, id)
    }
    
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        unreadCount += 1
    }
    
    private func createDemoNotifications() -> [AppNotification] {
        let now = Date()
        return [
            AppNotification(
                title: "Safety Inspection Due",
                body: "High-rise Tower project needs inspection by Friday.",
                type: .warning, isRead: false,
                createdAt: now.addingTimeInterval(-1800)
            ),
            AppNotification(
                title: "Task Completed",
                body: "Foundation pour completed at Riverside Complex.",
                type: .success, isRead: false,
                createdAt: now.addingTimeInterval(-3600)
            ),
            AppNotification(
                title: "Incident Reported",
                body: "Minor incident at Downtown Office — slip and fall near entrance.",
                type: .incident, isRead: false,
                createdAt: now.addingTimeInterval(-7200)
            ),
            AppNotification(
                title: "Project Update",
                body: "City Mall renovation is now 75% complete and on schedule.",
                type: .info, isRead: true,
                createdAt: now.addingTimeInterval(-86400)
            ),
            AppNotification(
                title: "Certification Expiring",
                body: "John Smith's forklift certification expires next month.",
                type: .warning, isRead: true,
                createdAt: now.addingTimeInterval(-86400 * 2)
            ),
            AppNotification(
                title: "Budget Alert",
                body: "Highway Overpass project has exceeded 90% of allocated budget.",
                type: .error, isRead: false,
                createdAt: now.addingTimeInterval(-86400 * 3)
            ),
            AppNotification(
                title: "Worker Added",
                body: "Maria Garcia has been added to the Suburban Housing team.",
                type: .success, isRead: true,
                createdAt: now.addingTimeInterval(-86400 * 4)
            ),
            AppNotification(
                title: "Task Reminder",
                body: "Review structural plans for the Bridge Project — due tomorrow.",
                type: .task, isRead: false,
                createdAt: now.addingTimeInterval(-86400 * 5)
            ),
        ]
    }
}
