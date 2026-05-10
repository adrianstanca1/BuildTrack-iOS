import SwiftUI
import SwiftData

struct PunchItemsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PunchItem.createdAt, order: .reverse) private var punchItems: [PunchItem]

    @State private var viewModel = PunchItemViewModel()
    @State private var showAddPunchItem = false
    @State private var searchText = ""
    @State private var statusFilter: PunchItemStatus?
    @State private var severityFilter: PunchItemSeverity?

    var filteredItems: [PunchItem] {
        var result = punchItems
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        if let severity = severityFilter {
            result = result.filter { $0.severity == severity }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    TextField("Search punch items...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Status filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ModernFilterChip(label: "All", isSelected: statusFilter == nil) {
                            statusFilter = nil
                        }
                        ForEach(PunchItemStatus.allCases, id: \.self) { status in
                            ModernFilterChip(
                                label: status.label,
                                isSelected: statusFilter == status,
                                color: statusColor(status)
                            ) {
                                statusFilter = status == statusFilter ? nil : status
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Severity filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ModernFilterChip(label: "All Severities", isSelected: severityFilter == nil) {
                            severityFilter = nil
                        }
                        ForEach(PunchItemSeverity.allCases, id: \.self) { severity in
                            ModernFilterChip(
                                label: severity.label,
                                isSelected: severityFilter == severity,
                                color: severityColor(severity)
                            ) {
                                severityFilter = severity == severityFilter ? nil : severity
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Items
                LazyVStack(spacing: 12) {
                    if filteredItems.isEmpty {
                        EmptyStateView(
                            icon: "wrench.and.screwdriver.fill",
                            title: "No Punch Items",
                            message: "Add punch items to track defects and snags."
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                PunchItemDetailView(punchItem: item)
                            } label: {
                                PunchItemRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Punch Items")
        .toolbar {
            Button { showAddPunchItem = true } label: {
                Image(systemName: "plus")
                    .foregroundStyle(BuildTrackColors.primary)
            }
        }
        .sheet(isPresented: $showAddPunchItem) {
            PunchItemFormView()
        }
    }

    private func statusColor(_ status: PunchItemStatus) -> Color {
        switch status {
        case .open: return BuildTrackColors.danger
        case .inProgress: return BuildTrackColors.warning
        case .resolved: return BuildTrackColors.success
        case .closed: return BuildTrackColors.textTertiary
        }
    }

    private func severityColor(_ severity: PunchItemSeverity) -> Color {
        switch severity {
        case .cosmetic: return BuildTrackColors.textTertiary
        case .minor: return BuildTrackColors.info
        case .major: return BuildTrackColors.warning
        case .critical: return BuildTrackColors.danger
        }
    }
}

// MARK: - Punch Item Row

struct PunchItemRow: View {
    let item: PunchItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "wrench.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(severityColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)

                HStack(spacing: 8) {
                    PunchItemStatusBadge(status: item.status)
                    PunchItemSeverityBadge(severity: item.severity)

                    if !item.location.isEmpty {
                        Label(item.location, systemImage: "mappin")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }

            Spacer()

            if item.status == .resolved || item.status == .closed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(BuildTrackColors.success)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private var severityColor: Color {
        switch item.severity {
        case .cosmetic: return BuildTrackColors.textTertiary
        case .minor: return BuildTrackColors.info
        case .major: return BuildTrackColors.warning
        case .critical: return BuildTrackColors.danger
        }
    }
}

// MARK: - Badges

struct PunchItemStatusBadge: View {
    let status: PunchItemStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .open: return BuildTrackColors.danger
        case .inProgress: return BuildTrackColors.warning
        case .resolved: return BuildTrackColors.success
        case .closed: return BuildTrackColors.textTertiary
        }
    }
}

struct PunchItemSeverityBadge: View {
    let severity: PunchItemSeverity

    var body: some View {
        Text(severity.label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch severity {
        case .cosmetic: return BuildTrackColors.textTertiary
        case .minor: return BuildTrackColors.info
        case .major: return BuildTrackColors.warning
        case .critical: return BuildTrackColors.danger
        }
    }
}

#Preview {
    PunchItemsListView()
        .modelContainer(for: [PunchItem.self])
}
