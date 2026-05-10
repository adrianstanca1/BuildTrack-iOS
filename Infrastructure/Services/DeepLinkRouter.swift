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

    private struct Route {
        let list: Screen
        let detail: ((UUID) -> Screen)?
    }

    private static let routes: [String: Route] = [
        "dashboard": Route(list: .dashboard, detail: nil),
        "projects": Route(list: .projects, detail: nil),
        "project": Route(list: .projects, detail: Screen.projectDetail),
        "tasks": Route(list: .tasks, detail: nil),
        "task": Route(list: .tasks, detail: Screen.taskDetail),
        "punch": Route(list: .punchItems, detail: Screen.punchItemDetail),
        "punchitems": Route(list: .punchItems, detail: Screen.punchItemDetail),
        "punchitem": Route(list: .punchItems, detail: Screen.punchItemDetail),
        "rfis": Route(list: .rfis, detail: nil),
        "rfi": Route(list: .rfis, detail: Screen.rfiDetail),
        "drawings": Route(list: .drawings, detail: nil),
        "drawing": Route(list: .drawings, detail: Screen.drawingDetail),
        "map": Route(list: .map, detail: nil),
        "safety": Route(list: .safety, detail: nil),
        "inspection": Route(list: .safety, detail: nil),
        "inspections": Route(list: .safety, detail: nil),
        "incident": Route(list: .safety, detail: nil),
        "incidents": Route(list: .safety, detail: nil),
        "team": Route(list: .team, detail: nil),
        "notifications": Route(list: .notifications, detail: nil),
    ]

    func resolve(_ url: URL) -> Screen? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "buildtrack",
              let route = Self.routes[components.host ?? ""] else {
            return nil
        }

        let pathParts = components.path.split(separator: "/").map(String.init)
        let firstPathId = pathParts.first.flatMap(UUID.init(uuidString:))
        let queryId = (components.queryItems ?? [])
            .first(where: { $0.name == "id" })?
            .value.flatMap(UUID.init(uuidString:))

        if let id = firstPathId ?? queryId, let detail = route.detail {
            return detail(id)
        }
        return route.list
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
