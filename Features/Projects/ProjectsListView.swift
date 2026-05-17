import SwiftUI
import SwiftData

// MARK: - Professional Projects List View

@MainActor
struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    
    @State private var viewModel = ProjectsListViewModel()
    @State private var selectedProject: Project?
    
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
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        sortMenu
                        Button {
                            DesignTokens.Haptic.medium()
                            // Create new project action
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(BuildTrackColors.primary)
                                .frame(width: 36, height: 36)
                                .background(BuildTrackColors.primary.opacity(0.12))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search projects..."
            )
            .refreshable {
                DesignTokens.Haptic.medium()
                await viewModel.loadProjects(context: modelContext)
            }
            .sheet(item: $selectedProject) { project in
                NavigationStack {
                    ProjectDetailView(project: project)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { selectedProject = nil }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Stats Row
                HStack(spacing: DesignTokens.Spacing.md) {
                    StatMiniCard(
                        icon: "folder.fill",
                        value: "\(projects.count)",
                        label: "Total",
                        color: BuildTrackColors.primary
                    )
                    StatMiniCard(
                        icon: "checkmark.circle.fill",
                        value: "\(projects.filter { $0.status == .completed }.count)",
                        label: "Done",
                        color: BuildTrackColors.success
                    )
                    StatMiniCard(
                        icon: "clock.fill",
                        value: "\(projects.filter { $0.status == .active }.count)",
                        label: "Active",
                        color: BuildTrackColors.info
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .fadeIn(delay: 0)
                
                // Projects List
                if projects.isEmpty {
                    ProEmptyState(
                        icon: "folder",
                        title: "No Projects",
                        message: "Create your first construction project to get started.",
                        action: {}
                    )
                    .padding(.top, DesignTokens.Spacing.xl)
                    .fadeIn(delay: 0.1)
                } else {
                    LazyVStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(filteredProjects) { project in
                            ProjectCardPro(project: project)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    DesignTokens.Haptic.medium()
                                    selectedProject = project
                                }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.1)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
    }
    
    // MARK: - Filtered Projects
    private var filteredProjects: [Project] {
        if viewModel.searchQuery.isEmpty {
            return projects
        }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
            $0.location.localizedCaseInsensitiveContains(viewModel.searchQuery)
        }
    }
    
    // MARK: - Sort Menu
    private var sortMenu: some View {
        Menu {
            Button {
                DesignTokens.Haptic.light()
                viewModel.sortBy = .updatedAt
            } label: {
                Label("Last Updated", systemImage: viewModel.sortBy == .updatedAt ? "checkmark" : "")
            }
            Button {
                DesignTokens.Haptic.light()
                viewModel.sortBy = .name
            } label: {
                Label("Name", systemImage: viewModel.sortBy == .name ? "checkmark" : "")
            }
            Button {
                DesignTokens.Haptic.light()
                viewModel.sortBy = .status
            } label: {
                Label("Status", systemImage: viewModel.sortBy == .status ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 36, height: 36)
                .background(BuildTrackColors.primary.opacity(0.12))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Shimmer Loading
    private var projectsShimmerList: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(BuildTrackColors.textTertiary.opacity(0.12))
                        .frame(height: 120)
                        .shimmer()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
        }
    }
}

// MARK: - Professional Project Card

struct ProjectCardPro: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header
            HStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(project.status.label)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(statusColor)
                }
                
                Spacer()
                
                // Progress indicator
                if let progress = project.progress {
                    ZStack {
                        Circle()
                            .stroke(BuildTrackColors.textTertiary.opacity(0.2), lineWidth: 3)
                            .frame(width: 36, height: 36)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress) / 100)
                            .stroke(BuildTrackColors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(progress))%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(BuildTrackColors.primary)
                    }
                }
            }
            
            // Location
            if !project.location.isEmpty {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    
                    Text(project.location)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    Text(project.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
                
                Spacer()
                
                // Task count badge
                if project.tasks.count > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "checklist")
                            .font(.system(size: 10))
                            .foregroundStyle(BuildTrackColors.info)
                        Text("\(project.tasks.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BuildTrackColors.info)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(BuildTrackColors.info.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(BuildTrackColors.border, lineWidth: 0.5)
        )
    }
    
    private var statusColor: Color {
        switch project.status {
        case .planning: return BuildTrackColors.info
        case .active: return BuildTrackColors.primary
        case .onHold: return BuildTrackColors.warning
        case .completed: return BuildTrackColors.success
        case .cancelled: return BuildTrackColors.danger
        }
    }
    
    private var statusIcon: String {
        switch project.status {
        case .planning: return "doc.text"
        case .active: return "bolt.fill"
        case .onHold: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + phase * geo.size.width * 2)
                }
            )
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

// MARK: - View Model

enum ProjectSortBy {
    case updatedAt, name, status
}

@MainActor
final class ProjectsListViewModel: ObservableObject {
    @Published var loadingState: LoadingState = .idle
    @Published var searchQuery = ""
    @Published var sortBy: ProjectSortBy = .updatedAt
    
    func loadProjects(context: ModelContext) async {
        loadingState = loadingState == .loaded ? .refreshing : .loading
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        loadingState = .loaded
    }
}

enum LoadingState: Equatable {
    case idle, loading, loaded, refreshing, error(String)
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(BuildTrackColors.warning)
            
            Text("Something went wrong")
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text(message)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(BuildTrackColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                DesignTokens.Haptic.medium()
                retry()
            } label: {
                Text("Try Again")
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(BuildTrackColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - Project Status Extension

extension ProjectStatus {
    var label: String {
        switch self {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

#Preview("Professional Projects") {
    ProjectsListView()
}
