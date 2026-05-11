import SwiftUI
import SwiftData

struct DrawingsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Drawing.createdAt, order: .reverse) private var allDrawings: [Drawing]
    @State private var showNewDrawing = false
    @State private var searchQuery = ""
    @State private var statusFilter: DrawingStatus? = nil

    var filteredDrawings: [Drawing] {
        var result = allDrawings
        if let filter = statusFilter { result = result.filter { $0.status == filter } }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.drawingNumber.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar(query: $searchQuery, placeholder: "Search drawings...")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                            ForEach(DrawingStatus.allCases, id: \.self) { s in
                                FilterChip(label: s.label, isSelected: statusFilter == s) { statusFilter = s }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    HStack(spacing: 12) {
                        SummaryCard(title: "Active", value: "\(allDrawings.filter { $0.status == .active }.count)", icon: "doc", color: .green)
                        SummaryCard(title: "Superseded", value: "\(allDrawings.filter { $0.status == .superseded }.count)", icon: "arrow.2.circlepath", color: .orange)
                        SummaryCard(title: "Total", value: "\(allDrawings.count)", icon: "doc.on.doc", color: .purple)
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(filteredDrawings) { drawing in
                            NavigationLink { DrawingDetailView(drawing: drawing) } label: {
                                DrawingRowCard(drawing: drawing)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)

                    if filteredDrawings.isEmpty {
                        EmptyStateView(icon: "doc", title: "No Drawings", message: "Add drawings to track revisions and versions.")
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Drawings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewDrawing = true } label: { Image(systemName: "plus").foregroundStyle(BuildTrackColors.primary) }
                }
            }
            .sheet(isPresented: $showNewDrawing) { DrawingFormView() }
        }
    }
}

struct DrawingRowCard: View {
    let drawing: Drawing
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(drawing.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                HStack(spacing: 6) {
                    DrawingStatusBadge(status: drawing.status)
                    if !drawing.drawingNumber.isEmpty {
                        Label(drawing.drawingNumber, systemImage: "number")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                    if !drawing.revision.isEmpty {
                        Text("Rev \(drawing.revision)")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }
            Spacer()
            Text(drawing.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(BuildTrackColors.textTertiary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview { DrawingsListView().modelContainer(for: [Drawing.self]) }
