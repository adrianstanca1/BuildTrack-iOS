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
        populateDemoData(in: context)
        try? context.save()
        return container
    }
    
    // MARK: - Demo Data
    
    static func populateDemoData(in context: ModelContext) {
        let project1 = Project(
            name: "High-rise Tower",
            descriptionText: "45-storey residential tower in downtown area with ground-floor retail and underground parking for 200 vehicles.",
            status: .active,
            budget: 12_500_000,
            spentToDate: 7_200_000,
            progress: 58,
            startDate: Date().addingTimeInterval(-180 * 86400),
            endDate: Date().addingTimeInterval(185 * 86400),
            locationName: "123 Main Street, Downtown",
            latitude: 40.7128,
            longitude: -74.0060,
            clientName: "Metropolitan Development Corp"
        )
        context.insert(project1)
        
        let project2 = Project(
            name: "Riverside Complex",
            descriptionText: "Mixed-use development with 3 residential buildings, a community centre, and riverside promenade.",
            status: .active,
            budget: 8_200_000,
            spentToDate: 3_100_000,
            progress: 38,
            startDate: Date().addingTimeInterval(-90 * 86400),
            endDate: Date().addingTimeInterval(275 * 86400),
            locationName: "456 River Road, Westside",
            latitude: 40.7282,
            longitude: -73.9942,
            clientName: "Riverfront Properties Ltd"
        )
        context.insert(project2)
        
        let project3 = Project(
            name: "Downtown Office Renovation",
            descriptionText: "Complete renovation of 12-storey office building including HVAC upgrade, new elevators, and modern lobby redesign.",
            status: .onHold,
            budget: 4_800_000,
            spentToDate: 2_100_000,
            progress: 44,
            startDate: Date().addingTimeInterval(-60 * 86400),
            endDate: Date().addingTimeInterval(120 * 86400),
            locationName: "789 Business Ave, Financial District",
            latitude: 40.7074,
            longitude: -74.0113,
            clientName: "Pinnacle Business Group"
        )
        context.insert(project3)
        
        let project4 = Project(
            name: "Suburban Housing Development",
            descriptionText: "50-unit single-family home development with community playground, walking paths, and retention pond.",
            status: .planning,
            budget: 15_000_000,
            spentToDate: 500_000,
            progress: 3,
            startDate: Date().addingTimeInterval(-14 * 86400),
            endDate: Date().addingTimeInterval(350 * 86400),
            locationName: "100 Maple Grove, Suburbia",
            latitude: 40.7589,
            longitude: -73.9851,
            clientName: "Greenfield Housing Authority"
        )
        context.insert(project4)
        
        let project5 = Project(
            name: "City Mall Expansion",
            descriptionText: "200,000 sq ft expansion including new anchor store, food court renovation, and 500 additional parking spaces.",
            status: .completed,
            budget: 22_000_000,
            spentToDate: 21_500_000,
            progress: 98,
            startDate: Date().addingTimeInterval(-365 * 86400),
            endDate: Date().addingTimeInterval(-2 * 86400),
            locationName: "555 Shopping Blvd, Retail District",
            latitude: 40.7831,
            longitude: -73.9712,
            clientName: "National Retail Properties"
        )
        context.insert(project5)
        
        // Tasks for High-rise Tower
        let t1 = TaskItem(title: "Foundation pour — Phase 2", descriptionText: "Complete the second phase of the foundation pour for the east wing.", priority: .high, status: .inProgress, dueDate: Date().addingTimeInterval(3 * 86400), assignedTo: "Mike Chen")
        t1.project = project1
        context.insert(t1)
        
        let t2 = TaskItem(title: "Structural steel delivery", descriptionText: "Receive and inventory structural steel beams for floors 15–30.", priority: .critical, status: .pending, dueDate: Date().addingTimeInterval(1 * 86400), assignedTo: "Sarah Johnson")
        t2.project = project1
        context.insert(t2)
        
        let t3 = TaskItem(title: "HVAC rough-in — Floors 5–10", priority: .medium, status: .pending, dueDate: Date().addingTimeInterval(7 * 86400), assignedTo: "Carlos Ruiz")
        t3.project = project1
        context.insert(t3)
        
        let t4 = TaskItem(title: "Window installation — South face", descriptionText: "Install all windows on the south-facing exterior, floors 10–20.", priority: .high, status: .completed, dueDate: Date().addingTimeInterval(-1 * 86400), assignedTo: "Aisha Patel")
        t4.project = project1
        context.insert(t4)
        
        // Tasks for Riverside Complex
        let t5 = TaskItem(title: "Site grading and compaction", priority: .high, status: .completed, dueDate: Date().addingTimeInterval(-5 * 86400), assignedTo: "Tom Wilson")
        t5.project = project2
        context.insert(t5)
        
        let t6 = TaskItem(title: "Underground utility layout", priority: .high, status: .inProgress, dueDate: Date().addingTimeInterval(2 * 86400), assignedTo: "Mike Chen")
        t6.project = project2
        context.insert(t6)
        
        let t7 = TaskItem(title: "Submit building permit amendment", priority: .critical, status: .blocked, dueDate: Date().addingTimeInterval(1 * 86400), assignedTo: "Sarah Johnson")
        t7.project = project2
        context.insert(t7)
        
        let t8 = TaskItem(title: "Order structural lumber package", priority: .medium, status: .pending, dueDate: Date().addingTimeInterval(14 * 86400), assignedTo: "Carlos Ruiz")
        t8.project = project2
        context.insert(t8)
        
        // Tasks for Downtown Office
        let t9 = TaskItem(title: "Asbestos abatement — Floors 3–6", descriptionText: "Complete asbestos removal and air quality certification.", priority: .critical, status: .completed, dueDate: Date().addingTimeInterval(-2 * 86400), assignedTo: "Aisha Patel")
        t9.project = project3
        context.insert(t9)
        
        let t10 = TaskItem(title: "New elevator shaft construction", priority: .high, status: .inProgress, dueDate: Date().addingTimeInterval(10 * 86400), assignedTo: "Tom Wilson")
        t10.project = project3
        context.insert(t10)
        
        // Incidents
        let i1 = Incident(title: "Slip and fall — Site entrance", descriptionText: "Worker slipped on wet concrete near main entrance. Minor ankle sprain. First aid administered on site.", severity: .low, incidentStatus: .resolved, reportedBy: "Sarah Johnson", location: "123 Main Street — Site entrance", date: Date().addingTimeInterval(-7 * 86400))
        i1.project = project1
        context.insert(i1)
        
        let i2 = Incident(title: "Scaffolding instability", descriptionText: "Scaffolding on the north face of the tower showed signs of instability at level 15. Area evacuated until inspection complete.", severity: .high, incidentStatus: .investigating, reportedBy: "Mike Chen", location: "123 Main Street — North face, level 15", date: Date().addingTimeInterval(-1 * 86400))
        i2.project = project1
        context.insert(i2)
        
        let i3 = Incident(title: "Equipment malfunction — Crane", descriptionText: "Crane #3 hydraulic system failure during operation. No injuries. Crane taken out of service pending repair.", severity: .medium, incidentStatus: .open, reportedBy: "Carlos Ruiz", location: "456 River Road — Crane #3", date: Date().addingTimeInterval(-3 * 86400))
        i3.project = project2
        context.insert(i3)
        
        // Inspections
        let ins1 = Inspection(title: "Weekly site safety walkthrough", inspector: "James O'Brien", result: .pass, date: Date().addingTimeInterval(-4 * 86400), notes: "All PPE in use. Fire extinguishers checked. First aid kits fully stocked. Minor trip hazard at material storage area — corrected on site.")
        context.insert(ins1)
        
        let ins2 = Inspection(title: "Structural frame inspection — Tower crane foundation", inspector: "City Building Dept — Inspector Miller", result: .conditional, date: Date().addingTimeInterval(-2 * 86400), notes: "Crane foundation passes load requirements. MUST add wind bracing documentation before next lift. Reinspect in 7 days.")
        context.insert(ins2)
        
        let ins3 = Inspection(title: "Electrical rough-in inspection", inspector: "Robert Kim — Electrical Inspector", result: .fail, date: Date().addingTimeInterval(-6 * 86400), notes: "Junction boxes on floor 8 not properly grounded. Conduit spacing on floor 12 exceeds code maximum. Schedule reinspection after corrections.")
        context.insert(ins3)
        
        // Workers
        let w1 = Worker(name: "Mike Chen", role: .foreman, phone: "555-0101", email: "mike.chen@buildtrack.com", certifications: ["OSHA 30", "Crane Operator: 2026-12-15", "First Aid/CPR: 2026-08-20"])
        context.insert(w1)
        
        let w2 = Worker(name: "Sarah Johnson", role: .supervisor, phone: "555-0102", email: "sarah.johnson@buildtrack.com", certifications: ["OSHA 30", "Safety Manager", "Confined Space Entry: 2026-06-10"])
        context.insert(w2)
        
        let w3 = Worker(name: "Carlos Ruiz", role: .electrician, phone: "555-0103", email: "carlos.ruiz@buildtrack.com", certifications: ["Licensed Electrician", "OSHA 10", "Arc Flash: 2026-04-30"])
        context.insert(w3)
        
        let w4 = Worker(name: "Aisha Patel", role: .engineer, phone: "555-0104", email: "aisha.patel@buildtrack.com", certifications: ["PE Licence", "Structural Engineer", "LEED AP"])
        context.insert(w4)
        
        let w5 = Worker(name: "Tom Wilson", role: .operator, phone: "555-0105", email: "tom.wilson@buildtrack.com", certifications: ["Heavy Equipment Operator", "OSHA 10", "Rigging & Signalling: 2025-11-01"])
        context.insert(w5)
        
        let w6 = Worker(name: "Maria Garcia", role: .carpenter, phone: "555-0106", email: "maria.garcia@buildtrack.com", certifications: ["Journeyman Carpenter", "OSHA 10", "Scaffold Competent Person: 2026-09-01"])
        context.insert(w6)
        
        let w7 = Worker(name: "David Kim", role: .plumber, phone: "555-0107", email: "david.kim@buildtrack.com", certifications: ["Licensed Plumber", "Backflow Prevention: 2026-07-15"])
        context.insert(w7)
        
        let w8 = Worker(name: "Lisa Wong", role: .engineer, phone: "555-0108", email: "lisa.wong@buildtrack.com", certifications: ["PE Licence", "Civil Engineer", "Erosion Control: 2026-05-30"])
        context.insert(w8)
    }
}
