import SwiftUI

struct DeepLinkRouter {
    enum Screen: Equatable, Hashable {
        case dashboard
        case projects
        case projectDetail(UUID)
        case tasks
        case taskDetail(UUID)
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
        
        let path = components.host ?? ""
        let params = components.queryItems ?? []
        
        switch path {
        case "dashboard":
            return .dashboard
        case "projects":
            return .projects
        case "project":
            if let idStr = params.first(where: { $0.name == "id" })?.value,
               let id = UUID(uuidString: idStr) {
                return .projectDetail(id)
            }
            return .projects
        case "tasks":
            return .tasks
        case "task":
            if let idStr = params.first(where: { $0.name == "id" })?.value,
               let id = UUID(uuidString: idStr) {
                return .taskDetail(id)
            }
            return .tasks
        case "map":
            return .map
        case "safety":
            return .safety
        case "team":
            return .team
        case "notifications":
            return .notifications
        default:
            return nil
        }
    }
    
    func resolve(_ string: String) -> Screen? {
        // Handle both "buildtrack://task/{id}" and regular URLs
        if string.hasPrefix("buildtrack://") {
            if let url = URL(string: string) {
                return resolve(url)
            }
            
            // Manual parse for "buildtrack://screen/id" format
            let path = String(string.dropFirst("buildtrack://".count))
            let parts = path.split(separator: "/")
            guard let screen = parts.first else { return nil }
            
            switch String(screen) {
            case "project":
                if parts.count > 1, let id = UUID(uuidString: String(parts[1])) {
                    return .projectDetail(id)
                }
                return .projects
            case "task":
                if parts.count > 1, let id = UUID(uuidString: String(parts[1])) {
                    return .taskDetail(id)
                }
                return .tasks
            case "dashboard": return .dashboard
            case "map": return .map
            case "safety": return .safety
            case "team": return .team
            case "notifications": return .notifications
            default: return nil
            }
        }
        
        return nil
    }
    
    func tabFor(_ screen: Screen) -> Int {
        switch screen {
        case .dashboard: 0
        case .projects, .projectDetail: 1
        case .tasks, .taskDetail: 2
        case .map: 3
        case .safety: 4
        case .team: 5
        case .notifications: 6
        }
    }
}
