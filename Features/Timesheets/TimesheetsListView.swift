import SwiftUI
import SwiftData

struct TimesheetsListView: View {
    @Query(sort: \TimesheetEntry.date, order: .reverse) private var entries: [TimesheetEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddEntry = false

    var totalHours: Double { entries.reduce(0) { $0 + $1.hoursWorked } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Hours")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(totalHours, specifier: "%.1f")")
                                .font(.title2.weight(.bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Entries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(entries.count)")
                                .font(.title2.weight(.bold))
                        }
                    }
                    .padding(.vertical, 4)
                }

                ForEach(entries) { entry in
                    NavigationLink {
                        TimesheetDetailView(entry: entry)
                    } label: {
                        TimesheetRow(entry: entry)
                    }
                }
                .onDelete(perform: deleteEntry)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Timesheets")
            .toolbar {
                Button { showAddEntry = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddEntry) {
                TimesheetFormView()
            }
            .overlay {
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Timesheets",
                        message: "Track worker hours and time"
                    )
                }
            }
        }
    }

    private func deleteEntry(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

struct TimesheetRow: View {
    let entry: TimesheetEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.workerName)
                    .font(.headline)
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !entry.task.isEmpty {
                    Text(entry.task)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.hoursWorked, specifier: "%.1f")h")
                    .font(.headline)
                TimesheetStatusBadge(status: entry.status)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TimesheetStatusBadge: View {
    let status: TimesheetStatus

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
        case .draft: return .gray
        case .submitted: return .blue
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

#Preview {
    TimesheetsListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
