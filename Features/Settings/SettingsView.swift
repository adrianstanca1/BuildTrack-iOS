import SwiftUI
import SwiftData
import LocalAuthentication

// MARK: - Professional Settings View

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    @State private var selectedSection: SettingsSection?
    
    enum SettingsSection: String, Identifiable {
        case account, security, notifications, help, about, export
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Profile Header
                    profileHeader
                        .fadeIn(delay: 0)
                    
                    // Quick Stats
                    settingsStats
                        .fadeIn(delay: 0.1)
                    
                    // Settings Sections
                    LazyVStack(spacing: DesignTokens.Spacing.md) {
                        settingsSection(title: "Account", icon: "person.crop.circle.fill", color: BuildTrackColors.primary) {
                            settingsRow(icon: "person.text.rectangle", title: "Account Information", subtitle: "Name, email, user ID") {
                                selectedSection = .account
                            }
                            settingsRow(icon: "lock.shield", title: "Security", subtitle: "Password, biometric, 2FA") {
                                selectedSection = .security
                            }
                            settingsRow(icon: "bell.badge", title: "Notifications", subtitle: "Push, email, in-app alerts") {
                                selectedSection = .notifications
                            }
                        }
                        .fadeIn(delay: 0.15)
                        
                        settingsSection(title: "App Preferences", icon: "gear", color: BuildTrackColors.info) {
                            ToggleRow(icon: "moon.fill", title: "Dark Mode", isOn: $viewModel.isDarkMode)
                            ToggleRow(icon: "wifi", title: "Sync on Wi-Fi Only", isOn: $viewModel.wifiOnlySync)
                            ToggleRow(icon: "cloud.slash.fill", title: "Offline Mode", isOn: $viewModel.offlineMode)
                            
                            Button {
                                DesignTokens.Haptic.medium()
                                viewModel.triggerSync()
                            } label: {
                                HStack {
                                    Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                                        .font(.system(size: 18))
                                        .foregroundStyle(BuildTrackColors.primary)
                                        .frame(width: 32, height: 32)
                                        .background(BuildTrackColors.primary.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(viewModel.isSyncing ? "Syncing..." : "Sync Now")
                                            .font(DesignTokens.Typography.callout.weight(.medium))
                                            .foregroundStyle(BuildTrackColors.textPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.isSyncing {
                                        ProgressView()
                                            .tint(BuildTrackColors.primary)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(BuildTrackColors.textTertiary)
                                    }
                                }
                            }
                            .disabled(viewModel.isSyncing)
                            .frame(minHeight: DesignTokens.Spacing.listRowHeight)
                        }
                        .fadeIn(delay: 0.2)
                        
                        settingsSection(title: "Data Management", icon: "externaldrive.fill", color: BuildTrackColors.warning) {
                            settingsRow(icon: "square.and.arrow.up", title: "Export Data", subtitle: "JSON backup of all projects and tasks") {
                                DesignTokens.Haptic.medium()
                                selectedSection = .export
                            }
                            
                            Button {
                                DesignTokens.Haptic.medium()
                                viewModel.showingClearDataConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                        .foregroundStyle(BuildTrackColors.danger)
                                        .frame(width: 32, height: 32)
                                        .background(BuildTrackColors.danger.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("Clear Local Cache")
                                        .font(DesignTokens.Typography.callout.weight(.medium))
                                        .foregroundStyle(BuildTrackColors.danger)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BuildTrackColors.textTertiary)
                                }
                            }
                            .frame(minHeight: DesignTokens.Spacing.listRowHeight)
                        }
                        .fadeIn(delay: 0.25)
                        
                        settingsSection(title: "Support", icon: "questionmark.circle.fill", color: BuildTrackColors.success) {
                            settingsRow(icon: "questionmark.circle", title: "Help & FAQ", subtitle: "Getting started, sync, troubleshooting") {
                                selectedSection = .help
                            }
                            settingsRow(icon: "info.circle", title: "About BuildTrack", subtitle: "Version, credits, legal") {
                                selectedSection = .about
                            }
                        }
                        .fadeIn(delay: 0.3)
                        
                        // Sign Out
                        Button {
                            DesignTokens.Haptic.heavy()
                            viewModel.showingSignOutConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                    .foregroundStyle(BuildTrackColors.danger)
                                    .frame(width: 32, height: 32)
                                    .background(BuildTrackColors.danger.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Text("Sign Out")
                                    .font(DesignTokens.Typography.callout.weight(.medium))
                                    .foregroundStyle(BuildTrackColors.danger)
                                
                                Spacer()
                            }
                        }
                        .frame(minHeight: DesignTokens.Spacing.listRowHeight)
                        .professionalCard(padding: DesignTokens.Spacing.cardPadding)
                        .fadeIn(delay: 0.35)
                        
                        // Version Footer
                        HStack {
                            Spacer()
                            VStack(spacing: 2) {
                                Text("BuildTrack")
                                    .font(DesignTokens.Typography.caption.weight(.semibold))
                                    .foregroundStyle(BuildTrackColors.textTertiary)
                                Text("Version \(viewModel.versionString)")
                                    .font(.caption2)
                                    .foregroundStyle(BuildTrackColors.textTertiary)
                                Text("© 2026 BuildTrack. All rights reserved.")
                                    .font(.caption2)
                                    .foregroundStyle(BuildTrackColors.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .fadeIn(delay: 0.4)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .padding(.vertical, DesignTokens.Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        DesignTokens.Haptic.light()
                        dismiss()
                    }
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.primary)
                }
            }
            .confirmationDialog("Sign Out?", isPresented: $viewModel.showingSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task { await authManager.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to access your projects.")
            }
            .alert("Clear Local Data?", isPresented: $viewModel.showingClearDataConfirmation) {
                Button("Clear", role: .destructive) {
                    viewModel.clearLocalCache()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all cached projects, tasks, and safety data from this device. Your server data is safe.")
            }
            .sheet(item: $selectedSection) { section in
                switch section {
                case .account:
                    NavigationStack { AccountDetailView(authManager: authManager) }
                case .security:
                    NavigationStack { SecuritySettingsView(authManager: authManager) }
                case .notifications:
                    NavigationStack { NotificationSettingsView() }
                case .help:
                    NavigationStack { HelpView() }
                case .about:
                    NavigationStack { AboutView() }
                case .export:
                    ExportDataView()
                }
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BuildTrackColors.primary, BuildTrackColors.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: BuildTrackColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text(initials)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(displayName)
                    .font(DesignTokens.Typography.title3)
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                Text(displayEmail)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(BuildTrackColors.textSecondary)
                
                ProBadge(text: authManager.isAuthenticated ? "Active" : "Guest", color: authManager.isAuthenticated ? .green : .gray)
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            LinearGradient(
                colors: [BuildTrackColors.primary.opacity(0.08), BuildTrackColors.primary.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(BuildTrackColors.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Settings Stats
    private var settingsStats: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            StatMiniCard(
                icon: "building.2.fill",
                value: "12",
                label: "Projects",
                color: BuildTrackColors.primary
            )
            StatMiniCard(
                icon: "checklist",
                value: "48",
                label: "Tasks",
                color: BuildTrackColors.info
            )
            StatMiniCard(
                icon: "shield.fill",
                value: "3",
                label: "Incidents",
                color: BuildTrackColors.warning
            )
        }
    }
    
    // MARK: - Settings Section
    private func settingsSection(title: String, icon: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textSecondary)
                    .textCase(.uppercase)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .professionalCard(padding: DesignTokens.Spacing.sm)
        }
    }
    
    // MARK: - Settings Row
    private func settingsRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(BuildTrackColors.primary)
                    .frame(width: 32, height: 32)
                    .background(BuildTrackColors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.callout.weight(.medium))
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: DesignTokens.Spacing.listRowHeight)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
    
    // MARK: - Computed Properties
    private var initials: String {
        guard let user = authManager.currentUser else { return "?" }
        let name = user.fullName ?? user.email
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private var displayName: String {
        guard let user = authManager.currentUser else { return "Guest" }
        return user.fullName ?? user.email
    }
    
    private var displayEmail: String {
        authManager.currentUser?.email ?? ""
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 32, height: 32)
                .background(BuildTrackColors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(DesignTokens.Typography.callout.weight(.medium))
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(BuildTrackColors.primary)
                .labelsHidden()
        }
        .frame(minHeight: DesignTokens.Spacing.listRowHeight)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

// MARK: - Supporting Views (Updated with Pro Design)

struct AccountDetailView: View {
    @Bindable var authManager: AuthManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Profile Card
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(BuildTrackColors.primary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Text(fullName.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(BuildTrackColors.primary)
                    }
                    
                    Text(fullName)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    Text(authManager.currentUser?.email ?? "—")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                }
                .padding(DesignTokens.Spacing.lg)
                .professionalCard()
                
                // Details
                VStack(spacing: 0) {
                    DetailRowPro(label: "User ID", value: authManager.currentUser?.id ?? "—", icon: "number")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Status", value: authManager.isAuthenticated ? "Active" : "Expired", icon: "checkmark.shield")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Device", value: UIDevice.current.name, icon: "iphone")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "System", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)", icon: "gear")
                }
                .professionalCard(padding: 0)
            }
            .padding(DesignTokens.Spacing.sectionPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Account")
    }
    
    var fullName: String {
        guard let user = authManager.currentUser else { return "—" }
        return user.fullName ?? user.email
    }
}

struct DetailRowPro: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 32, height: 32)
                .background(BuildTrackColors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(BuildTrackColors.textSecondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(DesignTokens.Typography.callout.weight(.medium))
                    .foregroundStyle(BuildTrackColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct SecuritySettingsView: View {
    @Bindable var authManager: AuthManager
    @State private var showChangePassword = false
    @State private var enableBiometric = UserDefaults.standard.bool(forKey: AppLockController.biometricEnabledKey)
    @State private var showDeleteAccountConfirmation = false
    @State private var biometricError: String?

    private var context = LAContext()

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Security Status Card
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(BuildTrackColors.success)
                    
                    Text("Security Status")
                        .font(DesignTokens.Typography.title3)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    ProBadge(text: "Protected", color: .green)
                }
                .padding(DesignTokens.Spacing.lg)
                .professionalCard()
                
                // Settings
                VStack(spacing: 0) {
                    ToggleRow(icon: "faceid", title: "Face ID / Touch ID", isOn: $enableBiometric)
                        .onChange(of: enableBiometric) { _, isOn in
                            if isOn { authenticateBiometric() }
                            else { UserDefaults.standard.set(false, forKey: AppLockController.biometricEnabledKey) }
                        }
                    
                    if let error = biometricError {
                        Text(error)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        DesignTokens.Haptic.medium()
                        showChangePassword = true
                    } label: {
                        settingsRow(icon: "key.fill", title: "Change Password", subtitle: "Update your account password") {
                            showChangePassword = true
                        }
                    }
                }
                .professionalCard(padding: DesignTokens.Spacing.sm)
                
                // Danger Zone
                Button {
                    DesignTokens.Haptic.heavy()
                    showDeleteAccountConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 18))
                            .foregroundStyle(BuildTrackColors.danger)
                            .frame(width: 32, height: 32)
                            .background(BuildTrackColors.danger.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("Delete Account")
                            .font(DesignTokens.Typography.callout.weight(.medium))
                            .foregroundStyle(BuildTrackColors.danger)
                        
                        Spacer()
                    }
                }
                .professionalCard(padding: DesignTokens.Spacing.md)
            }
            .padding(DesignTokens.Spacing.sectionPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Security")
        .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. All projects, tasks, and data will be permanently deleted.")
        }
    }
    
    private func authenticateBiometric() {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricError = error?.localizedDescription ?? "Biometric authentication not available"
            enableBiometric = false
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Secure your BuildTrack account with Face ID or Touch ID"
        ) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    biometricError = nil
                    UserDefaults.standard.set(true, forKey: AppLockController.biometricEnabledKey)
                } else {
                    biometricError = evalError?.localizedDescription
                    enableBiometric = false
                }
            }
        }
    }
    
    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 32, height: 32)
                .background(BuildTrackColors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(DesignTokens.Typography.callout.weight(.medium))
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textTertiary)
        }
        .frame(minHeight: DesignTokens.Spacing.listRowHeight)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(BuildTrackColors.primary)
                    
                    Text("Help & Support")
                        .font(DesignTokens.Typography.title3)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                }
                .padding(DesignTokens.Spacing.lg)
                .professionalCard()
                
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    HelpItemPro(icon: "building.2.fill", title: "Creating a Project", description: "Tap the + button on the Projects tab to add a new construction project with budget, timeline, and location.")
                    HelpItemPro(icon: "checklist", title: "Managing Tasks", description: "Add tasks to projects, set priorities, assign workers, and track completion status.")
                    HelpItemPro(icon: "shield.fill", title: "Safety Reporting", description: "Report incidents and schedule inspections. Set severity levels and track resolution.")
                    HelpItemPro(icon: "arrow.triangle.2.circlepath", title: "Data Sync", description: "BuildTrack syncs automatically with the cloud. Enable 'Wi-Fi Only' to save mobile data.")
                    HelpItemPro(icon: "cloud.slash.fill", title: "Offline Mode", description: "All changes are saved locally and will sync when you're back online.")
                }
                .professionalCard(padding: DesignTokens.Spacing.md)
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Link(destination: URL(string: "https://buildtrack.stancainvest.ro/support")!) {
                        HStack {
                            Image(systemName: "lifepreserver")
                                .font(.system(size: 18))
                                .foregroundStyle(BuildTrackColors.primary)
                            Text("Support Centre")
                                .font(DesignTokens.Typography.callout.weight(.medium))
                                .foregroundStyle(BuildTrackColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BuildTrackColors.textTertiary)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:support@buildtrack.stancainvest.ro")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(BuildTrackColors.primary)
                            Text("Email Support")
                                .font(DesignTokens.Typography.callout.weight(.medium))
                                .foregroundStyle(BuildTrackColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BuildTrackColors.textTertiary)
                        }
                    }
                }
                .professionalCard(padding: DesignTokens.Spacing.md)
            }
            .padding(DesignTokens.Spacing.sectionPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Help")
    }
}

