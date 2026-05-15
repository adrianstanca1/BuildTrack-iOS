import SwiftUI
import SwiftData

@MainActor
struct MaterialsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MaterialViewModel()
    @State private var showAddMaterial = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                switch viewModel.materialsState {
                case .idle:
                    Color.clear.onAppear { Task { await viewModel.loadAll() } }
                case .loading:
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.2)
                        Text("Loading materials...").font(.subheadline).foregroundStyle(.secondary)
                    }
                case .loaded:
                    mainContent
                case .error(let message):
                    ErrorView(message: message) { Task { await viewModel.loadAll() } }
                }
            }
            .navigationTitle("Materials")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddMaterial = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold).foregroundStyle(BuildTrackColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddMaterial) {
                MaterialFormView()
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                SearchBar(query: $viewModel.searchQuery, placeholder: "Search materials...")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: viewModel.activeFilter == nil) { viewModel.clearFilter() }
                        ForEach(MaterialStatus.allCases, id: \.self) { status in
                            FilterChip(label: status.label, isSelected: viewModel.activeFilter == status) {
                                viewModel.filter(by: status)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredMaterials) { item in
                        NavigationLink {
                            MaterialDetailView(material: item)
                        } label: {
                            MaterialRow(material: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                if viewModel.filteredMaterials.isEmpty {
                    EmptyStateView(icon: "cube.box", title: "No Materials", message: "Track deliveries and inventory for your projects.")
                        .padding(.top, 40)
                }
            }
            .padding(.vertical, 12)
        }
        .refreshable { await viewModel.loadAll() }
        .scrollDismissesKeyboard(.immediately)
    }
}

struct MaterialRow: View {
    let material: Material

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(statusColor.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: "cube.box").font(.system(size: 18)).foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(material.name).font(.headline).lineLimit(1)
                if !material.category.isEmpty {
                    Text(material.category).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(text: material.status.label, color: statusColor)
                Text("\(material.quantity, specifier: "%.1f") \(material.unit)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var statusColor: Color {
        switch material.status {
        case .ordered: return .blue
        case .delivered: return .orange
        case .inStock: return .green
        case .used: return .gray
        }
    }
}
