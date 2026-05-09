import SwiftUI
import SwiftData

// MARK: - Projects List View

struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    
    @State private var viewModel = ProjectsListViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                switch viewModel.loadingState {
                case .idle:
                    Color.clear.onAppear {
                        Task { await viewModel.loadProjects(context: modelContext) }
                    }
                case .loading:
                    projectsShimmerList
                case .loaded, .refreshing:
                    mainContent
                case .error(let message):
                    ErrorView(message: message) {
                        Task { await viewModel.loadProjects(context: modelContext) }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        sortMenu
                        NavigationLink {
                            ProjectFormView(mode: .create)
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search projects..."
            )
        }
        .task {
            if viewModel.loadingState == .idle {
                await viewModel.loadProjects(context: modelContext)
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                filterChipsSection
                
                if filteredProjects.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredProjects) { project in
                            projectCard(project)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
        }
        .refreshable {
            await viewModel.refreshProjects(context: modelContext)
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    // MARK: - Filter Chips
    
    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProjectStatusFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    @MainActor
    private func filterChip(_ filter: ProjectStatusFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                viewModel.selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : BuildTrackColors.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? BuildTrackColors.primary : BuildTrackColors.primary.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : BuildTrackColors.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.selectedFilter)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected) { old, new in
            new && !old
        }
    }
    
    // MARK: - Project Card
    
    private func projectCard(_ project: Project) -> some View {
        NavigationLink {
            ProjectDetailView(project: project)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(.label))
                            .lineLimit(2)
                        
                        if !project.clientName.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(project.clientName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: project.status)
                }
                
                Divider().padding(.vertical, 10)
                
                // Progress bar
                progressSection(project)
                    .padding(.bottom, 10)
                
                // Bottom row: location + task count
                HStack(spacing: 16) {
                    budgetGauge(project)
                    
                    Spacer()
                    
                    if !project.locationName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundStyle(BuildTrackColors.primary)
                            Text(project.locationName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    taskCountBadge(project)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16))
            .contextMenu { contextMenuContent(for: project) }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.archiveProject(project, context: modelContext) }
            } label: {
                Label("Archive", systemImage: "archivebox.fill")
            }
            
            Button {
                Task { await viewModel.toggleOnHold(project, context: modelContext) }
            } label: {
                Label("Hold", systemImage: "pause.circle.fill")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading) {
            Button {
                Task { await viewModel.completeProject(project, context: modelContext) }
            } label: {
                Label("Complete", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            )
        )
    }
    
    // MARK: - Progress Section
    
    private func progressSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(project.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(progressColor(project.progress))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(progressColor(project.progress))
                        .frame(width: max(geometry.size.width * CGFloat(project.progress), 6), height: 6)
                        .animation(.easeInOut(duration: 0.8), value: project.progress)
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Budget Gauge
    
    private func budgetGauge(_ project: Project) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sterlingsign.circle.fill")
                .font(.caption)
                .foregroundStyle(project.budget > 0 ? budgetColor(project) : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Spent \(formatCurrency(project.spentToDate))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if project.budget > 0 {
                    Text("of \(formatCurrency(project.budget))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - Task Count Badge
    
    private func taskCountBadge(_ project: Project) -> some View {
        let taskCount = project.tasks?.count ?? 0
        return HStack(spacing: 4) {
            Image(systemName: "list.clipboard")
                .font(.caption2)
            Text("\(taskCount) \(taskCount == 1 ? "task" : "tasks")")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func contextMenuContent(for project: Project) -> some View {
        Button {
            UIPasteboard.general.string = project.name
        } label: {
            Label("Copy Name", systemImage: "doc.on.doc")
        }
        
        Button {
            Task { await viewModel.duplicateProject(project, context: modelContext) }
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        
        Menu("Change Status") {
            ForEach(ProjectStatus.allCases) { status in
                Button {
                    Task { await viewModel.changeStatus(project, to: status, context: modelContext) }
                } label: {
                    Label(status.label, systemImage: status.icon)
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            Task { await viewModel.deleteProject(project, context: modelContext) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Sort Menu
    
    @MainActor
    private var sortMenu: some View {
        Menu {
            ForEach(ProjectSortOrder.allCases) { order in
                Button {
                    withAnimation { viewModel.sortOrder = order }
                } label: {
                    Label(order.label, systemImage: order.icon)
                }
            }
        } label: {
            Image(systemName: viewModel.sortOrder.icon)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            
            ZStack {
                Circle()
                    .fill(BuildTrackColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: viewModel.selectedFilter == .all
                      ? "building.columns.fill"
                      : viewModel.selectedFilter.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(BuildTrackColors.primary.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if viewModel.selectedFilter == .all {
                NavigationLink {
                    ProjectFormView(mode: .create)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Create Project")
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(BuildTrackColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
            
            Spacer().frame(height: 80)
        }
    }
    
    private var emptyStateTitle: String {
        viewModel.selectedFilter == .all
            ? "No Projects Yet"
            : "No \(viewModel.selectedFilter.label) Projects"
    }
    
    private var emptyStateMessage: String {
        viewModel.selectedFilter == .all
            ? "Create your first construction project to get started."
            : "There are no projects with this status. Try a different filter."
    }
    
    // MARK: - Shimmer Loading
    
    private var projectsShimmerList: some View {
        ScrollView {
            VStack(spacing: 12) {
                shimmerChips
                ForEach(0..<5, id: \.self) { _ in shimmerCard }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .disabled(true)
    }
    
    private var shimmerChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray5))
                        .frame(width: CGFloat([80, 60, 75, 90, 65][i % 5]), height: 32)
                        .shimmer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var shimmerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 160, height: 16)
                        .shimmer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 12)
                        .shimmer()
                }
                Spacer()
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 70, height: 22)
                    .shimmer()
            }
            
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray5))
                .frame(height: 6)
                .shimmer()
            
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 70, height: 16)
                    .shimmer()
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 90, height: 12)
                    .shimmer()
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 55, height: 18)
                    .shimmer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed
    
    private var filteredProjects: [Project] {
        var result = projects
        
        if viewModel.selectedFilter != .all {
            result = result.filter { $0.status.rawValue == viewModel.selectedFilter.statusRaw }
        }
        
        if !viewModel.searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                $0.clientName.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                $0.locationName.localizedCaseInsensitiveContains(viewModel.searchQuery)
            }
        }
        
        switch viewModel.sortOrder {
        case .date:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .budget:
            result.sort { $0.budget > $1.budget }
        case .progress:
            result.sort { $0.progress > $1.progress }
        }
        
        return result
    }
    
    private func progressColor(_ value: Double) -> Color {
        switch value {
        case 0..<0.25: .red
        case 0.25..<0.5: .orange
        case 0.5..<0.75: .yellow
        case 0.75..<1.0: .green
        default: .green
        }
    }
    
    private func budgetColor(_ project: Project) -> Color {
        guard project.budget > 0 else { return .secondary }
        let ratio = project.spentToDate / project.budget
        switch ratio {
        case 0..<0.6: .green
        case 0.6..<0.85: .orange
        default: .red
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
    }
}

// MARK: - View Model

@MainActor
@Observable
final class ProjectsListViewModel {
    var loadingState: LoadingState = .idle
    
    nonisolated init() {}
    var selectedFilter: ProjectStatusFilter = .all
    var sortOrder: ProjectSortOrder = .date
    var searchQuery = ""
    
    enum LoadingState: Equatable {
        case idle, loading, loaded, refreshing, error(String)
    }
    
    func loadProjects(context: ModelContext) async {
        loadingState = .loading
        do {
            let fetched: [Project] = try await ProjectRepository.live.fetchAll()
            for project in fetched {
                upsertInLocal(project, context: context)
            }
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func refreshProjects(context: ModelContext) async {
        loadingState = .refreshing
        do {
            let fetched: [Project] = try await ProjectRepository.live.fetchAll()
            for project in fetched {
                upsertInLocal(project, context: context)
            }
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func completeProject(_ project: Project, context: ModelContext) async {
        project.status = .completed
        project.updatedAt = Date()
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        do {
            try await ProjectRepository.live.update(project)
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func archiveProject(_ project: Project, context: ModelContext) async {
        project.status = .cancelled
        project.updatedAt = Date()
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
        do {
            try await ProjectRepository.live.update(project)
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func toggleOnHold(_ project: Project, context: ModelContext) async {
        if project.status == .onHold {
            project.status = .active
        } else {
            project.status = .onHold
        }
        project.updatedAt = Date()
        do {
            try await ProjectRepository.live.update(project)
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func changeStatus(_ project: Project, to status: ProjectStatus, context: ModelContext) async {
        project.status = status
        project.updatedAt = Date()
        do {
            try await ProjectRepository.live.update(project)
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func deleteProject(_ project: Project, context: ModelContext) async {
        context.delete(project)
        do {
            try await ProjectRepository.live.delete(project.id)
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func duplicateProject(_ project: Project, context: ModelContext) async {
        let duplicate = Project(
            name: "\(project.name) (Copy)",
            descriptionText: project.descriptionText,
            status: .planning,
            budget: project.budget,
            spentToDate: 0,
            progress: 0,
            startDate: Date(),
            endDate: project.endDate,
            locationName: project.locationName,
            latitude: project.latitude,
            longitude: project.longitude,
            clientName: project.clientName
        )
        context.insert(duplicate)
        do {
            let created = try await ProjectRepository.live.create(duplicate)
            duplicate.id = created.id
            loadingState = .loaded
        } catch {
            context.delete(duplicate)
            loadingState = .error(error.localizedDescription)
        }
    }
    
    private func upsertInLocal(_ project: Project, context: ModelContext) {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == project.id }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.name = project.name
            existing.descriptionText = project.descriptionText
            existing.status = project.status
            existing.budget = project.budget
            existing.spentToDate = project.spentToDate
            existing.progress = project.progress
            existing.startDate = project.startDate
            existing.endDate = project.endDate
            existing.locationName = project.locationName
            existing.latitude = project.latitude
            existing.longitude = project.longitude
            existing.clientName = project.clientName
            existing.updatedAt = project.updatedAt
        } else {
            context.insert(project)
        }
    }
}

// MARK: - Supporting Types

enum ProjectStatusFilter: String, CaseIterable, Identifiable {
    case all
    case planning, active, onHold = "on_hold", completed, cancelled
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .all: "All"
        case .planning: "Planning"
        case .active: "Active"
        case .onHold: "On Hold"
        case .completed: "Done"
        case .cancelled: "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .planning: "blueprint"
        case .active: "hammer.fill"
        case .onHold: "pause.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }
    
    var statusRaw: String {
        ["planning": "planning", "active": "active", "on_hold": "on_hold", "completed": "completed", "cancelled": "cancelled"][rawValue] ?? rawValue
    }
}

enum ProjectSortOrder: String, CaseIterable, Identifiable {
    case date, name, budget, progress
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .date: "Date Updated"
        case .name: "Name"
        case .budget: "Budget"
        case .progress: "Progress"
        }
    }
    
    var icon: String {
        switch self {
        case .date: "calendar"
        case .name: "textformat.abc"
        case .budget: "sterlingsign.circle"
        case .progress: "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.6), location: 0.5),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase * geometry.size.width * 2)
                }
            }
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Debounce Helper

extension ProjectsListViewModel {
    // Debounce is handled via Combine-free approach using @Observable and task cancellation
    // The searchable modifier already handles text input; filtering happens on @State changes
    // which are coalesced by SwiftUI's view update mechanism
    
    var debouncedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Preview

#Preview {
    ProjectsListView()
        .modelContainer(for: [Project.self, TaskItem.self, Incident.self, Inspection.self, Worker.self])
}
