import SwiftUI

struct StatCard: View {
    let icon: String
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(Color(.label))
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct StatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(BuildTrackColors.statusColor(status))
                .frame(width: 8, height: 8)
            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(BuildTrackColors.statusColor(status))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(BuildTrackColors.statusColor(status).opacity(0.12))
        .clipShape(Capsule())
    }
}

struct RFIStatusBadge: View {
    let status: RFIStatus
    
    var color: Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .closed: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct DrawingStatusBadge: View {
    let status: DrawingStatus
    
    var color: Color {
        switch status {
        case .active: return .green
        case .superseded: return .orange
        case .archived: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority?
    let text: String?
    let color: Color?
    
    init(priority: TaskPriority) {
        self.priority = priority
        self.text = nil
        self.color = nil
    }
    
    init(text: String, color: Color) {
        self.priority = nil
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text ?? priority?.label ?? "")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color ?? BuildTrackColors.priorityColor(priority ?? .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((color ?? BuildTrackColors.priorityColor(priority ?? .medium)).opacity(0.12))
            .clipShape(Capsule())
    }
}

struct SeverityBadge: View {
    let severity: IncidentSeverity
    
    var color: Color {
        switch severity {
        case .low: .yellow
        case .medium: .orange
        case .high: .red
        case .critical: .purple
        }
    }
    
    var body: some View {
        Text(severity.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct SectionHeader: View {
    let title: String
    var actionLabel: String?
    var action: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline)
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : BuildTrackColors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? BuildTrackColors.primary : BuildTrackColors.primary.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : BuildTrackColors.primary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            StatCard(icon: "hammer.fill", label: "Active Projects", value: 12, color: .green)
            StatCard(icon: "list.clipboard", label: "Today's Tasks", value: 8, color: .blue)
        }
        StatusBadge(status: .active)
        PriorityBadge(priority: .high)
        SeverityBadge(severity: .high)
        FilterChip(label: "All", isSelected: true) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

struct ResultBadge: View {
    let result: InspectionResult
    
    var body: some View {
        Text(result.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(resultColor)
            )
    }
    
    private var resultColor: Color {
        switch result {
        case .pass: BuildTrackColors.success
        case .fail: BuildTrackColors.danger
        case .conditional: BuildTrackColors.warning
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color(.label))
            Text(title)
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(12)
        .frame(width: 120)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    let valueColor: Color?
    
    init(icon: String, label: String, value: String, valueColor: Color? = nil) {
        self.icon = icon
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 32, height: 32)
                .background(BuildTrackColors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(valueColor ?? Color(.label))
            }
            Spacer()
        }
    }
}

// MARK: - Project Picker

struct ProjectPicker: View {
    @Binding var selectedProject: Project?
    let projects: [Project]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedProject = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("None")
                            if selectedProject == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundStyle(BuildTrackColors.primary)
                            }
                        }
                    }
                }
                Section("Projects") {
                    ForEach(projects) { project in
                        Button {
                            selectedProject = project
                            dismiss()
                        } label: {
                            HStack {
                                Text(project.name)
                                if selectedProject?.id == project.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(BuildTrackColors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ModernFilterChip
struct ModernFilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = BuildTrackColors.primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : color.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}
