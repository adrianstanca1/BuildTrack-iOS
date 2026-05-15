import SwiftUI
import SwiftData

@MainActor
struct EquipmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = EquipmentViewModel()
    @State private var showAddEquipment = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                switch viewModel.equipmentState {
                case .idle:
                    Color.clear.onAppear { Task { await viewModel.loadAll() } }
                case .loading:
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.2)
                        Text("Loading equipment...").font(.subheadline).foregroundStyle(.secondary)
                    }
                case .loaded:
                    mainContent
                case .error(let message):
                    ErrorView(message: message) { Task { await viewModel.loadAll() } }
                }
            }
            .navigationTitle("Equipment")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddEquipment = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold).foregroundStyle(BuildTrackColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddEquipment) {
                EquipmentFormView()
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                SearchBar(query: $viewModel.searchQuery, placeholder: "Search equipment...")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: viewModel.activeFilter == nil) { viewModel.clearFilter() }
                        ForEach(EquipmentStatus.allCases, id: \.self) { status in
                            FilterChip(label: status.label, isSelected: viewModel.activeFilter == status) {
                                viewModel.filter(by: status)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if viewModel.serviceDueCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("\(viewModel.serviceDueCount) item(s) due for service").font(.subheadline).foregroundStyle(.orange)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredEquipment) { item in
                        NavigationLink {
                            EquipmentDetailView(equipment: item)
                        } label: {
                            EquipmentRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                if viewModel.filteredEquipment.isEmpty {
                    EmptyStateView(icon: "wrench", title: "No Equipment", message: "Track plant and machinery for your projects.")
                        .padding(.top, 40)
                }
            }
            .padding(.vertical, 12)
        }
        .refreshable { await viewModel.loadAll() }
        .scrollDismissesKeyboard(.immediately)
    }
}

struct EquipmentRow: View {
    let item: Equipment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(statusColor.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: "wrench").font(.system(size: 18)).foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline).lineLimit(1)
                if !item.make.isEmpty || !item.model.isEmpty {
                    Text("\(item.make) \(item.model)".trimmingCharacters(in: .whitespaces)).font(.caption).foregroundStyle(.secondary)
                }
                Text(item.location).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(text: item.status.label, color: statusColor)
                Text("\(item.hoursUsed, specifier: "%.0f")h").font(.caption2).foregroundStyle(.tertiary)
                if item.isServiceDue {
                    Text("Service Due").font(.caption2).foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var statusColor: Color {
        switch item.status {
        case .available: return .green
        case .inUse: return .blue
        case .maintenance: return .orange
        case .retired: return .gray
        }
    }
}
