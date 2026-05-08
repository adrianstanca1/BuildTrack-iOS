import AppIntents
import Foundation

// MARK: - Siri Shortcuts for BuildTrack

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Task"
    static var description = IntentDescription("Create a new task in BuildTrack")
    
    @Parameter(title: "Title", requestValueDialog: "What's the task title?")
    var title: String
    
    @Parameter(title: "Priority", default: .medium)
    var priority: TaskPriorityParameter
    
    @Parameter(title: "Due Date", default: .now)
    var dueDate: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create task \($title) with \($priority) priority")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In production, this would insert into SwiftData + sync to Supabase
        let taskId = UUID().uuidString
        Logger.tasks.info("Siri created task: \(title) [\(taskId)]")
        return .result(value: "Task '\(title)' created successfully")
    }
}

struct LogIncidentIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Safety Incident"
    static var description = IntentDescription("Log a safety incident quickly")
    
    @Parameter(title: "Title", requestValueDialog: "What happened?")
    var title: String
    
    @Parameter(title: "Severity", default: .medium)
    var severity: IncidentSeverityParameter
    
    @Parameter(title: "Location", default: "Site")
    var location: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log incident '\($title)' at \($location)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        Logger.safety.info("Siri logged incident: \(title) [\(severity)] at \(location)")
        return .result(value: "Incident '\(title)' logged")
    }
}

struct CheckTodayTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Today's Tasks"
    static var description = IntentDescription("Get a summary of today's tasks")
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In production, query SwiftData for today's tasks
        let count = 3 // placeholder
        return .result(value: "You have \(count) tasks due today")
    }
}

struct GetProjectStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Project Status"
    static var description = IntentDescription("Check the status of active projects")
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In production, query SwiftData for project summary
        let active = 5
        let completed = 12
        return .result(value: "\(active) active projects, \(completed) completed")
    }
}

// MARK: - Parameter Types

enum TaskPriorityParameter: String, AppEnum {
    case low, medium, high
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task Priority")
    
    static var caseDisplayRepresentations: [TaskPriorityParameter: DisplayRepresentation] = [
        .low: DisplayRepresentation(title: "Low"),
        .medium: DisplayRepresentation(title: "Medium"),
        .high: DisplayRepresentation(title: "High"),
    ]
}

enum IncidentSeverityParameter: String, AppEnum {
    case low, medium, high, critical
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Severity")
    
    static var caseDisplayRepresentations: [IncidentSeverityParameter: DisplayRepresentation] = [
        .low: DisplayRepresentation(title: "Low"),
        .medium: DisplayRepresentation(title: "Medium"),
        .high: DisplayRepresentation(title: "High"),
        .critical: DisplayRepresentation(title: "Critical"),
    ]
}

// MARK: - Shortcut Provider

struct BuildTrackShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "Create a task in BuildTrack",
                "Add task to BuildTrack",
                "New BuildTrack task",
            ],
            shortTitle: "Create Task",
            systemImageName: "checklist"
        )
        
        AppShortcut(
            intent: LogIncidentIntent(),
            phrases: [
                "Log a safety incident in BuildTrack",
                "Report incident in BuildTrack",
            ],
            shortTitle: "Log Incident",
            systemImageName: "exclamationmark.shield"
        )
        
        AppShortcut(
            intent: CheckTodayTasksIntent(),
            phrases: [
                "What's on my BuildTrack today",
                "BuildTrack tasks today",
            ],
            shortTitle: "Today's Tasks",
            systemImageName: "list.clipboard"
        )
        
        AppShortcut(
            intent: GetProjectStatusIntent(),
            phrases: [
                "BuildTrack project status",
                "How are my BuildTrack projects",
            ],
            shortTitle: "Project Status",
            systemImageName: "building.2"
        )
    }
}
