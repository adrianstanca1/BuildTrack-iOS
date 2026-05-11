import SwiftUI
import SwiftData

struct RFIsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RFI.createdAt, order: .reverse) private var allRFIs: [RFI]
    @State private var showNewRFI = false
    @State private var searchQuery = ""
    @State private var statusFilter: RFIStatus? = nil

    var filteredRFIs: [RFI] {
        var result = allRFIs
        if let filter = statusFilter { result = result.filter { $0.status == filter } }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.assignedTo.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar(query: $searchQuery, placeholder: "Search RFIs...")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                            ForEach(RFIStatus.allCases, id: \.self) { s in
                                FilterChip(label: s.label, isSelected: statusFilter == s) { statusFilter = s }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    HStack(spacing: 12) {
                        SummaryCard(title: "Open", value: "\(allRFIs.filter { $0.status == .submitted || $0.status == .underReview }.count)", icon: "doc.text", color: .blue)
                        SummaryCard(title: "Approved", value: "\(allRFIs.filter { $0.status == .approved }.count)", icon: "checkmark.circle", color: .green)
                        SummaryCard(title: "Pending", value: "\(allRFIs.filter { $0.status == .draft }.count)", icon: "clock", color: .orange)
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(filteredRFIs) { rfi in
                            NavigationLink { RFIDetailView(rfi: rfi) } label: {
                                RFIRowCard(rfi: rfi)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)

                    if filteredRFIs.isEmpty {
                        EmptyStateView(icon: "doc.text", title: "No RFIs", message: "Create your first RFI to track requests for information.")
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("RFIs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewRFI = true } label: { Image(systemName: "plus").foregroundStyle(BuildTrackColors.primary) }
                }
            }
            .sheet(isPresented: $showNewRFI) { RFIFormView() }
        }
    }
}

struct RFIRowCard: View {
    let rfi: RFI
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rfi.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                HStack(spacing: 6) {
                    RFIStatusBadge(status: rfi.status)
                    PriorityBadge(priority: rfi.priority)
                    if !rfi.assignedTo.isEmpty {
                        Label(rfi.assignedTo, systemImage: "person")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }
            Spacer()
            Text(rfi.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(BuildTrackColors.textTertiary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview { RFIsListView().modelContainer(for: [RFI.self]) }
