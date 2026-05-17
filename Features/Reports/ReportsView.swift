import SwiftUI
import SwiftData

// MARK: - Professional Reports & Analytics View

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
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Period Selector
                periodSelector
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0)
                
                // Generate Report
                generateReportSection
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.05)
                
                // Summary Cards
                summaryCards
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.1)
                
                // Budget Health
                budgetHealthSection
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.15)
                
                // Status Breakdown
                statusBreakdownSection
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.2)
                
                // Tasks Analytics
                tasksAnalyticsSection
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.25)
                
                // Safety Summary
                safetySummarySection
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.3)
                
                // Top Projects
                topProjectsSection
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.35)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reports & Analytics")
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Button {
                        DesignTokens.Haptic.light()
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.label)
                            .font(DesignTokens.Typography.callout.weight(selectedPeriod == period ? .semibold : .medium))
                            .foregroundStyle(selectedPeriod == period ? .white : BuildTrackColors.primary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
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
    
    // MARK: - Generate Report
    
    private var generateReportSection: some View {
        NavigationLink {
            DocumentGeneratorView()
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BuildTrackColors.primary)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate Report")
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    Text("Create PDF reports from templates")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(BuildTrackColors.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.md) {
            StatMiniCard(
                icon: "building.2.fill",
                value: "\(activeProjectsCount)",
                label: "Active Projects",
                color: BuildTrackColors.success
            )
            StatMiniCard(
                icon: "list.clipboard",
                value: "\(openTasksCount)",
                label: "Open Tasks",
                color: BuildTrackColors.info
            )
            StatMiniCard(
                icon: "checkmark.circle.fill",
                value: "\(completedTasksCount)",
                label: "Completed",
                color: BuildTrackColors.primary
            )
            StatMiniCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(incidentsCount)",
                label: "Incidents",
                color: BuildTrackColors.danger
            )
        }
    }
    
    // MARK: - Budget Health
    
    private var budgetHealthSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Budget Health")
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    BudgetMetricCardPro(
                        label: "Total Budget",
                        value: formatCurrency(totalBudget),
                        color: BuildTrackColors.info,
                        icon: "creditcard.fill"
                    )
                    BudgetMetricCardPro(
                        label: "Spent to Date",
                        value: formatCurrency(totalSpent),
                        color: BuildTrackColors.primary,
                        icon: "arrow.up.circle.fill"
                    )
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("Budget Utilisation")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                        Spacer()
                        Text("\(Int(budgetUtilisation * 100))%")
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                            .foregroundStyle(budgetUtilisationColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(BuildTrackColors.textTertiary.opacity(0.2))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(budgetUtilisationColor)
                                .frame(width: max(geometry.size.width * CGFloat(budgetUtilisation), 4), height: 8)
                        }
                    }
                    .frame(height: 8)
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
    }
    
    // MARK: - Status Breakdown
    
    private var statusBreakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Project Status")
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            HStack(spacing: DesignTokens.Spacing.md) {
                StatusBreakdownCard(label: "Planning", count: planningCount, color: BuildTrackColors.info)
                StatusBreakdownCard(label: "Active", count: activeCount, color: BuildTrackColors.primary)
                StatusBreakdownCard(label: "On Hold", count: onHoldCount, color: BuildTrackColors.warning)
                StatusBreakdownCard(label: "Completed", count: completedCount, color: BuildTrackColors.success)
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(BuildTrackColors.border, lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Tasks Analytics
    
    private var tasksAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Tasks Overview")
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            HStack(spacing: DesignTokens.Spacing.md) {
                TaskAnalyticsCard(
                    icon: "checklist",
                    value: "\(tasks.count)",
                    label: "Total Tasks",
                    color: BuildTrackColors.primary
                )
                TaskAnalyticsCard(
                    icon: "clock.fill",
                    value: "\(overdueTasksCount)",
                    label: "Overdue",
                    color: BuildTrackColors.danger
                )
                TaskAnalyticsCard(
                    icon: "calendar.badge.checkmark",
                    value: "\(dueThisWeekCount)",
                    label: "Due This Week",
                    color: BuildTrackColors.success
                )
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(BuildTrackColors.border, lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Safety Summary
    
    private var safetySummarySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Safety Summary")
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            HStack(spacing: DesignTokens.Spacing.md) {
                SafetySummaryCard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(highSeverityCount)",
                    label: "High Severity",
                    color: BuildTrackColors.danger
                )
                SafetySummaryCard(
                    icon: "checkmark.shield.fill",
                    value: "\(resolvedIncidentsCount)",
                    label: "Resolved",
                    color: BuildTrackColors.success
                )
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(BuildTrackColors.border, lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Top Projects
    
    private var topProjectsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Top Projects by Budget")
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(topProjects.prefix(5)) { project in
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(BuildTrackColors.primary.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "building.2")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(BuildTrackColors.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .font(DesignTokens.Typography.callout.weight(.semibold))
                                .foregroundStyle(BuildTrackColors.textPrimary)
                                .lineLimit(1)
                            
                            if project.budget > 0 {
                                Text(formatCurrency(project.budget))
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundStyle(BuildTrackColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        if project.progress > 0 {
                            Text("\(Int(project.progress))%")
                                .font(DesignTokens.Typography.caption.weight(.semibold))
                                .foregroundStyle(BuildTrackColors.primary)
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(BuildTrackColors.border, lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var activeProjectsCount: Int { filteredProjects.filter { $0.status == .active }.count }
    private var openTasksCount: Int { tasks.filter { $0.status != .completed }.count }
    private var completedTasksCount: Int { tasks.filter { $0.status == .completed }.count }
    private var incidentsCount: Int { incidents.count }
    private var totalBudget: Double { filteredProjects.compactMap { $0.budget }.reduce(0, +) }
    private var totalSpent: Double { 0 } // Placeholder - Project model doesn't have spent property
    private var budgetUtilisation: Double { totalBudget > 0 ? totalSpent / totalBudget : 0 }
    private var budgetUtilisationColor: Color { budgetUtilisation > 0.9 ? .red : budgetUtilisation > 0.7 ? .orange : .green }
    private var planningCount: Int { filteredProjects.filter { $0.status == .planning }.count }
    private var activeCount: Int { filteredProjects.filter { $0.status == .active }.count }
    private var onHoldCount: Int { filteredProjects.filter { $0.status == .onHold }.count }
    private var completedCount: Int { filteredProjects.filter { $0.status == .completed }.count }
    private var overdueTasksCount: Int { tasks.filter { $0.isOverdue }.count }
    private var dueThisWeekCount: Int { tasks.filter { $0.isDueThisWeek }.count }
    private var highSeverityCount: Int { incidents.filter { $0.severity == .high }.count }
    private var resolvedIncidentsCount: Int { incidents.filter { $0.incidentStatus == .resolved }.count }
    private var topProjects: [Project] { filteredProjects.sorted { ($0.budget ?? 0) > ($1.budget ?? 0) } }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
}

// MARK: - Supporting Views

struct BudgetMetricCardPro: View {
    let label: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            Text(value)
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }
}

struct StatusBreakdownCard: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text("\(count)")
                .font(DesignTokens.Typography.callout.weight(.bold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct TaskAnalyticsCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            
            Text(value)
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SafetySummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            
            Text(value)
                .font(DesignTokens.Typography.callout.weight(.semibold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Report Period

enum ReportPeriod: String, CaseIterable {
    case allTime, thisWeek, thisMonth, thisQuarter, thisYear
    
    var label: String {
        switch self {
        case .allTime: return "All Time"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .thisQuarter: return "This Quarter"
        case .thisYear: return "This Year"
        }
    }
}

// MARK: - Document Generator View (Placeholder)

struct DocumentGeneratorView: View {
    var body: some View {
        Text("Document Generator")
            .navigationTitle("Generate Report")
    }
}

#Preview("Professional Reports") {
    ReportsView()
}
