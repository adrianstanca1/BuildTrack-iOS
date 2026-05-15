import SwiftUI
import SwiftData

@MainActor
struct TimesheetsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TimesheetViewModel()
    @State private var showNewEntry = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                switch viewModel.timesheetsState {
                case .idle:
                    Color.clear.onAppear {
                        Task { await viewModel.loadAll() }
                    }
                case .loading:
                    loadingContent
                case .loaded:
                    mainContent
                case .error(let message):
                    errorContent(message: message)
                }
            }
            .navigationTitle("Timesheets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewEntry = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(BuildTrackColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                TimesheetFormView()
            }
        }
    }
    
    // MARK: - Loading Content
    
    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading timesheets...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Error Content
    
    private func errorContent(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                Task { await viewModel.loadAll() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search bar
                SearchBar(query: $viewModel.searchQuery, placeholder: "Search timesheets...")
                
                // Status filter chips
                filterChips
                
                // Total hours summary card
                SummaryCard(
                    title: "Total Hours",
                    value: String(format: "%.1f", viewModel.totalHours),
                    subtitle: "\(viewModel.timesheets.count) entries",
                    icon: "clock",
                    color: BuildTrackColors.primary
                )
                
                // List
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredTimesheets) { entry in
                        NavigationLink {
                            TimesheetDetailView(entry: entry)
                        } label: {
                            TimesheetRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                
                if viewModel.filteredTimesheets.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Timesheets",
                        message: "Create a new timesheet entry to get started."
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.vertical, 12)
        }
        .refreshable {
            await viewModel.loadAll()
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: viewModel.activeFilter == nil) {
                    viewModel.clearFilter()
                }
                ForEach(TimesheetStatus.allCases, id: \.self) { status in
                    FilterChip(
                        label: status.label,
                        isSelected: viewModel.activeFilter == status
                    ) {
                        viewModel.filter(by: status)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Timesheet Row

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
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.hoursWorked, specifier: "%.1f")h")
                    .font(.headline)
                TimesheetStatusBadge(status: entry.status)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Timesheet Status Badge

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
