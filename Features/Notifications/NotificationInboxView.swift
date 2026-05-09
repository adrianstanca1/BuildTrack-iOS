import SwiftUI

// MARK: - Notifications Inbox (Redesigned)

struct NotificationInboxView: View {
    @State private var notifications: [AppNotification] = []
    @State private var filter: NotificationFilter = .all
    
    enum NotificationFilter: String, CaseIterable {
        case all, unread, task, incident, info
        
        var label: String {
            switch self {
            case .all: return "All"
            case .unread: return "Unread"
            case .task: return "Tasks"
            case .incident: return "Safety"
            case .info: return "Info"
            }
        }
    }
    
    var filteredNotifications: [AppNotification] {
        switch filter {
        case .all: return notifications
        case .unread: return notifications.filter { !$0.isRead }
        case .task: return notifications.filter { $0.type == .task }
        case .incident: return notifications.filter { $0.type == .incident }
        case .info: return notifications.filter { $0.type == .info }
        }
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(NotificationFilter.allCases, id: \.self) { f in
                            ModernFilterChip(
                                label: f == .unread && unreadCount > 0 ? "\(f.label) (\(unreadCount))" : f.label,
                                isSelected: filter == f
                            ) {
                                filter = f
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Notifications list
                LazyVStack(spacing: 10) {
                    if filteredNotifications.isEmpty {
                        EmptyStateView(
                            icon: "bell.slash",
                            title: "No Notifications",
                            message: "You're all caught up!"
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredNotifications) { notification in
                            ModernNotificationRow(notification: notification)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if unreadCount > 0 {
                    Button("Mark All") {
                        markAllAsRead()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
        .onAppear {
            loadDemoNotifications()
        }
    }
    
    private func markAllAsRead() {
        for index in notifications.indices {
            notifications[index] = AppNotification(
                id: notifications[index].id,
                title: notifications[index].title,
                body: notifications[index].body,
                type: notifications[index].type,
                isRead: true,
                createdAt: notifications[index].createdAt,
                relatedId: notifications[index].relatedId
            )
        }
    }
    
    private func loadDemoNotifications() {
        notifications = [
            AppNotification(
                id: UUID(),
                title: "Task Completed",
                body: "Foundation excavation has been marked as complete.",
                type: .task,
                isRead: false,
                createdAt: Date().addingTimeInterval(-3600),
                relatedId: nil
            ),
            AppNotification(
                id: UUID(),
                title: "Safety Alert",
                body: "Hard hat required zone has been updated on Site B.",
                type: .incident,
                isRead: false,
                createdAt: Date().addingTimeInterval(-7200),
                relatedId: nil
            ),
            AppNotification(
                id: UUID(),
                title: "Budget Update",
                body: "Project 'Downtown Office' has reached 75% of budget.",
                type: .info,
                isRead: true,
                createdAt: Date().addingTimeInterval(-86400),
                relatedId: nil
            ),
            AppNotification(
                id: UUID(),
                title: "New Task Assigned",
                body: "Electrical rough-in has been assigned to Mike Johnson.",
                type: .task,
                isRead: true,
                createdAt: Date().addingTimeInterval(-172800),
                relatedId: nil
            )
        ]
    }
}

// MARK: - Modern Notification Row

struct ModernNotificationRow: View {
    let notification: AppNotification
    @State private var isRead: Bool
    
    init(notification: AppNotification) {
        self.notification = notification
        _isRead = State(initialValue: notification.isRead)
    }
    
    var typeColor: Color {
        switch notification.type {
        case .info: return BuildTrackColors.primary
        case .warning: return BuildTrackColors.warning
        case .success: return BuildTrackColors.success
        case .error: return BuildTrackColors.danger
        case .task: return BuildTrackColors.info
        case .incident: return BuildTrackColors.danger
        }
    }
    
    var typeIcon: String {
        switch notification.type {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .task: return "list.clipboard.fill"
        case .incident: return "shield.exclamation"
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: typeIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(typeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(notification.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isRead ? BuildTrackColors.textSecondary : BuildTrackColors.textPrimary)
                    
                    if !isRead {
                        Circle()
                            .fill(BuildTrackColors.primary)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(BuildTrackColors.textSecondary)
                    .lineLimit(2)
                
                Text(notification.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(BuildTrackColors.textTertiary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        .opacity(isRead ? 0.7 : 1)
        .onTapGesture {
            isRead = true
        }
    }
}

#Preview {
    NavigationStack {
        NotificationInboxView()
    }
}