struct HelpItemPro: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 40, height: 40)
                .background(BuildTrackColors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                Text(description)
                    .font(DesignTokens.Typography.footnote)
                    .foregroundStyle(BuildTrackColors.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Hero
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BuildTrackColors.primary, BuildTrackColors.primaryLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("BuildTrack")
                        .font(DesignTokens.Typography.largeTitle)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    Text("Construction Management")
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                    
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
                .padding(DesignTokens.Spacing.xl)
                .professionalCard()
                
                // Description
                Text("BuildTrack is a construction project management platform built for modern building teams. Track projects, manage tasks, ensure safety compliance, and keep your team connected — all from one native iOS app.")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(BuildTrackColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(DesignTokens.Spacing.md)
                
                // Credits
                VStack(spacing: 0) {
                    DetailRowPro(label: "Backend", value: "Supabase", icon: "server.rack")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Maps", value: "MapKit", icon: "map")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Storage", value: "SwiftData", icon: "externaldrive.fill")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Realtime", value: "Supabase Realtime", icon: "bolt.fill")
                }
                .professionalCard(padding: 0)
                
                // Legal
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Link(destination: URL(string: "https://buildtrack.stancainvest.ro/privacy")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(BuildTrackColors.primary)
                            Text("Privacy Policy")
                                .font(DesignTokens.Typography.callout.weight(.medium))
                                .foregroundStyle(BuildTrackColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(BuildTrackColors.textTertiary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://buildtrack.stancainvest.ro/terms")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(BuildTrackColors.primary)
                            Text("Terms of Service")
                                .font(DesignTokens.Typography.callout.weight(.medium))
                                .foregroundStyle(BuildTrackColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(BuildTrackColors.textTertiary)
                        }
                    }
                }
                .professionalCard(padding: DesignTokens.Spacing.md)
            }
            .padding(DesignTokens.Spacing.sectionPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About")
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(BuildTrackColors.primary)
                        
                        Text("Export Data")
                            .font(DesignTokens.Typography.title3)
                            .foregroundStyle(BuildTrackColors.textPrimary)
                        
                        Text("Your data can be exported as JSON for backup or migration purposes.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .professionalCard()
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ExportButton(title: "Export All Data", icon: "archivebox.fill", isExporting: $isExporting)
                        ExportButton(title: "Export Projects Only", icon: "building.2.fill", isExporting: $isExporting)
                        ExportButton(title: "Export Tasks Only", icon: "checklist", isExporting: $isExporting)
                    }
                }
                .padding(DesignTokens.Spacing.sectionPadding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    @Binding var isExporting: Bool
    
    var body: some View {
        Button {
            DesignTokens.Haptic.medium()
            isExporting = true
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { isExporting = false }
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(BuildTrackColors.primary)
                    .frame(width: 32, height: 32)
                    .background(BuildTrackColors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(title)
                    .font(DesignTokens.Typography.callout.weight(.medium))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                Spacer()
                
                if isExporting {
                    ProgressView()
                        .tint(BuildTrackColors.primary)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
            }
        }
        .disabled(isExporting)
        .buttonStyle(.plain)
        .frame(minHeight: DesignTokens.Spacing.listRowHeight)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

// MARK: - View Model

final class SettingsViewModel: ObservableObject {
    nonisolated init() {}
    
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("wifiOnlySync") var wifiOnlySync = true
    @AppStorage("offlineMode") var offlineMode = false
    
    @Published var isSyncing = false
    @Published var showingSignOutConfirmation = false
    @Published var showingClearDataConfirmation = false
    @Published var showingExportConfirmation = false
    
    var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    func triggerSync() {
        isSyncing = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run { isSyncing = false }
        }
    }
    
    func clearLocalCache() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
    }
}

#Preview("Professional Settings") {
    SettingsView()
        .environment(AuthManager())
}
