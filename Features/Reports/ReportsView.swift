import SwiftUI
import SwiftData

// MARK: - Reports & Analytics View

struct ReportsView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    @Query(sort: \Incident.date, order: .reverse) private var incidents: [Incident]
    
    @State private var selectedPeriod: ReportPeriod = .thisMonth
    @State private var selectedProject: Project?
    
    var filteredProjects: [Project] {
        let cal = Calendar.current
        let now = Date()
        return projects.filter { project in
            switch selectedPeriod {
            case .allTime:
                return true
            case .thisWeek:
                guard let weekAgo = cal.date(byAdding: .day, value: -7, to: now) else { return false }
                return project.startDate >= weekAgo || project.updatedAt >= weekAgo
            case .thisMonth:
                guard let monthAgo = cal.date(byAdding: .month, value: -1, to: now) else { return false }
                return project.startDate >= monthAgo || project.updatedAt >= monthAgo
            case .thisQuarter:
                guard let qAgo = cal.date(byAdding: .month, value: -3, to: now) else { return false }
                return project.startDate >= qAgo || project.updatedAt >= qAgo
            case .thisYear:
                guard let yAgo = cal.date(byAdding: .year, value: -1, to: now) else { return false }
                return project.startDate >= yAgo || project.updatedAt >= yAgo
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period selector
                periodSelector
                    .padding(.horizontal)
                
                // Summary cards
                summaryCards
                    .padding(.horizontal)
                
                // Budget health
                budgetHealthSection
                    .padding(.horizontal)
                
                // Project status breakdown
                statusBreakdownSection
                    .padding(.horizontal)
                
                // Tasks analytics
                tasksAnalyticsSection
                    .padding(.horizontal)
                
                // Safety summary
                safetySummarySection
                    .padding(.horizontal)
                
                // Top projects by budget
                topProjectsSection
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reports & Analytics")
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.label)
                            .font(.subheadline)
                            .fontWeight(selectedPeriod == period ? .semibold : .regular)
                            .foregroundStyle(selectedPeriod == period ? .white : BuildTrackColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedPeriod == period ? BuildTrackColors.primary : BuildTrackColors.primary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "building.2.fill", label: "Active Projects", value: activeProjectsCount, color: BuildTrackColors.success)
            StatCard(icon: "list.clipboard", label: "Open Tasks", value: openTasksCount, color: BuildTrackColors.info)
            StatCard(icon: "checkmark.circle.fill", label: "Completed Tasks", value: completedTasksCount, color: BuildTrackColors.primary)
            StatCard(icon: "exclamationmark.triangle.fill", label: "Incidents", value: incidentsCount, color: BuildTrackColors.danger)
        }
    }
    
    // MARK: - Budget Health
    
    private var budgetHealthSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Budget Health")
                
                // Total budget vs spent
                HStack(spacing: 20) {
                    BudgetMetricCard(
                        label: "Total Budget",
                        value: formatCurrency(totalBudget),
                        color: .blue,
                        icon: "creditcard.fill"
                    )
                    BudgetMetricCard(
                        label: "Spent to Date",
                        value: formatCurrency(totalSpent),
                        color: BuildTrackColors.primary,
                        icon: "arrow.up.circle.fill"
                    )
                }
                
                Divider()
                
                // Burn rate
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Budget Utilisation")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(budgetUtilisation * 100))%")
                            .font(.subheadline.bold())
                            .foregroundStyle(budgetUtilisationColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(budgetUtilisationColor)
                                .frame(width: max(geometry.size.width * CGFloat(budgetUtilisation), 4), height: 8)
                                .animation(.easeInOut(duration: 0.8), value: budgetUtilisation)
                        }
                    }
                    .frame(height: 8)
                    
                    Text(remainingBudgetText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Over-budget projects
                if !overBudgetProjects.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Over Budget Alert")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                        
                        ForEach(overBudgetProjects.prefix(3)) { project in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text(project.name)
                                    .font(.caption)
                                Spacer()
                                Text(formatCurrency(project.spentToDate - project.budget))
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Status Breakdown
    
    private var statusBreakdownSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Project Status Breakdown")
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatusCountCard(status: .planning, count: planningCount, total: projects.count)
                    StatusCountCard(status: .active, count: activeCount, total: projects.count)
                    StatusCountCard(status: .onHold, count: onHoldCount, total: projects.count)
                    StatusCountCard(status: .completed, count: completedCount, total: projects.count)
                    StatusCountCard(status: .cancelled, count: cancelledCount, total: projects.count)
                }
            }
        }
    }
    
    // MARK: - Tasks Analytics
    
    private var tasksAnalyticsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Tasks Overview")
                
                // Priority breakdown
                HStack(spacing: 12) {
                    TaskPriorityBar(label: "Critical", count: criticalTaskCount, total: tasks.count, color: .red)
                    TaskPriorityBar(label: "High", count: highTaskCount, total: tasks.count, color: .orange)
                    TaskPriorityBar(label: "Medium", count: mediumTaskCount, total: tasks.count, color: .blue)
                    TaskPriorityBar(label: "Low", count: lowTaskCount, total: tasks.count, color: .gray)
                }
                
                Divider()
                
                // Completion rate
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completion Rate")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(completionRate)%")
                            .font(.title3.bold())
                            .foregroundStyle(completionRateColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Overdue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(overdueTaskCount)")
                            .font(.title3.bold())
                            .foregroundStyle(overdueTaskCount > 0 ? .red : .green)
                    }
                }
            }
        }
    }
    
    // MARK: - Safety Summary
    
    private var safetySummarySection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Safety Summary")
                
                HStack(spacing: 12) {
                    SafetyMetricCard(
                        label: "Open Incidents",
                        value: openIncidentsCount,
                        color: .red,
                        icon: "exclamationmark.shield.fill"
                    )
                    SafetyMetricCard(
                        label: "Resolved",
                        value: resolvedIncidentsCount,
                        color: .green,
                        icon: "checkmark.shield.fill"
                    )
                }
                
                if !recentIncidents.isEmpty {
                    Divider()
                    Text("Recent Incidents")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(recentIncidents.prefix(3)) { incident in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(severityColor(incident.severity))
                                .font(.caption)
                            Text(incident.title)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            SeverityBadge(severity: incident.severity)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Top Projects
    
    private var topProjectsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Top Projects by Budget")
                
                ForEach(filteredProjects.sorted { $0.budget > $1.budget }.prefix(5)) { project in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(project.clientName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(project.budget))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(Int(project.progress))% complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if project.id != filteredProjects.sorted(by: { $0.budget > $1.budget }).prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var activeProjectsCount: Int { filteredProjects.filter { $0.status == .active }.count }
    var openTasksCount: Int { tasks.filter { $0.status != .completed }.count }
    var completedTasksCount: Int { tasks.filter { $0.status == .completed }.count }
    var incidentsCount: Int { incidents.count }
    
    var totalBudget: Double { filteredProjects.reduce(0) { $0 + $1.budget } }
    var totalSpent: Double { filteredProjects.reduce(0) { $0 + $1.spentToDate } }
    var budgetUtilisation: Double { totalBudget > 0 ? totalSpent / totalBudget : 0 }
    var budgetUtilisationColor: Color {
        switch budgetUtilisation {
        case 0..<0.6: .green
        case 0.6..<0.85: .orange
        default: .red
        }
    }
    var remainingBudgetText: String {
        let remaining = totalBudget - totalSpent
        return remaining >= 0
            ? "\(formatCurrency(remaining)) remaining"
            : "\(formatCurrency(abs(remaining))) over budget"
    }
    var overBudgetProjects: [Project] {
        filteredProjects.filter { $0.spentToDate > $0.budget && $0.budget > 0 }
    }
    
    var planningCount: Int { filteredProjects.filter { $0.status == .planning }.count }
    var activeCount: Int { filteredProjects.filter { $0.status == .active }.count }
    var onHoldCount: Int { filteredProjects.filter { $0.status == .onHold }.count }
    var completedCount: Int { filteredProjects.filter { $0.status == .completed }.count }
    var cancelledCount: Int { filteredProjects.filter { $0.status == .cancelled }.count }
    
    var criticalTaskCount: Int { tasks.filter { $0.priority == .critical }.count }
    var highTaskCount: Int { tasks.filter { $0.priority == .high }.count }
    var mediumTaskCount: Int { tasks.filter { $0.priority == .medium }.count }
    var lowTaskCount: Int { tasks.filter { $0.priority == .low }.count }
    var completionRate: Int {
        guard !tasks.isEmpty else { return 0 }
        return Int(round(Double(completedTasksCount) / Double(tasks.count) * 100))
    }
    var completionRateColor: Color {
        switch completionRate {
        case 0..<40: .red
        case 40..<70: .orange
        default: .green
        }
    }
    var overdueTaskCount: Int {
        let now = Date()
        return tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return due < now && task.status != .completed
        }.count
    }
    
    var openIncidentsCount: Int { incidents.filter { $0.incidentStatus == .open || $0.incidentStatus == .investigating }.count }
    var resolvedIncidentsCount: Int { incidents.filter { $0.incidentStatus == .resolved || $0.incidentStatus == .closed }.count }
    var recentIncidents: [Incident] { Array(incidents.prefix(10)) }
    
    // MARK: - Helpers
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
    }
    
    func severityColor(_ severity: IncidentSeverity) -> Color {
        switch severity {
        case .low: .yellow
        case .medium: .orange
        case .high: .red
        case .critical: .purple
        }
    }
}

