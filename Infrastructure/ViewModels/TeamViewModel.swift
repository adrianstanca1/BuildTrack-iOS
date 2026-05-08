import SwiftUI
import SwiftData

@MainActor
@Observable
final class TeamViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Worker])
        case error(String)
    }
    
    private(set) var state: State = .idle
    private let modelContext: ModelContext?
    
    init() {
        let container = try? ModelContainer(for: Worker.self)
        self.modelContext = container?.mainContext
    }
    
    func loadWorkers() {
        state = .loading
        guard let context = modelContext else {
            state = .loaded([])
            return
        }
        
        do {
            let descriptor = FetchDescriptor<Worker>(sortBy: [SortDescriptor(\.name)])
            let workers = try context.fetch(descriptor)
            state = .loaded(workers)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    var roleBreakdown: [(WorkerRole, Int)] {
        WorkerRole.allCases.compactMap { role in
            guard case .loaded(let workers) = state else { return nil }
            let count = workers.filter { $0.role == role && $0.isActive }.count
            return count > 0 ? (role, count) : nil
        }.sorted { $0.1 > $1.1 }
    }
    
    var activeWorkers: [Worker] {
        guard case .loaded(let workers) = state else { return [] }
        return workers.filter { $0.isActive }
    }
    
    var inactiveWorkers: [Worker] {
        guard case .loaded(let workers) = state else { return [] }
        return workers.filter { !$0.isActive }
    }
    
    func expiringCertifications(withinDays days: Int = 30) -> [(worker: Worker, cert: String, expires: Date)] {
        guard case .loaded(let workers) = state else { return [] }
        let cutoff = Date().addingTimeInterval(Double(days) * 86400)
        
        var result: [(Worker, String, Date)] = []
        for worker in workers where worker.isActive {
            for cert in worker.certifications {
                // Parse date from cert string if it contains one, otherwise skip
                if let dateStr = cert.split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                   let date = ISO8601DateFormatter().date(from: String(dateStr)),
                   date <= cutoff {
                    result.append((worker, cert, date))
                }
            }
        }
        return result.sorted { $0.expires < $1.expires }
    }
    
    func searchWorkers(query: String) -> [Worker] {
        guard !query.isEmpty else { return activeWorkers }
        return activeWorkers.filter {
            $0.name.localizedCaseInsensitiveContains(query)
            || $0.role.label.localizedCaseInsensitiveContains(query)
            || $0.certifications.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func addWorker(name: String, role: WorkerRole = .labourer, phone: String = "", email: String = "", certifications: [String] = []) {
        let worker = Worker(name: name, role: role, phone: phone, email: email, certifications: certifications)
        modelContext?.insert(worker)
        try? modelContext?.save()
        loadWorkers()
    }
    
    func updateWorker(_ worker: Worker, name: String, role: WorkerRole, phone: String, email: String, certifications: [String]) {
        worker.name = name
        worker.role = role
        worker.phone = phone
        worker.email = email
        worker.certifications = certifications
        try? modelContext?.save()
        loadWorkers()
    }
    
    func deactivateWorker(_ worker: Worker) {
        worker.isActive = false
        try? modelContext?.save()
        loadWorkers()
    }
    
    func reactivateWorker(_ worker: Worker) {
        worker.isActive = true
        try? modelContext?.save()
        loadWorkers()
    }
    
    func deleteWorker(_ worker: Worker) {
        modelContext?.delete(worker)
        try? modelContext?.save()
        loadWorkers()
    }
}
