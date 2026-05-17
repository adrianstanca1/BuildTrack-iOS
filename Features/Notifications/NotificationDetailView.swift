import SwiftUI

struct NotificationDetailView: View {
    let notification: AppNotification
    @Environment(\.dismiss) private var dismiss
    @State private var isRead: Bool

    init(notification: AppNotification) {
        self.notification = notification
        self._isRead = State(initialValue: notification.isRead)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(notificationColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.type.rawValue.capitalized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(notification.title)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)

                // Status
                HStack {
                    Image(systemName: isRead ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isRead ? .green : .orange)
                    Text(isRead ? "Read" : "Unread")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isRead ? .green : .orange)

                    Spacer()

                    Text(notification.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)

                // Body
                DetailCard(title: "Message") {
                    Text(notification.body)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 16)

                // Actions
                if !isRead {
                    Button {
                        isRead = true
                        // TODO: Mark as read in repository
                    } label: {
                        Label("Mark as Read", systemImage: "checkmark.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(BuildTrackColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Notification")
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
    let notification = AppNotification(
        title: "Task Assigned",
        body: "You have been assigned to the foundation pour task on Site A. Please review the task details and confirm your availability.",
        type: .task,
        isRead: false,
        createdAt: Date()
    )
    return NavigationStack {
        NotificationDetailView(notification: notification)
    }
}
