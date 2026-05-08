import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<Project> { _ in true }) private var projects: [Project]
    @Query(filter: #Predicate<TaskItem> { _ in true }) private var tasks: [TaskItem]
    @State private var showNewProject = false
    @State private var showNewTask = false
    @State private var showNewIncident = false
    
    var activeProjects: Int { projects.filter { $0.status == .active }.count }
    var todayTasks: Int {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate) && task.status != .completed
        }.count
    }
    var overdueTasks: Int {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && task.status != .completed
        }.count
    }
    var completionRate: Int {
        guard !tasks.isEmpty else { return 0 }
        return Int(round(Double(tasks.filter { $0.status == .completed }.count) / Double(tasks.count) * 100))
    }
    var recentProjects: [Project] { Array(projects.sorted { $0.updatedAt > $1.updatedAt }.prefix(3)) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("BuildTrack")
                        .font(.largeTitle.bold())
                    Text("Construction Management")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(icon: "building.2.fill", label: "Active Projects", value: activeProjects, color: BuildTrackColors.primary)
                    StatCard(icon: "list.clipboard", label: "Today's Tasks", value: todayTasks, color: BuildTrackColors.success)
                    StatCard(icon: "exclamationmark.triangle.fill", label: "Overdue Tasks", value: overdueTasks, color: BuildTrackColors.danger)
                    StatCard(icon: "chart.line.uptrend.xyaxis", label: "Completion Rate", value: completionRate, color: BuildTrackColors.info)
                }
                
                // Quick Actions
                CardView {
                    SectionHeader(title: "Quick Actions")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        Button { showNewProject = true } label: {
                            ActionButton(icon: "plus.circle.fill", label: "New Project", color: BuildTrackColors.primary)
                        }
                        .buttonStyle(.plain)
                        
                        Button { showNewTask = true } label: {
                            ActionButton(icon: "checklist", label: "Add Task", color: BuildTrackColors.info)
                        }
                        .buttonStyle(.plain)
                        
                        Button { showNewIncident = true } label: {
                            ActionButton(icon: "exclamationmark.shield.fill", label: "Report", color: BuildTrackColors.danger)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Analytics Card
                NavigationLink {
                    ReportsView()
                } label: {
                    CardView {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(BuildTrackColors.primary.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                    .foregroundStyle(BuildTrackColors.primary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reports & Analytics")
                                    .font(.headline)
                                Text("Budget health, task trends, safety metrics")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Recent Projects
                if !recentProjects.isEmpty {
                    CardView {
                        SectionHeader(title: "Recent Projects")
                        ForEach(recentProjects) { project in
                            ProjectRow(project: project)
                            if project.id != recentProjects.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNewProject) {
            ProjectFormView(mode: .create)
        }
        .sheet(isPresented: $showNewTask) {
            TaskFormView()
        }
        .sheet(isPresented: $showNewIncident) {
            IncidentFormView()
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: project.status.icon)
                .font(.title3)
                .foregroundStyle(BuildTrackColors.statusColor(project.status))
                .frame(width: 40, height: 40)
                .background(BuildTrackColors.statusColor(project.status).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(project.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: project.status)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Project.self, TaskItem.self])
}
