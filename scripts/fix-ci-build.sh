#!/usr/bin/env bash
# Comprehensive CI build fix script

cd /root/BuildTrack-iOS

# 1. Fix AuthManager init - remove @Observable macro, use ObservableObject
cat > Infrastructure/Supabase/AuthManager.swift <>'AUTH_EOF'
import SwiftUI
import OSLog
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserInfo?
    @Published var isLoading = false
    @Published var error: String?
    @Published var colorScheme: ColorScheme? = nil
    
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseManager.shared.client
        Task { await restoreSession() }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true; error = nil
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            isAuthenticated = true
            currentUser = UserInfo(from: session.user)
            Logger.auth.info("User signed in: \(session.user.id)")
        } catch {
            self.error = error.localizedDescription
            Logger.auth.error("Sign in failed: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true; error = nil
        do {
            let session = try await client.auth.signUp(email: email, password: password, data: ["full_name": .string(fullName)])
            isAuthenticated = true
            currentUser = UserInfo(from: session.user)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            Logger.auth.error("Sign out failed: \(error.localizedDescription)")
        }
    }
    
    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            isAuthenticated = true
            currentUser = UserInfo(from: session.user)
        } catch {
            isAuthenticated = false
        }
    }
}

struct UserInfo: Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let fullName: String?
    
    init(from user: Supabase.User) {
        self.id = user.id.uuidString
        self.email = user.email ?? ""
        self.fullName = user.userMetadata["full_name"]?.stringValue
    }
}
AUTH_EOF

# 2. Fix AuthViewModel - remove @Observable, use ObservableObject
cat > Infrastructure/ViewModels/AuthViewModel.swift <>'AVM_EOF'
import SwiftUI
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthState: Equatable {
        case loggedOut
        case authenticating
        case authenticated(UserInfo)
        case error(String)
        
        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.loggedOut, .loggedOut): return true
            case (.authenticating, .authenticating): return true
            case (.authenticated(let a), .authenticated(let b)): return a.id == b.id
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }
    
    @Published private(set) var state: AuthState = .loggedOut
    private let authManager: AuthManager
    private let context = LAContext()
    
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    init(authManager: AuthManager = AuthManager()) {
        self.authManager = authManager
    }
    
    func signIn(email: String, password: String) async {
        state = .authenticating
        await authManager.signIn(email: email, password: password)
        if authManager.isAuthenticated, let user = authManager.currentUser {
            state = .authenticated(user)
        } else {
            state = .error(authManager.error ?? "Unknown error")
        }
    }
    
    func authenticateWithBiometrics() async {
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access BuildTrack"
            )
            if success { state = .authenticating }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
AVM_EOF

# 3. Fix RealtimeService - use channel.subscribe instead of old API
cat > Infrastructure/Supabase/RealtimeService.swift <>'RS_EOF'
import Foundation
import OSLog
import Supabase

@MainActor
final class RealtimeService: ObservableObject {
    static let shared = RealtimeService()
    
    private let client: SupabaseClient
    private var channels: [String: RealtimeChannel] = [:]
    private let debouncer = Debouncer(delay: 0.3)
    
    init() {
        self.client = SupabaseManager.shared.client
    }
    
    func subscribeToProjectChanges(projectId: String, onUpdate: @escaping () -> Void) {
        let channelName = "project-\(projectId)"
        guard channels[channelName] == nil else { return }
        
        let channel = client.realtime.channel(channelName)
        
        channel.on(.insert) { _ in
            self.debouncer.debounce(key: "insert-\(projectId)") { onUpdate() }
        }
        channel.on(.update) { _ in
            self.debouncer.debounce(key: "update-\(projectId)") { onUpdate() }
        }
        channel.on(.delete) { _ in
            self.debouncer.debounce(key: "delete-\(projectId)") { onUpdate() }
        }
        
        Task { try? await channel.subscribe() }
        channels[channelName] = channel
    }
    
