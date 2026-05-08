import SwiftUI
import SwiftData

@main
struct BuildTrackApp: App {
    @State private var authManager = AuthManager()
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Project.self,
            TaskItem.self,
            Incident.self,
            Inspection.self,
            Worker.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
        .modelContainer(modelContainer)
    }
}
