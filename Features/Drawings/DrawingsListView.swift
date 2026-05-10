import SwiftUI
import SwiftData

struct DrawingsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Drawing.createdAt, order: .reverse) private var drawings: [Drawing]
    @State private var viewModel = DrawingViewModel()
    @State private var showAddDrawing = false
    @State private var searchText = ""
    @State private var statusFilter: DrawingStatus?
    var filteredDrawings: [Drawing] {
        var result = drawings
        if let status = statusFilter { result = result.filter { $0.status == status } }
        if !searchText.isEmpty { result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.drawingNumber.localizedCaseInsensitiveContains(searchText) } }
        return result
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchAndFilterBar
                    summaryCards
                    drawingList
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Drawings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddDrawing = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddDrawing) {
                DrawingFormView()
            }
            .onAppear {
                viewModel.fetchDrawings(context: modelContext)
            }
        }
    }
    var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search drawings...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                    ForEach(DrawingStatus.allCases) { status in
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
                SummaryCard(title: "Total", value: "\(drawings.count)", icon: "doc", color: .blue)
                SummaryCard(title: "Active", value: "\(drawings.filter { $0.status == .active }.count)", icon: "checkmark.circle", color: .green)
                SummaryCard(title: "Superseded", value: "\(drawings.filter { $0.status == .superseded }.count)", icon: "arrow.2.circlepath", color: .orange)
            }
            .padding(.horizontal, 16)
        }
    }
    var drawingList: some View {
        LazyVStack(spacing: 12) {
            if filteredDrawings.isEmpty {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No Drawings Found",
                    subtitle: searchText.isEmpty ? "Add your first drawing to get started" : "Try adjusting your search"
                )
            } else {
                ForEach(filteredDrawings) { drawing in
                    NavigationLink(value: drawing) {
                        DrawingCard(drawing: drawing)
                    }
                }
            }
        }
        .navigationDestination(for: Drawing.self) { drawing in
            DrawingDetailView(drawing: drawing)
        }
    }
}

struct DrawingCard: View {
    let drawing: Drawing
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusBadge(text: drawing.status.label, color: statusColor(drawing.status))
                Spacer()
                Text("Rev \(drawing.revision)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
            Text(drawing.title)
                .font(.headline)
                .foregroundStyle(.primary)
            if !drawing.drawingNumber.isEmpty {
                Text("#\(drawing.drawingNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(drawing.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    func statusColor(_ status: DrawingStatus) -> Color {
        switch status {
        case .active: return .green
        case .superseded: return .orange
        case .archived: return .gray
        }
    }
}


}






}
