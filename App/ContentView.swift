import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AuthManager.self)
    private var authManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "rectangle.grid.1x2.fill") }
                .tag(0)
            
            NavigationStack { ProjectsListView() }
                .tabItem { Label("Projects", systemImage: "building.2.fill") }
                .tag(1)
            
            NavigationStack { TasksListView() }
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(2)
            
            NavigationStack { MapView() }
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(3)
            
            NavigationStack { SafetyView() }
                .tabItem { Label("Safety", systemImage: "shield.fill") }
                .tag(4)
            
            NavigationStack { TeamView() }
                .tabItem { Label("Team", systemImage: "person.3.fill") }
                .tag(5)
            
            NavigationStack { NotificationInboxView() }
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .tag(6)
            
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(7)
        }
    }
}
