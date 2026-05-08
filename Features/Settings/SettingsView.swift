import SwiftUI
import SwiftData

// MARK: - Settings / Profile View

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: Profile Section
                Section {
                    ProfileHeader(authManager: authManager)
                }
                
                // MARK: Account Actions
                Section("Account") {
                    NavigationLink {
                        AccountDetailView(authManager: authManager)
                    } label: {
                        Label("Account Information", systemImage: "person.circle")
                    }
                    
                    NavigationLink {
                        SecuritySettingsView(authManager: authManager)
                    } label: {
                        Label("Security", systemImage: "lock.shield")
                    }
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell.badge")
                    }
                }
                
                // MARK: App Settings
                Section("App Preferences") {
                    Toggle("Dark Mode", systemImage: "moon.fill", isOn: $viewModel.isDarkMode)
                        .tint(BuildTrackColors.primary)
                    
                    Toggle("Sync on Wi-Fi Only", systemImage: "wifi", isOn: $viewModel.wifiOnlySync)
                        .tint(BuildTrackColors.primary)
                    
                    Toggle("Offline Mode", systemImage: "cloud.slash.fill", isOn: $viewModel.offlineMode)
                        .tint(BuildTrackColors.primary)
                    
                    Button {
                        viewModel.triggerSync()
                    } label: {
                        Label(viewModel.isSyncing ? "Syncing…" : "Sync Now", systemImage: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    }
                    .disabled(viewModel.isSyncing)
                }
                
                // MARK: Data Management
                Section("Data") {
                    Button(role: .destructive) {
                        viewModel.showingClearDataConfirmation = true
                    } label: {
                        Label("Clear Local Cache", systemImage: "trash")
                    }
                    
                    Button {
                        viewModel.showingExportConfirmation = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                // MARK: Support
                Section("Support") {
                    NavigationLink {
                        HelpView()
                    } label: {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About BuildTrack", systemImage: "info.circle")
                    }
                }
                
                // MARK: Sign Out
                Section {
                    Button(role: .destructive) {
                        viewModel.showingSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
                
                // MARK: Version
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(viewModel.versionString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("© 2026 BuildTrack. All rights reserved.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
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
            .sheet(isPresented: $viewModel.showingExportConfirmation) {
                ExportDataView()
            }
        }
    }
}

// MARK: - Profile Header

struct ProfileHeader: View {
    @Bindable var authManager: AuthManager
    
    var initials: String {
        guard let user = authManager.currentUser else { return "?" }
        let name = user.fullName ?? user.email
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    var displayName: String {
        guard let user = authManager.currentUser else { return "Guest" }
        return user.fullName ?? user.email
    }
    
    var displayEmail: String {
        authManager.currentUser?.email ?? ""
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(BuildTrackColors.primary.opacity(0.15))
                    .frame(width: 64, height: 64)
                Text(initials)
                    .font(.title2.bold())
                    .foregroundStyle(BuildTrackColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                Text(displayEmail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Account Detail View

struct AccountDetailView: View {
    @Bindable var authManager: AuthManager
    
    var body: some View {
        List {
            Section("Profile") {
                LabeledContent("Name", value: fullName)
                LabeledContent("Email", value: authManager.currentUser?.email ?? "—")
                LabeledContent("User ID", value: authManager.currentUser?.id ?? "—")
            }
            
            Section("Session") {
                LabeledContent("Status", value: authManager.isAuthenticated ? "Active" : "Expired")
                LabeledContent("Device", value: UIDevice.current.name)
                LabeledContent("System", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
            }
        }
        .navigationTitle("Account")
    }
    
    var fullName: String {
        guard let user = authManager.currentUser else { return "—" }
        return user.fullName ?? user.email
    }
}

// MARK: - Security Settings

struct SecuritySettingsView: View {
    @Bindable var authManager: AuthManager
    @State private var showChangePassword = false
    @State private var enableBiometric = false
    @State private var showDeleteAccountConfirmation = false
    
    var body: some View {
        List {
            Section {
                Toggle("Face ID / Touch ID", isOn: $enableBiometric)
                    .tint(BuildTrackColors.primary)
                
                Button {
                    showChangePassword = true
                } label: {
                    Label("Change Password", systemImage: "key.fill")
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "person.crop.circle.badge.xmark")
                }
            } footer: {
                Text("Deleting your account will permanently remove all your data from BuildTrack.")
            }
        }
        .navigationTitle("Security")
        .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. All projects, tasks, and data will be permanently deleted.")
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                HelpItem(icon: "building.2.fill", title: "Creating a Project", description: "Tap the + button on the Projects tab to add a new construction project with budget, timeline, and location.")
                HelpItem(icon: "checklist", title: "Managing Tasks", description: "Add tasks to projects, set priorities, assign workers, and track completion status.")
                HelpItem(icon: "shield.fill", title: "Safety Reporting", description: "Report incidents and schedule inspections. Set severity levels and track resolution.")
            }
            
            Section("Sync & Offline") {
                HelpItem(icon: "arrow.triangle.2.circlepath", title: "Data Sync", description: "BuildTrack syncs automatically with the cloud. Enable 'Wi-Fi Only' to save mobile data.")
                HelpItem(icon: "cloud.slash.fill", title: "Offline Mode", description: "All changes are saved locally and will sync when you're back online.")
            }
            
            Section("Support") {
                Link(destination: URL(string: "https://buildtrack.stancainvest.ro/support")!) {
                    Label("Support Centre", systemImage: "lifepreserver")
                }
                Link(destination: URL(string: "mailto:support@buildtrack.stancainvest.ro")!) {
                    Label("Email Support", systemImage: "envelope.fill")
                }
            }
        }
        .navigationTitle("Help")
    }
}

struct HelpItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 36, height: 36)
                .background(BuildTrackColors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(BuildTrackColors.primary)
                    
                    Text("BuildTrack")
                        .font(.largeTitle.bold())
                    Text("Construction Management")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            
            Section("About") {
                Text("BuildTrack is a construction project management platform built for modern building teams. Track projects, manage tasks, ensure safety compliance, and keep your team connected — all from one native iOS app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section("Credits") {
                LabeledContent("Backend", value: "Supabase")
                LabeledContent("Maps", value: "MapKit")
                LabeledContent("Storage", value: "SwiftData")
                LabeledContent("Realtime", value: "Supabase Realtime")
            }
            
            Section("Legal") {
                Link(destination: URL(string: "https://buildtrack.stancainvest.ro/privacy")!) {
                    Label("Privacy Policy", systemImage: "doc.text")
                }
                Link(destination: URL(string: "https://buildtrack.stancainvest.ro/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
            }
        }
        .navigationTitle("About")
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Your data can be exported as JSON for backup or migration purposes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button("Export All Data") {}
                    Button("Export Projects Only") {}
                    Button("Export Tasks Only") {}
                }
            }
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

// MARK: - View Model

@MainActor
@Observable
final class SettingsViewModel {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("wifiOnlySync") var wifiOnlySync = true
    @AppStorage("offlineMode") var offlineMode = false
    
    var isSyncing = false
    var showingSignOutConfirmation = false
    var showingClearDataConfirmation = false
    var showingExportConfirmation = false
    
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
        // Placeholder — in production, clear SwiftData context
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
    }
}

#Preview {
    SettingsView()
        .environment(AuthManager())
}
