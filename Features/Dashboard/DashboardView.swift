import SwiftUI
import SwiftData

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
    @State private var showPunchItems = false
    @State private var showRFIs = false
    @State private var showDrawings = false
    @State private var showSubmittals = false
    @State private var showInvoices = false
    
    var activeProjects: Int { projects.filter { $0.status == .active }.count }
    var pendingTasks: Int { tasks.filter { $0.status != .completed }.count }
    var completionRate: Int {
        guard !tasks.isEmpty else { return 0 }
        return Int(round(Double(tasks.filter { $0.status == .completed }.count) / Double(tasks.count) * 100))
    }
    var recentProjects: [Project] { Array(projects.prefix(3)) }
    var criticalIncidents: Int { 0 } // Placeholder
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Stats Grid
                statsGrid
                
                // Quick Actions
                quickActionsSection
                
                // Recent Projects
                recentProjectsSection
                // Quality & Documents
                qualitySection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                        .foregroundStyle(BuildTrackColors.primary)
                }
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
        .sheet(isPresented: $showSubmittals) {
            SubmittalsListView()
        }
        .sheet(isPresented: $showInvoices) {
            InvoicesListView()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BuildTrack")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text("Construction Management")
                .font(.subheadline)
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "building.2.fill",
                label: "Active Projects",
                value: activeProjects,
                color: BuildTrackColors.primary
            )
            StatCard(
                icon: "checklist",
                label: "Pending Tasks",
                value: pendingTasks,
                color: BuildTrackColors.info
            )
            StatCard(
                icon: "shield.fill",
                label: "Critical Alerts",
                value: criticalIncidents,
                color: BuildTrackColors.danger
            )
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                label: "Completion",
                value: completionRate,
                color: BuildTrackColors.success
            )
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    label: "New Project",
                    color: BuildTrackColors.primary
                ) { showNewProject = true }
                
                QuickActionButton(
                    icon: "checklist",
                    label: "Add Task",
                    color: BuildTrackColors.info
                ) { showNewTask = true }
                
                QuickActionButton(
                    icon: "exclamationmark.shield.fill",
                    label: "Report",
                    color: BuildTrackColors.danger
                ) { showNewIncident = true }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Recent Projects
    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Projects")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                Spacer()
                
                NavigationLink {
                    ProjectsListView()
                } label: {
                    Text("See All")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
            
            if recentProjects.isEmpty {
                EmptyStateView(
                    icon: "building.2.fill",
                    title: "No Projects Yet",
                    message: "Create your first project to get started."
                )
            } else {
                ForEach(recentProjects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        ProjectRowCard(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Quality & Documents
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quality & Documents")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionButton(
                    icon: "wrench.and.screwdriver.fill",
                    label: "Punch Items",
                    color: .orange
                ) { showPunchItems = true }
                
                QuickActionButton(
                    icon: "doc.text.fill",
                    label: "RFIs",
                    color: .blue
                ) { showRFIs = true }
                
                QuickActionButton(
                    icon: "doc.fill",
                    label: "Drawings",
                    color: .purple
                ) { showDrawings = true }
                
                QuickActionButton(
                    icon: "doc.on.doc.fill",
                    label: "Submittals",
                    color: .indigo
                ) { showSubmittals = true }
                
                QuickActionButton(
                    icon: "sterlingsign.square.fill",
                    label: "Invoices",
                    color: .green
                ) { showInvoices = true }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BuildTrackColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Project Row Card

struct ProjectRowCard: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 8)
                .fill(BuildTrackColors.statusColor(project.status))
                .frame(width: 4, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                HStack(spacing: 6) {
                    Text(project.status.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(BuildTrackColors.statusColor(project.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(BuildTrackColors.statusColor(project.status).opacity(0.12))
                        .clipShape(Capsule())
                    
                    if !project.locationName.isEmpty {
                        Text(project.locationName)
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(project.progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: [Project.self, TaskItem.self])
}
