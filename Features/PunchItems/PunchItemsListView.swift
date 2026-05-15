import SwiftUI
import SwiftData

@MainActor
struct PunchItemsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PunchItemViewModel()
    @State private var showNewPunchItem = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                switch viewModel.punchItemsState {
                case .idle:
                    Color.clear.onAppear { Task { await viewModel.loadAll() } }
                case .loading:
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.2)
                        Text("Loading punch items...").font(.subheadline).foregroundStyle(.secondary)
                    }
                case .loaded:
                    mainContent
                case .error(let message):
                    ErrorView(message: message) { Task { await viewModel.loadAll() } }
                }
            }
            .navigationTitle("Punch Items")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewPunchItem = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold).foregroundStyle(BuildTrackColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showNewPunchItem) {
                PunchItemFormView()
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                SearchBar(query: $viewModel.searchQuery, placeholder: "Search punch items...")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: viewModel.activeFilter == nil) { viewModel.clearFilter() }
                        ForEach(PunchItemStatus.allCases, id: \.self) { status in
                            FilterChip(label: status.label, isSelected: viewModel.activeFilter == status) {
                                viewModel.filter(by: status)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredItems) { item in
                        NavigationLink {
                            PunchItemDetailView(punchItem: item)
                        } label: {
                            PunchItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                if viewModel.filteredItems.isEmpty {
                    EmptyStateView(icon: "wrench.and.screwdriver", title: "No Punch Items", message: "Create a punch item to track issues.")
                        .padding(.top, 40)
                }
            }
            .padding(.vertical, 12)
        }
        .refreshable { await viewModel.loadAll() }
        .scrollDismissesKeyboard(.immediately)
    }
}

struct PunchItemRow: View {
    let item: PunchItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(severityColor.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: severityIcon).font(.system(size: 18, weight: .medium)).foregroundStyle(severityColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.headline).lineLimit(1)
                Text(item.location).font(.caption).foregroundStyle(.secondary)
                Text("Assigned: \(item.assignee)").font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(label: item.status.label, color: statusColor)
                if item.status == .resolved || item.status == .closed {
                    Text("Done").font(.caption2).foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var severityColor: Color {
        switch item.severity {
        case .cosmetic: return .gray
        case .minor: return .yellow
        case .major: return .orange
        case .critical: return .red
        }
    }

    var severityIcon: String {
        switch item.severity {
        case .cosmetic: return "circle"
        case .minor: return "exclamationmark.circle"
        case .major: return "exclamationmark.triangle"
        case .critical: return "xmark.octagon"
        }
    }

    var statusColor: Color {
        switch item.status {
        case .open: return .red
        case .inProgress: return .orange
        case .resolved: return .green
        case .closed: return .gray
        }
    }
}