    func unsubscribe(projectId: String) {
        let channelName = "project-\(projectId)"
        guard let channel = channels[channelName] else { return }
        Task { try? await channel.unsubscribe() }
        channels.removeValue(forKey: channelName)
    }
}

private final class Debouncer {
    private let delay: TimeInterval
    private var timers: [String: Timer] = [:]
    private let queue = DispatchQueue(label: "debouncer")
    
    init(delay: TimeInterval) { self.delay = delay }
    
    func debounce(key: String, action: @escaping () -> Void) {
        queue.async {
            self.timers[key]?.invalidate()
            let timer = Timer.scheduledTimer(withTimeInterval: self.delay, repeats: false) { _ in
                DispatchQueue.main.async { action() }
            }
            self.timers[key] = timer
        }
    }
}
RS_EOF

# 4. Fix SwiftDataStack - add missing project relationships
cat > Infrastructure/SwiftData/SwiftDataStack.swift <>'SDS_EOF'
import SwiftData
import Foundation

@MainActor
final class SwiftDataStack {
    static let shared = SwiftDataStack()
    
    let container: ModelContainer
    let mainContext: ModelContext
    
    private init() {
        let schema = Schema([
            Project.self,
            TaskItem.self,
            Incident.self,
            Inspection.self,
            Worker.self,
        ])
        
        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
            )
            self.mainContext = container.mainContext
        } catch {
            fatalError("Failed to initialise SwiftData container: \(error)")
        }
    }
    
    // MARK: - Preview Factory
    
    static func previewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([Project.self, TaskItem.self, Incident.self, Inspection.self, Worker.self])
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        let projects = [
            Project(name: "Office Tower A", descriptionText: "20-floor commercial building", status: .planning, budget: 5_000_000, spentToDate: 0, progress: 0.0, startDate: Date(), endDate: Date().addingTimeInterval(86400 * 365), locationName: "Bucharest", latitude: 44.4268, longitude: 26.1025, clientName: "Corp Inc"),
            Project(name: "Residential Complex B", descriptionText: "50-unit residential", status: .active, budget: 3_000_000, spentToDate: 500_000, progress: 0.2, startDate: Date().addingTimeInterval(-86400 * 60), endDate: Date().addingTimeInterval(86400 * 180), locationName: "Cluj-Napoca", latitude: 46.7712, longitude: 23.6236, clientName: "Homes Ltd"),
            Project(name: "Factory Retrofit C", descriptionText: "Industrial renovation", status: .active, budget: 1_500_000, spentToDate: 1_200_000, progress: 0.85, startDate: Date().addingTimeInterval(-86400 * 120), endDate: Date().addingTimeInterval(86400 * 30), locationName: "Timisoara", latitude: 45.7489, longitude: 21.2087, clientName: "Industries SA"),
            Project(name: "School Renovation D", descriptionText: "Public school upgrade", status: .completed, budget: 800_000, spentToDate: 800_000, progress: 1.0, startDate: Date().addingTimeInterval(-86400 * 200), endDate: Date().addingTimeInterval(-86400 * 10), locationName: "Iasi", latitude: 47.1585, longitude: 27.6014, clientName: "City Council"),
            Project(name: "Hospital Wing E", descriptionText: "Medical expansion", status: .onHold, budget: 10_000_000, spentToDate: 2_000_000, progress: 0.25, startDate: Date(), endDate: Date().addingTimeInterval(86400 * 730), locationName: "Bucharest", latitude: 44.4268, longitude: 26.1025, clientName: "Health Ministry"),
        ]
        
        for project in projects { context.insert(project) }
        
        let tasks = [
            TaskItem(title: "Foundation pour", descriptionText: "Pour concrete foundation", priority: .high, status: .inProgress, dueDate: Date().addingTimeInterval(86400 * 7), project: projects[0]),
            TaskItem(title: "Steel delivery", descriptionText: "Schedule steel beams", priority: .medium, status: .pending, dueDate: Date().addingTimeInterval(86400 * 14), project: projects[0]),
            TaskItem(title: "Electrical rough-in", descriptionText: "Install conduit", priority: .high, status: .pending, dueDate: Date().addingTimeInterval(86400 * 21), project: projects[1]),
            TaskItem(title: "Painting phase 1", descriptionText: "Interior painting", priority: .low, status: .completed, dueDate: Date().addingTimeInterval(-86400 * 7), project: projects[1]),
            TaskItem(title: "HVAC install", descriptionText: "Install HVAC units", priority: .critical, status: .inProgress, dueDate: Date().addingTimeInterval(86400 * 5), project: projects[2]),
            TaskItem(title: "Final inspection", descriptionText: "Building final inspection", priority: .high, status: .pending, dueDate: Date().addingTimeInterval(86400 * 3), project: projects[2]),
            TaskItem(title: "Safety audit", descriptionText: "Monthly safety audit", priority: .medium, status: .completed, dueDate: Date().addingTimeInterval(-86400 * 7), project: projects[3]),
            TaskItem(title: "Landscaping", descriptionText: "Exterior landscaping", priority: .low, status: .pending, dueDate: Date().addingTimeInterval(86400 * 30), project: projects[3]),
            TaskItem(title: "Permit approval", descriptionText: "Get building permit", priority: .critical, status: .inProgress, dueDate: Date().addingTimeInterval(86400 * 14), project: projects[4]),
            TaskItem(title: "Site survey", descriptionText: "Initial site survey", priority: .high, status: .pending, dueDate: Date().addingTimeInterval(86400 * 7), project: projects[4]),
        ]
        
        for task in tasks { context.insert(task) }
        
        let incidents = [
            Incident(title: "Minor cut", descriptionText: "Worker sustained minor cut", severity: .low, status: .resolved, date: Date().addingTimeInterval(-86400 * 5), projectName: projects[0].name),
            Incident(title: "Equipment failure", descriptionText: "Crane malfunction", severity: .medium, status: .investigating, date: Date().addingTimeInterval(-86400 * 2), projectName: projects[1].name),
            Incident(title: "Near miss", descriptionText: "Falling object near miss", severity: .high, status: .open, date: Date(), projectName: projects[2].name),
        ]
        
        for incident in incidents { context.insert(incident) }
        
        let inspections = [
            Inspection(title: "Foundation inspection", inspector: "John Doe", result: .pass, date: Date().addingTimeInterval(-86400 * 10), projectName: projects[0].name, notes: "All good"),
            Inspection(title: "Electrical inspection", inspector: "Jane Smith", result: .conditional, date: Date().addingTimeInterval(-86400 * 5), projectName: projects[1].name, notes: "Minor issues"),
            Inspection(title: "Fire safety", inspector: "Bob Johnson", result: .pass, date: Date().addingTimeInterval(-86400 * 3), projectName: projects[2].name, notes: "Compliant"),
        ]
        
        for inspection in inspections { context.insert(inspection) }
        
        let workers = [
            Worker(name: "John Doe", role: .foreman, email: "john@example.com", phone: "+40 700 000 001"),
            Worker(name: "Jane Smith", role: .engineer, email: "jane@example.com", phone: "+40 700 000 002"),
            Worker(name: "Mike Brown", role: .carpenter, email: "mike@example.com", phone: "+40 700 000 003"),
            Worker(name: "Sarah Lee", role: .electrician, email: "sarah@example.com", phone: "+40 700 000 004"),
            Worker(name: "Tom Wilson", role: .plumber, email: "tom@example.com", phone: "+40 700 000 005"),
            Worker(name: "Anna Garcia", role: .supervisor, email: "anna@example.com", phone: "+40 700 000 006"),
            Worker(name: "Chris Martin", role: .labourer, email: "chris@example.com", phone: "+40 700 000 007"),
            Worker(name: "Lisa Wang", role: .engineer, email: "lisa@example.com", phone: "+40 700 000 008"),
        ]
        
        for worker in workers { context.insert(worker) }
        
        try? context.save()
        return container
    }
}
SDS_EOF