// MARK: - Supporting Types

enum ReportPeriod: String, CaseIterable, Identifiable {
    case allTime, thisWeek, thisMonth, thisQuarter, thisYear
    
    var id: String { rawValue }
    var label: String {
        switch self {
        case .allTime: "All Time"
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        case .thisQuarter: "This Quarter"
        case .thisYear: "This Year"
        }
    }
}

struct BudgetMetricCard: View {
    let label: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(Color(.label))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatusCountCard: View {
    let status: ProjectStatus
    let count: Int
    let total: Int
    
    var percentage: Double { total > 0 ? Double(count) / Double(total) : 0 }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundStyle(BuildTrackColors.statusColor(status))
            Text("\(count)")
                .font(.title3.bold())
            Text(status.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GeometryReader { geometry in
                Capsule()
                    .fill(BuildTrackColors.statusColor(status))
                    .frame(width: max(geometry.size.width * CGFloat(percentage), 4), height: 4)
            }
            .frame(height: 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct TaskPriorityBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    var percentage: Double { total > 0 ? Double(count) / Double(total) : 0 }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundStyle(color)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
                    .overlay(
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(height: max(geometry.size.height * CGFloat(percentage), 2))
                        }
                    )
            }
            .frame(height: 60)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SafetyMetricCard: View {
    let label: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title3.bold())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ReportsView()
            .modelContainer(for: [Project.self, TaskItem.self, Incident.self])
    }
}
