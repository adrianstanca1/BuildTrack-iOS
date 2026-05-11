import SwiftUI
import SwiftData

struct DefectsListView: View {
    @Query(sort: \Defect.updatedAt, order: .reverse) private var defects: [Defect]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddDefect = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(defects) { defect in
                    NavigationLink {
                        DefectDetailView(defect: defect)
                    } label: {
                        DefectRow(defect: defect)
                    }
                }
                .onDelete(perform: deleteDefect)
            }
            .listStyle(.plain)
            .navigationTitle("Defects")
            .toolbar {
                Button { showAddDefect = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddDefect) {
                DefectFormView()
            }
            .overlay {
                if defects.isEmpty {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "No Defects",
                        message: "Track quality issues and defects"
                    )
                }
            }
        }
    }

    private func deleteDefect(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(defects[index])
        }
    }
}

struct DefectRow: View {
    let defect: Defect

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(defect.title)
                    .font(.headline)
                if !defect.location.isEmpty {
                    Text(defect.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    DefectSeverityBadge(severity: defect.severity)
                    DefectStatusBadge(status: defect.status)
                }
            }
            Spacer()
            if defect.isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DefectSeverityBadge: View {
    let severity: DefectSeverity

    var body: some View {
        Text(severity.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severityColor.opacity(0.12))
            .foregroundStyle(severityColor)
            .clipShape(Capsule())
    }

    var severityColor: Color {
        switch severity {
        case .minor: return .gray
        case .major: return .orange
        case .critical: return .red
        }
    }
}

struct DefectStatusBadge: View {
    let status: DefectStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.12))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    var statusColor: Color {
        switch status {
        case .open: return .red
        case .inProgress: return .blue
        case .resolved: return .green
        case .closed: return .gray
        }
    }
}

#Preview {
    DefectsListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
