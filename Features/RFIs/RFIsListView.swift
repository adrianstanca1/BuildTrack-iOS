import SwiftUI
import SwiftData

struct RFIsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RFI.createdAt, order: .reverse) private var rfis: [RFI]

    @State private var viewModel = RFIViewModel()
    @State private var showAddRFI = false
    @State private var searchText = ""
    @State private var statusFilter: RFIStatus?
    @State private var priorityFilter: RFIPriority?

    var filteredRFIs: [RFI] {
        var result = rfis
        if let status = statusFilter { result = result.filter { $0.status == status } }
        if let priority = priorityFilter { result = result.filter { $0.priority == priority } }
        if !searchText.isEmpty { result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) } }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchAndFilterBar
                    summaryCards
                    rfiList
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("RFIs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddRFI = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRFI) {
                RFIFormView()
            }
            .onAppear {
                viewModel.fetchRFIs(context: modelContext)
            }
        }
    }

    var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search RFIs...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                    ForEach(RFIStatus.allCases) { status in
                        FilterChip(title: status.label, isSelected: statusFilter == status) { statusFilter = status }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryCard(title: "Total", value: "\(rfis.count)", icon: "doc.text", color: .blue)
                SummaryCard(title: "Pending", value: "\(rfis.filter { $0.status == .draft || $0.status == .submitted || $0.status == .underReview }.count)", icon: "clock", color: .orange)
                SummaryCard(title: "Approved", value: "\(rfis.filter { $0.status == .approved }.count)", icon: "checkmark.circle", color: .green)
            }
            .padding(.horizontal, 16)
        }
    }

    var rfiList: some View {
        LazyVStack(spacing: 12) {
            if filteredRFIs.isEmpty {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No RFIs Found",
                    subtitle: searchText.isEmpty ? "Create your first RFI to get started" : "Try adjusting your search"
                )
            } else {
                ForEach(filteredRFIs) { rfi in
                    NavigationLink(value: rfi) {
                        RFICard(rfi: rfi)
                    }
                }
            }
        }
        .navigationDestination(for: RFI.self) { rfi in
            RFIDetailView(rfi: rfi)
        }
    }
}

struct RFICard: View {
    let rfi: RFI
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusBadge(text: rfi.status.label, color: statusColor(rfi.status))
                Spacer()
                PriorityBadge(text: rfi.priority.label, color: priorityColor(rfi.priority))
            }
            Text(rfi.title)
                .font(.headline)
                .foregroundStyle(.primary)
            if !rfi.descriptionText.isEmpty {
                Text(rfi.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Label(rfi.assignedTo.isEmpty ? "Unassigned" : rfi.assignedTo, systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(rfi.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func statusColor(_ status: RFIStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .closed: return .gray
        }
    }

    func priorityColor(_ priority: RFIPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

