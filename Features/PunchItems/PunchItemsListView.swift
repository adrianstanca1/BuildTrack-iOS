import SwiftUI
import SwiftData

struct PunchItemsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PunchItem.createdAt, order: .reverse) private var allItems: [PunchItem]
    @State private var showNewItem = false
    @State private var searchQuery = ""
    @State private var statusFilter: PunchItemStatus? = nil
    @State private var severityFilter: PunchItemSeverity? = nil

    var filteredItems: [PunchItem] {
        var result = allItems
        if let filter = statusFilter { result = result.filter { $0.status == filter } }
        if let filter = severityFilter { result = result.filter { $0.severity == filter } }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.location.localizedCaseInsensitiveContains(searchQuery) ||
                $0.assignee.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar(query: $searchQuery, placeholder: "Search punch items...")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                            ForEach(PunchItemStatus.allCases, id: \.self) { s in
                                FilterChip(label: s.label, isSelected: statusFilter == s) { statusFilter = s }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    HStack(spacing: 12) {
                        SummaryCard(title: "Open", value: "\(allItems.filter { $0.status == .open }.count)", icon: "wrench.and.screwdriver", color: .blue)
                        SummaryCard(title: "Resolved", value: "\(allItems.filter { $0.status == .resolved }.count)", icon: "checkmark.circle", color: .green)
                        SummaryCard(title: "Critical", value: "\(allItems.filter { $0.severity == .critical }.count)", icon: "exclamationmark.triangle", color: .red)
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            NavigationLink { PunchItemDetailView(punchItem: item) } label: {
                                PunchItemRowCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)

                    if filteredItems.isEmpty {
                        EmptyStateView(icon: "wrench.and.screwdriver", title: "No Punch Items", message: "Create your first punch item to track defects.")
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Punch Items")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewItem = true } label: { Image(systemName: "plus").foregroundStyle(BuildTrackColors.primary) }
                }
            }
            .sheet(isPresented: $showNewItem) { PunchItemFormView() }
        }
    }
}

struct PunchItemRowCard: View {
    let item: PunchItem
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                HStack(spacing: 6) {
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
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview { PunchItemsListView().modelContainer(for: [PunchItem.self]) }