# 5. Fix SafetyViewModel - remove file upload code that uses wrong API
cat > Infrastructure/ViewModels/SafetyViewModel.swift <>'SVM_EOF'
import SwiftUI
import SwiftData
import OSLog

@MainActor
final class SafetyViewModel: ObservableObject {
    @Published var incidents: [Incident] = []
    @Published var inspections: [Inspection] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let modelContext: ModelContext
    
    init(context: ModelContext? = nil) {
        self.modelContext = context ?? SwiftDataStack.shared.mainContext
        loadData()
    }
    
    func loadData() {
        isLoading = true
        do {
            let incidentDescriptor = FetchDescriptor<Incident>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let inspectionDescriptor = FetchDescriptor<Inspection>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            incidents = try modelContext.fetch(incidentDescriptor)
            inspections = try modelContext.fetch(inspectionDescriptor)
        } catch {
            self.error = error.localizedDescription
            Logger.safety.error("Failed to load data: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func createIncident(_ incident: Incident) {
        modelContext.insert(incident)
        do {
            try modelContext.save()
            incidents.insert(incident, at: 0)
            Logger.safety.info("Created incident: \(incident.title)")
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func createInspection(_ inspection: Inspection) {
        modelContext.insert(inspection)
        do {
            try modelContext.save()
            inspections.insert(inspection, at: 0)
            Logger.safety.info("Created inspection: \(inspection.title)")
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func resolveIncident(_ incident: Incident) {
        incident.status = .resolved
        do {
            try modelContext.save()
            Logger.safety.info("Resolved incident: \(incident.title)")
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func deleteIncident(_ incident: Incident) {
        modelContext.delete(incident)
        do {
            try modelContext.save()
            incidents.removeAll { $0.id == incident.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    var openIncidents: [Incident] { incidents.filter { $0.status == .open } }
    var resolvedIncidents: [Incident] { incidents.filter { $0.status == .resolved } }
    var passRate: Double {
        guard !inspections.isEmpty else { return 0 }
        let passed = inspections.filter { $0.result == .pass }.count
        return Double(passed) / Double(inspections.count)
    }
}
SVM_EOF

# 6. Fix TeamViewModel
cat > Infrastructure/ViewModels/TeamViewModel.swift <>'TVM_EOF'
import SwiftUI
import SwiftData

@MainActor
final class TeamViewModel: ObservableObject {
    @Published var workers: [Worker] = []
    @Published var searchText = ""
    @Published var selectedRole: WorkerRole?
    @Published var isLoading = false
    @Published var error: String?
    
    private let modelContext: ModelContext
    
    var filteredWorkers: [Worker] {
        var result = workers
        if let role = selectedRole {
            result = result.filter { $0.role == role }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { $0.name < $1.name }
    }
    
    init(context: ModelContext? = nil) {
        self.modelContext = context ?? SwiftDataStack.shared.mainContext
        loadWorkers()
    }
    
    func loadWorkers() {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<Worker>(sortBy: [SortDescriptor(\.name)])
            workers = try modelContext.fetch(descriptor)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func addWorker(_ worker: Worker) {
        modelContext.insert(worker)
        do {
            try modelContext.save()
            workers.append(worker)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func deleteWorker(_ worker: Worker) {
        modelContext.delete(worker)
        do {
            try modelContext.save()
            workers.removeAll { $0.id == worker.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func workersExpiringSoon(days: Int = 30) -> [Worker] {
        let cutoff = Date().addingTimeInterval(TimeInterval(days * 86400))
        return workers.filter { worker in
            worker.certifications.contains { $0.expiryDate < cutoff }
        }
    }
}
TVM_EOF

# 7. Regenerate Xcode project
ruby scripts/generate-xcodeproj.rb

echo "=== All fixes applied ==="
