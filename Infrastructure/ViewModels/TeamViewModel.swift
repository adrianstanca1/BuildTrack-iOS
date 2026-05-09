import SwiftUI
import SwiftData

@Observable
final class TeamViewModel {
    var workers: [Worker] = []
    var searchText = ""
    var selectedRole: WorkerRole?
    var isLoading = false
    var error: String?
    
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
        return result.sorted(using: KeyPathComparator(\.name))
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
        var result = [Worker]()
        for worker in workers {
            for cert in worker.certifications {
                if cert.expiryDate < cutoff {
                    result.append(worker)
                    break
                }
            }
        }
        return result
    }
}
