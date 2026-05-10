import SwiftUI
import SwiftData

@main
struct BuildTrackApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
        .modelContainer(SwiftDataStack.shared.container)
    }
}
