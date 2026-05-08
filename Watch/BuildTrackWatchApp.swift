import SwiftUI

@main
struct BuildTrackWatchApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

struct WatchContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WatchDashboardView()
                .tag(0)
            WatchTasksView()
                .tag(1)
            WatchSafetyView()
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
    }
}

struct WatchDashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("BuildTrack")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    WatchStatBlock(value: 5, label: "Projects", color: .blue)
                    WatchStatBlock(value: 3, label: "Tasks", color: .green)
                }
                
                HStack(spacing: 8) {
                    WatchStatBlock(value: 0, label: "Incidents", color: .orange)
                    WatchStatBlock(value: 2, label: "Team", color: .purple)
                }
            }
            .padding()
        }
    }
}

struct WatchTasksView: View {
    @State private var tasks = [
        WatchTask(title: "Foundation pour", priority: .high, completed: false),
        WatchTask(title: "Steel inspection", priority: .medium, completed: false),
        WatchTask(title: "Site cleanup", priority: .low, completed: true),
    ]
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                HStack {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.completed ? .green : .gray)
                    Text(task.title)
                        .strikethrough(task.completed)
                    Spacer()
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .navigationTitle("Tasks")
    }
}

struct WatchSafetyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            
            Text("No Active Incidents")
                .font(.headline)
            
            Text("All sites are safe")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Report Incident") {
                // Open iPhone app to report
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .navigationTitle("Safety")
    }
}

struct WatchStatBlock: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WatchTask: Identifiable {
    let id = UUID()
    let title: String
    let priority: WatchTaskPriority
    let completed: Bool
}

enum WatchTaskPriority {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }
}

#Preview {
    WatchContentView()
}
