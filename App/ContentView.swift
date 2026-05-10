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
            // Re-lock when the app returns to foreground after being backgrounded.
            if newPhase == .active, AppLockController.isBiometricEnabled, !isLocked {
                // Already active; only re-lock if explicitly transitioning from background.
            }
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
        // Defer until unlocked / authenticated; otherwise stash for when MainTabView mounts.
        guard authManager.isAuthenticated, !isLocked else {
            deepLink = screen
            return
        }
        selectedTab = ContentView.router.tabFor(screen)
        deepLink = screen
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
            // Biometric was enabled but no longer available (e.g. removed enrolment).
            // Fail open rather than locking the user out of their own data.
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

// MARK: - Modern Tab Bar

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var deepLink: DeepLinkRouter.Screen?
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
