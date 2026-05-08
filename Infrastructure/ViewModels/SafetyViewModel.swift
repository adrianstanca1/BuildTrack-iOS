import SwiftUI
import SwiftData
import OSLog

@Observable
final class SafetyViewModel {
    var incidents: [Incident] = []
    var inspections: [Inspection] = []
    var isLoading = false
    var error: String?
    
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
        }
        isLoading = false
    }
    
    func createIncident(_ incident: Incident) {
        modelContext.insert(incident)
        do {
            try modelContext.save()
            incidents.insert(incident, at: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func createInspection(_ inspection: Inspection) {
        modelContext.insert(inspection)
        do {
            try modelContext.save()
            inspections.insert(inspection, at: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func resolveIncident(_ incident: Incident) {
        incident.status = .resolved
        do {
            try modelContext.save()
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
