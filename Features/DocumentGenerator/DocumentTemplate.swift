import Foundation

enum DocumentTemplate: String, CaseIterable, Identifiable {
    case dailyReport, timesheetSummary, safetyIncident, projectStatus, budgetOverview, punchList

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dailyReport: return "Daily Report"
        case .timesheetSummary: return "Timesheet Summary"
        case .safetyIncident: return "Safety Incident Report"
        case .projectStatus: return "Project Status Report"
        case .budgetOverview: return "Budget Overview"
        case .punchList: return "Punch List"
        }
    }

    var icon: String {
        switch self {
        case .dailyReport: return "doc.text"
        case .timesheetSummary: return "clock.arrow.circlepath"
        case .safetyIncident: return "exclamationmark.shield"
        case .projectStatus: return "chart.bar"
        case .budgetOverview: return "sterlingsign.circle"
        case .punchList: return "wrench.and.screwdriver"
        }
    }

    var description: String {
        switch self {
        case .dailyReport: return "Generate a PDF daily report for a selected project and date range."
        case .timesheetSummary: return "Summarise worker hours and tasks across a date range."
        case .safetyIncident: return "Compile safety incidents into a formatted PDF report."
        case .projectStatus: return "Project health, tasks and budget in one status report."
        case .budgetOverview: return "Budget vs actual spend breakdown with charts."
        case .punchList: return "Export open and resolved punch items for a project."
        }
    }

    var color: String {
        switch self {
        case .dailyReport: return "blue"
        case .timesheetSummary: return "green"
        case .safetyIncident: return "red"
        case .projectStatus: return "purple"
        case .budgetOverview: return "orange"
        case .punchList: return "indigo"
        }
    }
}
