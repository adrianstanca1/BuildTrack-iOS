import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AuthManager.self)
    private var authManager
    @State private var selectedTab = 0
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
            } else {
                AuthView()
            }
        }
        .onAppear {
            // Check if first launch
            if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                showOnboarding = false
            }
        }
    }
}

// MARK: - Modern Tab Bar

struct MainTabView: View {
    @Binding var selectedTab: Int
    @State private var tabItems = [
        TabItem(icon: "rectangle.grid.1x2.fill", label: "Dashboard"),
        TabItem(icon: "building.2.fill", label: "Projects"),
        TabItem(icon: "checklist", label: "Tasks"),
        TabItem(icon: "wrench.and.screwdriver.fill", label: "Punch"),
        TabItem(icon: "doc.text.fill", label: "Drawings")
    ]
    
    struct TabItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { DashboardView() }
                    .tag(0)
                
                NavigationStack { ProjectsListView() }
                    .tag(1)
                
                NavigationStack { TasksListView() }
                    .tag(2)
                
                NavigationStack { PunchItemsListView() }
                    .tag(3)
                
                NavigationStack { DrawingsListView() }
                    .tag(4)
            }
            .toolbar(.hidden, for: .tabBar)
            
            // Custom Tab Bar
            CustomTabBar(
                items: tabItems,
                selectedTab: $selectedTab
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

struct CustomTabBar: View {
    let items: [MainTabView.TabItem]
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TabBarButton(
                    icon: item.icon,
                    label: item.label,
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -4)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? BuildTrackColors.primary : Color(.tertiaryLabel))
                    .frame(height: 26)
                    .background(
                        Circle()
                            .fill(isSelected ? BuildTrackColors.primary.opacity(0.12) : Color.clear)
                            .frame(width: 44, height: 44)
                    )
                
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? BuildTrackColors.primary : Color(.tertiaryLabel))
            }
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .modelContainer(for: [Project.self, TaskItem.self])
}
