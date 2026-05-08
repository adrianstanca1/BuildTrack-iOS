import SwiftUI

struct NotificationInboxView: View {
    @State private var notifications: [AppNotification] = []
    @State private var showUnreadOnly = false
    
    var grouped: [(String, [AppNotification])] {
        let filtered = showUnreadOnly ? notifications.filter { !$0.isRead } : notifications
        let calendar = Calendar.current
        
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
            if let items = groups[key], !items.isEmpty {
                return (key, items.sorted { $0.createdAt > $1.createdAt })
            }
            return nil
        }
    }
    
    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
    
    var body: some View {
        List {
            if notifications.isEmpty {
                ContentUnavailableView(
                    "No Notifications",
                    systemImage: "bell.slash",
                    description: Text("You'll see alerts and updates here")
                )
            }
            
            ForEach(grouped, id: \.0) { section in
                Section(section.0) {
                    ForEach(section.1) { notification in
                        NotificationRow(notification: notification)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    remove(notification)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button(notification.isRead ? "Unread" : "Read") {
                                    toggleRead(notification)
                                }
                                .tint(notification.isRead ? .orange : .blue)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation { showUnreadOnly.toggle() }
                } label: {
                    Image(systemName: showUnreadOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if unreadCount > 0 {
                    Button("Mark All Read") { markAllRead() }
                        .font(.caption)
                }
            }
        }
        .onAppear { loadDemo() }
    }
    
    func toggleRead(_ notification: AppNotification) {
        if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
            var updated = notification
            updated = AppNotification(
                id: updated.id, title: updated.title, body: updated.body,
                type: updated.type, isRead: !updated.isRead,
                createdAt: updated.createdAt, relatedId: updated.relatedId
            )
            notifications[idx] = updated
        }
    }
    
    func markAllRead() {
        notifications = notifications.map {
            AppNotification(id: $0.id, title: $0.title, body: $0.body, type: $0.type,
                          isRead: true, createdAt: $0.createdAt, relatedId: $0.relatedId)
        }
    }
    
    func remove(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
    }
    
    func loadDemo() {
        let now = Date()
        notifications = [
            AppNotification(
                title: "Safety Inspection Due", body: "High-rise Tower project needs inspection by Friday.",
                type: .warning, isRead: false,
                createdAt: now.addingTimeInterval(-3600), relatedId: nil
            ),
            AppNotification(
                title: "Task Completed", body: "Foundation pour completed at Riverside Complex.",
                type: .success, isRead: false,
                createdAt: now.addingTimeInterval(-7200), relatedId: nil
            ),
            AppNotification(
                title: "Incident Reported", body: "Minor incident at Downtown Office — slip and fall.",
                type: .incident, isRead: false,
                createdAt: now.addingTimeInterval(-14400), relatedId: nil
            ),
            AppNotification(
                title: "Project Update", body: "City Mall renovation is now 75% complete.",
                type: .info, isRead: true,
                createdAt: now.addingTimeInterval(-86400), relatedId: nil
            ),
            AppNotification(
                title: "Worker Certification", body: "John's forklift certification expires next month.",
                type: .warning, isRead: true,
                createdAt: now.addingTimeInterval(-172800), relatedId: nil
            ),
            AppNotification(
                title: "New Project Added", body: "Suburban Housing development added to your portfolio.",
                type: .success, isRead: true,
                createdAt: now.addingTimeInterval(-259200), relatedId: nil
            ),
            AppNotification(
                title: "Budget Alert", body: "Highway Overpass project has exceeded 90% of budget.",
                type: .error, isRead: false,
                createdAt: now.addingTimeInterval(-345600), relatedId: nil
            ),
        ]
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.title3)
                .foregroundStyle(typeColor)
                .frame(width: 36, height: 36)
                .background(typeColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if !notification.isRead {
                    Circle().fill(.blue).frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    var typeColor: Color {
        switch notification.type {
        case .info: .blue; case .warning: .orange; case .success: .green
        case .error: .red; case .task: .indigo; case .incident: .purple
        }
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(notification.createdAt)
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }
}

#Preview {
    NavigationStack { NotificationInboxView() }
}
