import SwiftUI

struct NotificationsListView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @State private var selectedNotification: AppNotification?

    var body: some View {
        NavigationStack {
            List(viewModel.notifications) { notification in
                NotificationRow(notification: notification)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedNotification = notification
                    }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .refreshable {
                await viewModel.loadNotifications()
            }
            .sheet(item: $selectedNotification) { notification in
                NavigationStack {
                    NotificationDetailView(notification: notification)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    selectedNotification = nil
                                }
                            }
                        }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.title2)
                .foregroundStyle(notificationColor)
                .frame(width: 40, height: 40)
                .background(notificationColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(notification.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.03))
    }

    private var notificationColor: Color {
        switch notification.type {
        case .info: return .blue
        case .warning: return .orange
        case .success: return .green
        case .error: return .red
        case .task: return .purple
        case .incident: return .red
        }
    }
}

#Preview {
    NotificationsListView()
}
