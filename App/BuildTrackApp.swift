import SwiftUI
import SwiftData

@main
struct BuildTrackApp: App {
    @State private var authManager = AuthManager()
    
    var modelContainer: ModelContainer {
        let schema = Schema([
            Project.self,
            TaskItem.self,
            Incident.self,
            Inspection.self,
            Worker.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: config)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .modelContainer(modelContainer)
                        .environment(authManager)
                } else {
                    AuthView()
                        .environment(authManager)
                }
            }
            .preferredColorScheme(authManager.colorScheme)
        }
    }
}
