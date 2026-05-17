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

// MARK: - Embedded Notification Detail View

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
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                HStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(notificationColor.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(notificationColor)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(notification.title)
                            .font(DesignTokens.Typography.title3)
                            .foregroundStyle(BuildTrackColors.textPrimary)
                        
                        Text(notification.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                        
                        ProBadge(text: notification.type.label, color: notificationTypeColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                
                // Message
                if !notification.message.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Message")
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.textSecondary)
                        
                        Text(notification.message)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .professionalCard()
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                }
                
                // Actions
                HStack(spacing: DesignTokens.Spacing.md) {
                    if !isRead {
                        Button {
                            isRead = true
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Mark as Read")
                            }
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(BuildTrackColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                        }
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Close")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(BuildTrackColors.textTertiary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Notification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .info: return BuildTrackColors.info
        case .warning: return BuildTrackColors.warning
        case .success: return BuildTrackColors.success
        case .error: return BuildTrackColors.danger
        case .task: return BuildTrackColors.primary
        case .incident: return BuildTrackColors.danger
        }
    }
    
    private var notificationTypeColor: Color {
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
