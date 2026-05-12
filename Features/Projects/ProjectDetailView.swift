import SwiftUI
import SwiftData

// MARK: - Project Detail View

@MainActor
struct ProjectDetailView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DetailTab = .overview
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false
    @State private var showAddTask = false
    @State private var showAddTeamMember = false

    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case documents = "Documents"
        case team = "Team"
        case timeline = "Timeline"

        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .tasks: return "checklist"
            case .documents: return "doc.on.doc"
            case .team: return "person.3"
            case .timeline: return "calendar.badge.clock"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                heroHeader

                // Tab selector
                tabSelector
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))

                // Tab content
                tabContent
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            ProjectFormView(mode: .edit(project))
        }
        .confirmationDialog("Delete Project?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(project)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(project.name) and all associated data.")
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 16) {
            // Status + progress ring
            HStack(spacing: 20) {
                // Progress ring
                ProgressRingView(progress: project.progress, size: 80, lineWidth: 8)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        StatusBadge(status: project.status)
                        Spacer()
                    }

                    Text("\(Int(project.progress * 100))% Complete")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BuildTrackColors.textPrimary)

                    if let endDate = project.endDate {
                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                        Text(daysRemaining >= 0 ? "\(daysRemaining) days remaining" : "\(abs(daysRemaining)) days overdue")
                            .font(.caption)
                            .foregroundStyle(daysRemaining >= 0 ? .secondary : Color.red)
                    }
                }

                Spacer()
            }

            // Budget bar
            if project.budget > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Budget")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatCurrency(project.spentToDate) + " of " + formatCurrency(project.budget))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(budgetColor)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            let ratio = min(project.spentToDate / project.budget, 1.0)
                            Capsule()
                                .fill(budgetColor)
                                .frame(width: max(geometry.size.width * CGFloat(ratio), 4), height: 8)
                                .animation(.easeInOut(duration: 0.6), value: project.spentToDate)
                        }
                    }
                    .frame(height: 8)
                }
            }

            // Quick stats row
            HStack(spacing: 0) {
                StatItem(icon: "checklist", value: "\(project.tasks?.count ?? 0)", label: "Tasks")
                Divider().frame(height: 36)
                StatItem(icon: "person.3", value: "\(project.workers?.count ?? 0)", label: "Workers")
                Divider().frame(height: 36)
                StatItem(icon: "exclamationmark.shield", value: "\(project.incidents?.count ?? 0)", label: "Incidents")
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    TabButton(
                        icon: tab.icon,
                        label: tab.rawValue,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            OverviewTab(project: project)
        case .tasks:
            ProjectTasksTab(project: project, showAddTask: $showAddTask)
        case .documents:
            ProjectDocumentsTab(project: project)
        case .team:
            ProjectTeamTab(project: project, showAddTeamMember: $showAddTeamMember)
        case .timeline:
            ProjectTimelineTab(project: project)
        }
    }

    private var budgetColor: Color {
        guard project.budget > 0 else { return .secondary }
        let ratio = project.spentToDate / project.budget
        if ratio < 0.6 { return .green }
        else if ratio < 0.85 { return .orange }
        else { return .red }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundStyle(BuildTrackColors.textPrimary)
        }
    }

    private var ringColor: Color {
        switch progress {
        case 0..<0.25: return .red
        case 0.25..<0.5: return .orange
        case 0.5..<0.75: return .yellow
        case 0.75..<1.0: return .green
        default: return .green
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(BuildTrackColors.primary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? .white : BuildTrackColors.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? BuildTrackColors.primary : BuildTrackColors.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let project: Project

    var body: some View {
        VStack(spacing: 16) {
            // Location & Dates
            CardView {
                SectionHeader(title: "Details")
                VStack(spacing: 14) {
                    if !project.locationName.isEmpty {
                        DetailRow(icon: "mappin.and.ellipse", label: "Location", value: project.locationName)
                    }
                    DetailRow(icon: "calendar", label: "Start Date", value: project.startDate.formatted(date: .abbreviated, time: .omitted))
                    if let endDate = project.endDate {
                        DetailRow(icon: "flag", label: "End Date", value: endDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    DetailRow(icon: "building.2", label: "Client", value: project.clientName.isEmpty ? "Not set" : project.clientName)
                }
            }

            // Description
            if !project.descriptionText.isEmpty {
                CardView {
                    SectionHeader(title: "Description")
                    Text(project.descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                        .lineLimit(nil)
                }
            }

            // Budget breakdown
            if project.budget > 0 {
                CardView {
                    SectionHeader(title: "Budget Breakdown")
                    VStack(spacing: 14) {
                        DetailRow(icon: "creditcard", label: "Total Budget", value: formatCurrency(project.budget))
                        DetailRow(icon: "arrow.down.circle", label: "Spent", value: formatCurrency(project.spentToDate))
                        DetailRow(icon: "banknote", label: "Remaining", value: formatCurrency(max(0, project.budget - project.spentToDate)), valueColor: remainingColor)
                        DetailRow(icon: "chart.pie", label: "Utilisation", value: String(format: "%.1f%%", project.budget > 0 ? (project.spentToDate / project.budget) * 100 : 0))
                    }
                }
            }
        }
    }

    private var remainingColor: Color {
        guard project.budget > 0 else { return .secondary }
        let ratio = project.spentToDate / project.budget
        if ratio < 0.6 { return .green }
        else if ratio < 0.85 { return .orange }
        else { return .red }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
    }
}

// MARK: - Project Tasks Tab

struct ProjectTasksTab: View {
    let project: Project
    @Binding var showAddTask: Bool
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var allTasks: [TaskItem]

    var projectTasks: [TaskItem] {
        allTasks.filter { $0.project?.id == project.id }
    }

    var completedTasks: Int {
        projectTasks.filter { $0.status == .completed }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Summary
            HStack(spacing: 12) {
                SummaryCard(title: "Total", value: "\(projectTasks.count)", icon: "checklist", color: BuildTrackColors.primary)
                SummaryCard(title: "Done", value: "\(completedTasks)", icon: "checkmark.circle", color: .green)
                SummaryCard(title: "Pending", value: "\(projectTasks.count - completedTasks)", icon: "clock", color: .orange)
            }

            // Add button
            Button { showAddTask = true } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Task")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            // Task list
            if projectTasks.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "No Tasks",
                    message: "Add tasks to track progress for this project."
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(projectTasks) { task in
                        TaskRowCard(task: task)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            TaskFormView(preselectedProject: project)
        }
    }
}

struct TaskRowCard: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    PriorityBadge(priority: task.priority)

                    if !task.assignedTo.isEmpty {
                        Label(task.assignedTo, systemImage: "person")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }

                    if let due = task.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(isOverdue ? .red : BuildTrackColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Status
            Text(task.status.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusColor: Color {
        switch task.status {
        case .pending: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .blocked: return .red
        }
    }

    private var isOverdue: Bool {
        guard let due = task.dueDate else { return false }
        return due < Date() && task.status != .completed
    }
}

// MARK: - Project Documents Tab

struct ProjectDocumentsTab: View {
    let project: Project
    @Query(sort: \RFI.createdAt, order: .reverse) private var allRFIs: [RFI]
    @Query(sort: \Drawing.createdAt, order: .reverse) private var allDrawings: [Drawing]
    @Query(sort: \Submittal.createdAt, order: .reverse) private var allSubmittals: [Submittal]
    @Query(sort: \Invoice.createdAt, order: .reverse) private var allInvoices: [Invoice]
    @Query(sort: \PunchItem.createdAt, order: .reverse) private var allPunchItems: [PunchItem]

    var projectRFIs: [RFI] { allRFIs.filter { $0.projectId == project.id } }
    var projectDrawings: [Drawing] { allDrawings.filter { $0.projectId == project.id } }
    var projectSubmittals: [Submittal] { allSubmittals.filter { $0.projectId == project.id } }
    var projectInvoices: [Invoice] { allInvoices.filter { $0.projectId == project.id } }
    var projectPunchItems: [PunchItem] { allPunchItems.filter { $0.projectId == project.id } }

    var totalDocuments: Int {
        projectRFIs.count + projectDrawings.count + projectSubmittals.count + projectInvoices.count + projectPunchItems.count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Summary
            SummaryCard(title: "Documents", value: "\(totalDocuments)", icon: "doc.on.doc", color: .indigo)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Document categories
            LazyVStack(spacing: 12) {
                DocumentCategoryRow(icon: "doc.text", label: "RFIs", count: projectRFIs.count, color: .blue)
                DocumentCategoryRow(icon: "doc", label: "Drawings", count: projectDrawings.count, color: .purple)
                DocumentCategoryRow(icon: "doc.on.doc", label: "Submittals", count: projectSubmittals.count, color: .indigo)
                DocumentCategoryRow(icon: "sterlingsign.square", label: "Invoices", count: projectInvoices.count, color: .green)
                DocumentCategoryRow(icon: "wrench.and.screwdriver", label: "Punch Items", count: projectPunchItems.count, color: .orange)
            }
        }
    }
}

struct DocumentCategoryRow: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                Text("\(count) items")
                    .font(.caption)
                    .foregroundStyle(BuildTrackColors.textSecondary)
            }

            Spacer()

            Text("\(count)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Project Team Tab

struct ProjectTeamTab: View {
    let project: Project
    @Binding var showAddTeamMember: Bool
    @Query(sort: \Worker.name) private var allWorkers: [Worker]

    var projectWorkers: [Worker] {
        project.workers ?? []
    }

    var body: some View {
        VStack(spacing: 16) {
            SummaryCard(title: "Team", value: "\(projectWorkers.count)", icon: "person.3", color: .teal)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button { showAddTeamMember = true } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Team Member")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if projectWorkers.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "No Team Members",
                    message: "Add workers to this project."
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(projectWorkers) { worker in
                        WorkerRowCard(worker: worker)
                    }
                }
            }
        }
    }
}

struct WorkerRowCard: View {
    let worker: Worker

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(BuildTrackColors.primary.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.primary)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(worker.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)

                Text(worker.role.label)
                    .font(.caption)
                    .foregroundStyle(BuildTrackColors.textSecondary)

                if !worker.phone.isEmpty {
                    Label(worker.phone, systemImage: "phone")
                        .font(.caption2)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var initials: String {
        let parts = worker.name.split(separator: " ")
        let first = parts.first?.prefix(1).uppercased() ?? "?"
        let last = parts.count > 1 ? parts.last?.prefix(1).uppercased() ?? "" : ""
        return first + last
    }
}

// MARK: - Project Timeline Tab

struct ProjectTimelineTab: View {
    let project: Project

    var events: [TimelineEvent] {
        var items: [TimelineEvent] = []

        // Start date
        items.append(TimelineEvent(
            date: project.startDate,
            title: "Project Started",
            description: "Project created and planning phase begins.",
            icon: "flag.fill",
            color: .green
        ))

        // Any updates
        if project.updatedAt > project.startDate.addingTimeInterval(3600) {
            items.append(TimelineEvent(
                date: project.updatedAt,
                title: "Project Updated",
                description: "Latest project information updated.",
                icon: "pencil",
                color: .blue
            ))
        }

        // End date if set
        if let endDate = project.endDate {
            items.append(TimelineEvent(
                date: endDate,
                title: "Target Completion",
                description: "Scheduled project completion date.",
                icon: "calendar.badge.checkmark",
                color: .orange
            ))
        }

        // Status milestones
        if project.status == .completed {
            items.append(TimelineEvent(
                date: project.updatedAt,
                title: "Project Completed",
                description: "All work finished and project closed.",
                icon: "checkmark.seal.fill",
                color: .green
            ))
        } else if project.status == .onHold {
            items.append(TimelineEvent(
                date: project.updatedAt,
                title: "Project On Hold",
                description: "Work temporarily paused.",
                icon: "pause.circle.fill",
                color: .orange
            ))
        }

        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 16) {
            if events.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No Timeline Events",
                    message: "Project milestones will appear here."
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        TimelineRow(
                            event: event,
                            isFirst: index == 0,
                            isLast: index == events.count - 1
                        )
                    }
                }
            }
        }
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct TimelineRow: View {
    let event: TimelineEvent
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line + dot
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                } else {
                    Spacer().frame(width: 2)
                }

                ZStack {
                    Circle()
                        .fill(event.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: event.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(event.color)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                } else {
                    Spacer().frame(width: 2)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)

                Text(event.description)
                    .font(.caption)
                    .foregroundStyle(BuildTrackColors.textSecondary)

                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(BuildTrackColors.textTertiary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 8)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectDetailView(project: Project(name: "High-rise Tower", descriptionText: "45-storey residential", status: .active, budget: 12_500_000, spentToDate: 7_200_000, progress: 0.58, locationName: "Downtown", clientName: "Metro Dev"))
        .modelContainer(for: [Project.self, TaskItem.self, Worker.self])
}
