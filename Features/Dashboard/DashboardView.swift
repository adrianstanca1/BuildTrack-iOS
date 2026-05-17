import SwiftUI
import SwiftData

// MARK: - Professional Dashboard Redesign

@MainActor
struct DashboardView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \PunchItem.createdAt, order: .reverse) private var punchItems: [PunchItem]
    @Query(sort: \RFI.createdAt, order: .reverse) private var rfis: [RFI]
    @Query(sort: \Drawing.createdAt, order: .reverse) private var drawings: [Drawing]
    
    @State private var showNewProject = false
    @State private var showNewTask = false
    @State private var showNewIncident = false
    @State private var selectedSection: DashboardSection?
    
    var activeProjects: Int { projects.filter { $0.status == .active }.count }
    var pendingTasks: Int { tasks.filter { $0.status != .completed }.count }
    var completionRate: Int {
        guard !tasks.isEmpty else { return 0 }
        return Int(round(Double(tasks.filter { $0.status == .completed }.count) / Double(tasks.count) * 100))
    }
    var recentProjects: [Project] { Array(projects.prefix(5)) }
    
    enum DashboardSection: String, Identifiable {
        case punchItems, rfis, drawings, submittals, invoices
        var id: String { rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                welcomeHeader
                    .fadeIn(delay: 0)
                
                statsCarousel
                    .fadeIn(delay: 0.1)
                
                quickActionsGrid
                    .fadeIn(delay: 0.2)
                
                recentProjectsSection
                    .fadeIn(delay: 0.3)
                
                qualityDocumentsSection
                    .fadeIn(delay: 0.4)
            }
            .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    NotificationInboxView()
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BuildTrackColors.primary)
                        .frame(width: DesignTokens.Spacing.minTapTarget, height: DesignTokens.Spacing.minTapTarget)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .accessibleTapTarget(label: "Notifications", hint: "View your notifications")
            }
        }
        .sheet(isPresented: $showNewProject) {
            ProjectFormView(mode: .create)
        }
        .sheet(isPresented: $showNewTask) {
            TaskFormView()
        }
        .sheet(isPresented: $showNewIncident) {
            IncidentFormView()
        }
        .sheet(item: $selectedSection) { section in
            switch section {
            case .punchItems:
                PunchItemsListView()
            case .rfis:
                RFIsListView()
            case .drawings:
                DrawingsListView()
            case .submittals:
                SubmittalsListView()
            case .invoices:
                InvoicesListView()
            }
        }
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("BuildTrack")
                .font(DesignTokens.Typography.largeTitle)
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text("Construction Management")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DesignTokens.Spacing.sm)
    }
    
    // MARK: - Stats Carousel
    private var statsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                StatCardPro(
                    icon: "building.2.fill",
                    label: "Active Projects",
                    value: "\(activeProjects)",
                    color: BuildTrackColors.primary,
                    trend: "+2 this week"
                )
                
                StatCardPro(
                    icon: "checklist",
                    label: "Pending Tasks",
                    value: "\(pendingTasks)",
                    color: BuildTrackColors.info,
                    trend: nil
                )
                
                StatCardPro(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Completion",
                    value: "\(completionRate)%",
                    color: BuildTrackColors.success,
                    trend: completionRate > 75 ? "On track" : "Needs attention"
                )
                
                StatCardPro(
                    icon: "exclamationmark.triangle.fill",
                    label: "Open Issues",
                    value: "\(punchItems.count + rfis.count)",
                    color: BuildTrackColors.warning,
                    trend: nil
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
        }
        .padding(.horizontal, -DesignTokens.Spacing.sectionPadding)
    }
    
    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Quick Actions")
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.md) {
                QuickActionButtonPro(
                    icon: "plus.circle.fill",
                    label: "New Project",
                    color: BuildTrackColors.primary
                ) {
                    DesignTokens.Haptic.medium()
                    showNewProject = true
                }
                
                QuickActionButtonPro(
                    icon: "checklist",
                    label: "Add Task",
                    color: BuildTrackColors.info
                ) {
                    DesignTokens.Haptic.medium()
                    showNewTask = true
                }
                
                QuickActionButtonPro(
                    icon: "exclamationmark.shield.fill",
                    label: "Report",
                    color: BuildTrackColors.danger
                ) {
                    DesignTokens.Haptic.medium()
                    showNewIncident = true
                }
            }
        }
        .professionalCard()
    }
    
    // MARK: - Recent Projects
    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Recent Projects")
                    .font(DesignTokens.Typography.title3)
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                Spacer()
                
                NavigationLink {
                    ProjectsListView()
                } label: {
                    Text("See All")
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
            
            if recentProjects.isEmpty {
                ProEmptyState(
                    icon: "building.2.fill",
                    title: "No Projects Yet",
                    message: "Create your first project to get started with construction management.",
                    actionTitle: "Create Project"
                ) {
                    showNewProject = true
                }
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(recentProjects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            ProjectRowCardPro(project: project)
                                .contentTransition(.opacity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .professionalCard()
    }
    
    // MARK: - Quality & Documents
    private var qualityDocumentsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Quality & Documents")
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.md) {
                DocumentActionButton(
                    icon: "wrench.and.screwdriver.fill",
                    label: "Punch Items",
                    count: punchItems.count,
                    color: .orange
                ) {
                    DesignTokens.Haptic.light()
                    selectedSection = .punchItems
                }
                
                DocumentActionButton(
                    icon: "doc.text.fill",
                    label: "RFIs",
                    count: rfis.count,
                    color: .blue
                ) {
                    DesignTokens.Haptic.light()
                    selectedSection = .rfis
                }
                
                DocumentActionButton(
                    icon: "doc.fill",
                    label: "Drawings",
                    count: drawings.count,
                    color: .purple
                ) {
                    DesignTokens.Haptic.light()
                    selectedSection = .drawings
                }
                
                DocumentActionButton(
                    icon: "doc.on.doc.fill",
                    label: "Submittals",
                    count: 0,
                    color: .indigo
                ) {
                    DesignTokens.Haptic.light()
                    selectedSection = .submittals
                }
                
                DocumentActionButton(
                    icon: "sterlingsign.square.fill",
                    label: "Invoices",
                    count: 0,
                    color: .green
                ) {
                    DesignTokens.Haptic.light()
                    selectedSection = .invoices
                }
            }
        }
        .professionalCard()
    }
}

// MARK: - Professional Components

struct StatCardPro: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
                
                Spacer()
                
                if let trend {
                    Text(trend)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            Text(value)
                .font(DesignTokens.Typography.numericLarge)
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .padding(DesignTokens.Spacing.md)
        .frame(width: 160, height: 120, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}

struct QuickActionButtonPro: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                
                Text(label)
                    .font(DesignTokens.Typography.caption.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .contentShape(Rectangle())
    }
}

struct ProjectRowCardPro: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Status indicator
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(BuildTrackColors.statusColor(project.status))
                .frame(width: 4, height: 48)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(project.name)
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ProBadge(text: project.status.label, color: BuildTrackColors.statusColor(project.status))
                    
                    if !project.locationName.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                            Text(project.locationName)
                                .font(.caption2)
                        }
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(BuildTrackColors.border, lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(project.progress, 1.0)))
                    .stroke(
                        BuildTrackColors.statusColor(project.status),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(project.progress * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct DocumentActionButton: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 48, height: 48)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color)
                            .clipShape(Capsule())
                            .offset(x: 4, y: -4)
                    }
                }
                
                Text(label)
                    .font(DesignTokens.Typography.caption.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Professional Dashboard") {
    DashboardView()
        .modelContainer(for: [Project.self, TaskItem.self])
}
