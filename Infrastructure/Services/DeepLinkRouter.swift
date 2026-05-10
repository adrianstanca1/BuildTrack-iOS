import SwiftUI

struct DeepLinkRouter {
    enum Screen: Equatable, Hashable {
        case dashboard
        case projects
        case projectDetail(UUID)
        case tasks
        case taskDetail(UUID)
        case punchItems
        case punchItemDetail(UUID)
        case rfis
        case rfiDetail(UUID)
        case drawings
        case drawingDetail(UUID)
        case map
        case safety
        case team
        case notifications
    }

    func resolve(_ url: URL) -> Screen? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "buildtrack" else {
            return nil
        }

        let host = components.host ?? ""
        let pathParts = components.path
            .split(separator: "/")
            .map(String.init)
        let params = components.queryItems ?? []

        // Resolve `buildtrack://punch/<uuid>` (host=punch, path=<uuid>) and `buildtrack://punch?id=<uuid>`.
        let firstPathId = pathParts.first.flatMap(UUID.init(uuidString:))
        let queryId = params.first(where: { $0.name == "id" })?.value.flatMap(UUID.init(uuidString:))
        let id = firstPathId ?? queryId

        switch host {
        case "dashboard": return .dashboard
        case "projects": return .projects
        case "project":
            return id.map(Screen.projectDetail) ?? .projects
        case "tasks": return .tasks
        case "task":
            return id.map(Screen.taskDetail) ?? .tasks
        case "punch", "punchitems":
            if let id { return .punchItemDetail(id) }
            return .punchItems
        case "punchitem":
            return id.map(Screen.punchItemDetail) ?? .punchItems
        case "rfis":
            return .rfis
        case "rfi":
            return id.map(Screen.rfiDetail) ?? .rfis
        case "drawings":
            return .drawings
        case "drawing":
            return id.map(Screen.drawingDetail) ?? .drawings
        case "map": return .map
        case "safety", "inspection", "inspections", "incident", "incidents":
            return .safety
        case "team": return .team
        case "notifications": return .notifications
        default: return nil
        }
    }

    func resolve(_ string: String) -> Screen? {
        guard let url = URL(string: string) else { return nil }
        return resolve(url)
    }

    /// Tab index that should be foregrounded for this screen. Detail screens drop to the parent
    /// tab; surfaces without a tab (rfis, map, safety, team, notifications) fall back to Dashboard
    /// — they're reachable via push-navigation from there.
    func tabFor(_ screen: Screen) -> Int {
        switch screen {
        case .dashboard, .rfis, .rfiDetail, .map, .safety, .team, .notifications:
            return 0
        case .projects, .projectDetail:
            return 1
        case .tasks, .taskDetail:
            return 2
        case .punchItems, .punchItemDetail:
            return 3
        case .drawings, .drawingDetail:
            return 4
        }
    }
}
