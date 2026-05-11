import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AuthManager.self)
    private var authManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var showOnboarding = false
    @State private var isLocked = AppLockController.shouldLockOnLaunch
    @State private var deepLink: DeepLinkRouter.Screen?

    private static let router = DeepLinkRouter()

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if isLocked {
                    AppLockView(isLocked: $isLocked)
                } else {
                    MainTabView(selectedTab: $selectedTab, deepLink: $deepLink)
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background, AppLockController.isBiometricEnabled {
                isLocked = true
            }
        }
        .onOpenURL { url in
            if let screen = ContentView.router.resolve(url) {
                handleDeepLink(screen)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { note in
            guard let raw = note.userInfo?["url"] as? String,
                  let screen = ContentView.router.resolve(raw) else { return }
            handleDeepLink(screen)
        }
    }

    private func handleDeepLink(_ screen: DeepLinkRouter.Screen) {
        guard authManager.isAuthenticated, !isLocked else {
            deepLink = screen
            return
        }
        selectedTab = ContentView.router.tabFor(screen)
        deepLink = screen
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var deepLink: DeepLinkRouter.Screen?
    @State private var tabItems: [TabItem] = []

    struct TabItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let view: AnyView
    }

    init(selectedTab: Binding<Int>, deepLink: Binding<DeepLinkRouter.Screen?>) {
        _selectedTab = selectedTab
        _deepLink = deepLink
        _tabItems = State(initialValue: [
            TabItem(icon: "house.fill", label: "Home", view: AnyView(DashboardView())),
            TabItem(icon: "building.2.fill", label: "Projects", view: AnyView(ProjectsListView())),
            TabItem(icon: "checklist", label: "Tasks", view: AnyView(TasksListView())),
            TabItem(icon: "square.grid.2x2", label: "More", view: AnyView(MoreMenuView())),
        ])
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { DashboardView() }.tag(0)
                NavigationStack { ProjectsListView() }.tag(1)
                NavigationStack { TasksListView() }.tag(2)
                NavigationStack { MoreMenuView() }.tag(3)
            }
            .toolbar(.hidden, for: .tabBar)

            CustomTabBar(items: tabItems, selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - More Menu View

struct MoreMenuView: View {
    let menuItems: [MenuItem] = [
        MenuItem(icon: "wrench.and.screwdriver", label: "Punch Items", color: .orange, destination: AnyView(PunchItemsListView())),
        MenuItem(icon: "doc.text", label: "RFIs", color: .blue, destination: AnyView(RFIsListView())),
        MenuItem(icon: "doc", label: "Drawings", color: .purple, destination: AnyView(DrawingsListView())),
        MenuItem(icon: "shield", label: "Safety", color: .red, destination: AnyView(SafetyView())),
        MenuItem(icon: "sterlingsign.circle", label: "Budget", color: .green, destination: AnyView(BudgetListView())),
        MenuItem(icon: "cube.box", label: "Materials", color: .cyan, destination: AnyView(MaterialsListView())),
        MenuItem(icon: "wrench", label: "Equipment", color: .indigo, destination: AnyView(EquipmentListView())),
        MenuItem(icon: "person.3", label: "Meetings", color: .pink, destination: AnyView(MeetingsListView())),
        MenuItem(icon: "clock", label: "Timesheets", color: .brown, destination: AnyView(TimesheetsListView())),
        MenuItem(icon: "document.text", label: "Permits", color: .mint, destination: AnyView(PermitsListView())),
        MenuItem(icon: "warning", label: "Defects", color: .orange, destination: AnyView(DefectsListView())),
        MenuItem(icon: "person.2", label: "Team", color: .teal, destination: AnyView(TeamView())),
        MenuItem(icon: "chart.bar", label: "Reports", color: .gray, destination: AnyView(ReportsView())),
        MenuItem(icon: "doc.text", label: "Daily Reports", color: .blue, destination: AnyView(DailyReportsListView())),
        MenuItem(icon: "gear", label: "Settings", color: .gray, destination: AnyView(SettingsView())),
    ]

    struct MenuItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let color: Color
        let destination: AnyView
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(menuItems) { item in
                    NavigationLink {
                        item.destination
                    } label: {
                        MenuButton(icon: item.icon, label: item.label, color: item.color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("More")
    }
}

struct MenuButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(BuildTrackColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Bar Components

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

// MARK: - App Lock

enum AppLockController {
    static let biometricEnabledKey = "biometric_auth_enabled"

    static var isBiometricEnabled: Bool {
        UserDefaults.standard.bool(forKey: biometricEnabledKey)
    }

    static var shouldLockOnLaunch: Bool {
        isBiometricEnabled
    }
}

struct AppLockView: View {
    @Binding var isLocked: Bool
    @State private var lastError: String?
    @State private var isAuthenticating = false
    private let service = BiometricAuthService()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: service.biometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(BuildTrackColors.primary)
                .padding(.bottom, 8)

            Text("BuildTrack is locked")
                .font(.title2.weight(.semibold))

            Text("Use \(service.biometricTypeDescription) to unlock.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let lastError {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                Task { await unlock() }
            } label: {
                Label("Unlock", systemImage: "lock.open.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BuildTrackColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .disabled(isAuthenticating)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task { await unlock() }
    }

    private func unlock() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        guard service.isAvailable else {
            UserDefaults.standard.set(false, forKey: AppLockController.biometricEnabledKey)
            isLocked = false
            return
        }

        do {
            let success = try await service.authenticate(reason: "Unlock BuildTrack")
            if success {
                lastError = nil
                isLocked = false
            }
        } catch let error as BiometricAuthError {
            lastError = error.errorDescription
        } catch {
            lastError = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .modelContainer(for: [Project.self, TaskItem.self])
}
