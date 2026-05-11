import Foundation
import SwiftData

// MARK: - Budget
@Model
final class Budget: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var budgetDescription: String
    var totalBudget: Double
    var totalSpent: Double
    var currency: String
    var statusRaw: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var categories: [BudgetCategory]? = []

    var status: BudgetStatus {
        get { BudgetStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var progress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }

    init(
        id: UUID = UUID(),
        name: String,
        budgetDescription: String = "",
        totalBudget: Double = 0,
        totalSpent: Double = 0,
        currency: String = "GBP",
        status: BudgetStatus = .draft,
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.budgetDescription = budgetDescription
        self.totalBudget = totalBudget
        self.totalSpent = totalSpent
        self.currency = currency
        self.statusRaw = status.rawValue
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, budgetDescription, totalBudget, totalSpent, currency, statusRaw, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.budgetDescription = try container.decodeIfPresent(String.self, forKey: .budgetDescription) ?? ""
        self.totalBudget = try container.decodeIfPresent(Double.self, forKey: .totalBudget) ?? 0
        self.totalSpent = try container.decodeIfPresent(Double.self, forKey: .totalSpent) ?? 0
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "GBP"
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(budgetDescription, forKey: .budgetDescription)
        try container.encode(totalBudget, forKey: .totalBudget)
        try container.encode(totalSpent, forKey: .totalSpent)
        try container.encode(currency, forKey: .currency)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum BudgetStatus: String, CaseIterable, Codable {
    case draft, approved, revised, closed
    var label: String {
        switch self {
        case .draft: return "Draft"
        case .approved: return "Approved"
        case .revised: return "Revised"
        case .closed: return "Closed"
        }
    }
    var color: String {
        switch self {
        case .draft: return "gray"
        case .approved: return "green"
        case .revised: return "orange"
        case .closed: return "blue"
        }
    }
}

// MARK: - BudgetCategory
@Model
final class BudgetCategory: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryDescription: String
    var allocated: Double
    var spent: Double
    var budgetId: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        categoryDescription: String = "",
        allocated: Double = 0,
        spent: Double = 0,
        budgetId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.categoryDescription = categoryDescription
        self.allocated = allocated
        self.spent = spent
        self.budgetId = budgetId
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, categoryDescription, allocated, spent, budgetId, createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.categoryDescription = try container.decodeIfPresent(String.self, forKey: .categoryDescription) ?? ""
        self.allocated = try container.decodeIfPresent(Double.self, forKey: .allocated) ?? 0
        self.spent = try container.decodeIfPresent(Double.self, forKey: .spent) ?? 0
        self.budgetId = try container.decodeIfPresent(UUID.self, forKey: .budgetId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(categoryDescription, forKey: .categoryDescription)
        try container.encode(allocated, forKey: .allocated)
        try container.encode(spent, forKey: .spent)
        try container.encodeIfPresent(budgetId, forKey: .budgetId)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Material
@Model
final class Material: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var materialDescription: String
    var quantity: Double
    var unit: String
    var statusRaw: String
    var deliveryDate: Date?
    var supplier: String
    var cost: Double
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var status: MaterialStatus {
        get { MaterialStatus(rawValue: statusRaw) ?? .ordered }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: String = "",
        materialDescription: String = "",
        quantity: Double = 0,
        unit: String = "",
        status: MaterialStatus = .ordered,
        deliveryDate: Date? = nil,
        supplier: String = "",
        cost: Double = 0,
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.materialDescription = materialDescription
        self.quantity = quantity
        self.unit = unit
        self.statusRaw = status.rawValue
        self.deliveryDate = deliveryDate
        self.supplier = supplier
        self.cost = cost
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, materialDescription, quantity, unit, statusRaw, deliveryDate, supplier, cost, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.materialDescription = try container.decodeIfPresent(String.self, forKey: .materialDescription) ?? ""
        self.quantity = try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 0
        self.unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.deliveryDate = try container.decodeIfPresent(Date.self, forKey: .deliveryDate)
        self.supplier = try container.decodeIfPresent(String.self, forKey: .supplier) ?? ""
        self.cost = try container.decodeIfPresent(Double.self, forKey: .cost) ?? 0
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(materialDescription, forKey: .materialDescription)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unit, forKey: .unit)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encodeIfPresent(deliveryDate, forKey: .deliveryDate)
        try container.encode(supplier, forKey: .supplier)
        try container.encode(cost, forKey: .cost)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum MaterialStatus: String, CaseIterable, Codable {
    case ordered, delivered, inStock, used
    var label: String {
        switch self {
        case .ordered: return "Ordered"
        case .delivered: return "Delivered"
        case .inStock: return "In Stock"
        case .used: return "Used"
        }
    }
}

// MARK: - Equipment
@Model
final class Equipment: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var equipmentType: String
    var make: String
    var model: String
    var serialNumber: String
    var statusRaw: String
    var assignedTo: String
    var location: String
    var hoursUsed: Double
    var lastServiceDate: Date?
    var nextServiceDate: Date?
    var cost: Double
    var notes: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var status: EquipmentStatus {
        get { EquipmentStatus(rawValue: statusRaw) ?? .available }
        set { statusRaw = newValue.rawValue }
    }

    var isServiceDue: Bool {
        guard let next = nextServiceDate else { return false }
        return next <= Date()
    }

    init(
        id: UUID = UUID(),
        name: String,
        equipmentType: String = "",
        make: String = "",
        model: String = "",
        serialNumber: String = "",
        status: EquipmentStatus = .available,
        assignedTo: String = "",
        location: String = "",
        hoursUsed: Double = 0,
        lastServiceDate: Date? = nil,
        nextServiceDate: Date? = nil,
        cost: Double = 0,
        notes: String = "",
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.equipmentType = equipmentType
        self.make = make
        self.model = model
        self.serialNumber = serialNumber
        self.statusRaw = status.rawValue
        self.assignedTo = assignedTo
        self.location = location
        self.hoursUsed = hoursUsed
        self.lastServiceDate = lastServiceDate
        self.nextServiceDate = nextServiceDate
        self.cost = cost
        self.notes = notes
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, equipmentType, make, model, serialNumber, statusRaw, assignedTo, location, hoursUsed, lastServiceDate, nextServiceDate, cost, notes, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.equipmentType = try container.decodeIfPresent(String.self, forKey: .equipmentType) ?? ""
        self.make = try container.decodeIfPresent(String.self, forKey: .make) ?? ""
        self.model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""
        self.serialNumber = try container.decodeIfPresent(String.self, forKey: .serialNumber) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo) ?? ""
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.hoursUsed = try container.decodeIfPresent(Double.self, forKey: .hoursUsed) ?? 0
        self.lastServiceDate = try container.decodeIfPresent(Date.self, forKey: .lastServiceDate)
        self.nextServiceDate = try container.decodeIfPresent(Date.self, forKey: .nextServiceDate)
        self.cost = try container.decodeIfPresent(Double.self, forKey: .cost) ?? 0
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(equipmentType, forKey: .equipmentType)
        try container.encode(make, forKey: .make)
        try container.encode(model, forKey: .model)
        try container.encode(serialNumber, forKey: .serialNumber)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(assignedTo, forKey: .assignedTo)
        try container.encode(location, forKey: .location)
        try container.encode(hoursUsed, forKey: .hoursUsed)
        try container.encodeIfPresent(lastServiceDate, forKey: .lastServiceDate)
        try container.encodeIfPresent(nextServiceDate, forKey: .nextServiceDate)
        try container.encode(cost, forKey: .cost)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum EquipmentStatus: String, CaseIterable, Codable {
    case available, inUse, maintenance, retired
    var label: String {
        switch self {
        case .available: return "Available"
        case .inUse: return "In Use"
        case .maintenance: return "Maintenance"
        case .retired: return "Retired"
        }
    }
}

// MARK: - Meeting
@Model
final class Meeting: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var meetingTypeRaw: String
    var date: Date
    var startTime: String
    var endTime: String
    var location: String
    var agenda: String
    var minutes: String
    var projectId: UUID?
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date

    var meetingType: MeetingType {
        get { MeetingType(rawValue: meetingTypeRaw) ?? .other }
        set { meetingTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        meetingType: MeetingType = .other,
        date: Date = Date(),
        startTime: String = "",
        endTime: String = "",
        location: String = "",
        agenda: String = "",
        minutes: String = "",
        projectId: UUID? = nil,
        createdBy: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.meetingTypeRaw = meetingType.rawValue
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.agenda = agenda
        self.minutes = minutes
        self.projectId = projectId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, meetingTypeRaw, date, startTime, endTime, location, agenda, minutes, projectId, createdBy, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.meetingTypeRaw = try container.decode(String.self, forKey: .meetingTypeRaw)
        self.date = try container.decode(Date.self, forKey: .date)
        self.startTime = try container.decodeIfPresent(String.self, forKey: .startTime) ?? ""
        self.endTime = try container.decodeIfPresent(String.self, forKey: .endTime) ?? ""
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.agenda = try container.decodeIfPresent(String.self, forKey: .agenda) ?? ""
        self.minutes = try container.decodeIfPresent(String.self, forKey: .minutes) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(meetingTypeRaw, forKey: .meetingTypeRaw)
        try container.encode(date, forKey: .date)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(location, forKey: .location)
        try container.encode(agenda, forKey: .agenda)
        try container.encode(minutes, forKey: .minutes)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum MeetingType: String, CaseIterable, Codable {
    case site, progress, safety, design, other
    var label: String {
        switch self {
        case .site: return "Site"
        case .progress: return "Progress"
        case .safety: return "Safety"
        case .design: return "Design"
        case .other: return "Other"
        }
    }
}

// MARK: - TimesheetEntry
@Model
final class TimesheetEntry: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var workerName: String
    var date: Date
    var startTime: String
    var endTime: String
    var breakMinutes: Int
    var hoursWorked: Double
    var task: String
    var notes: String
    var statusRaw: String
    var approvedBy: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var status: TimesheetStatus {
        get { TimesheetStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        workerName: String,
        date: Date = Date(),
        startTime: String = "",
        endTime: String = "",
        breakMinutes: Int = 0,
        hoursWorked: Double = 0,
        task: String = "",
        notes: String = "",
        status: TimesheetStatus = .draft,
        approvedBy: String = "",
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.workerName = workerName
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakMinutes = breakMinutes
        self.hoursWorked = hoursWorked
        self.task = task
        self.notes = notes
        self.statusRaw = status.rawValue
        self.approvedBy = approvedBy
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, workerName, date, startTime, endTime, breakMinutes, hoursWorked, task, notes, statusRaw, approvedBy, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.workerName = try container.decode(String.self, forKey: .workerName)
        self.date = try container.decode(Date.self, forKey: .date)
        self.startTime = try container.decodeIfPresent(String.self, forKey: .startTime) ?? ""
        self.endTime = try container.decodeIfPresent(String.self, forKey: .endTime) ?? ""
        self.breakMinutes = try container.decodeIfPresent(Int.self, forKey: .breakMinutes) ?? 0
        self.hoursWorked = try container.decodeIfPresent(Double.self, forKey: .hoursWorked) ?? 0
        self.task = try container.decodeIfPresent(String.self, forKey: .task) ?? ""
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.approvedBy = try container.decodeIfPresent(String.self, forKey: .approvedBy) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(workerName, forKey: .workerName)
        try container.encode(date, forKey: .date)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(breakMinutes, forKey: .breakMinutes)
        try container.encode(hoursWorked, forKey: .hoursWorked)
        try container.encode(task, forKey: .task)
        try container.encode(notes, forKey: .notes)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(approvedBy, forKey: .approvedBy)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum TimesheetStatus: String, CaseIterable, Codable {
    case draft, submitted, approved, rejected
    var label: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

// MARK: - Permit
@Model
final class Permit: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var permitNumber: String
    var permitType: String
    var authority: String
    var statusRaw: String
    var issueDate: Date?
    var expiryDate: Date?
    var permitDescription: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var status: PermitStatus {
        get { PermitStatus(rawValue: statusRaw) ?? .applied }
        set { statusRaw = newValue.rawValue }
    }

    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }

    var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiry).day
    }

    init(
        id: UUID = UUID(),
        permitNumber: String,
        permitType: String = "",
        authority: String = "",
        status: PermitStatus = .applied,
        issueDate: Date? = nil,
        expiryDate: Date? = nil,
        permitDescription: String = "",
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.permitNumber = permitNumber
        self.permitType = permitType
        self.authority = authority
        self.statusRaw = status.rawValue
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.permitDescription = permitDescription
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, permitNumber, permitType, authority, statusRaw, issueDate, expiryDate, permitDescription, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.permitNumber = try container.decode(String.self, forKey: .permitNumber)
        self.permitType = try container.decodeIfPresent(String.self, forKey: .permitType) ?? ""
        self.authority = try container.decodeIfPresent(String.self, forKey: .authority) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.issueDate = try container.decodeIfPresent(Date.self, forKey: .issueDate)
        self.expiryDate = try container.decodeIfPresent(Date.self, forKey: .expiryDate)
        self.permitDescription = try container.decodeIfPresent(String.self, forKey: .permitDescription) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(permitNumber, forKey: .permitNumber)
        try container.encode(permitType, forKey: .permitType)
        try container.encode(authority, forKey: .authority)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encodeIfPresent(issueDate, forKey: .issueDate)
        try container.encodeIfPresent(expiryDate, forKey: .expiryDate)
        try container.encode(permitDescription, forKey: .permitDescription)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum PermitStatus: String, CaseIterable, Codable {
    case applied, underReview, approved, rejected, expired
    var label: String {
        switch self {
        case .applied: return "Applied"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Defect
@Model
final class Defect: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var defectDescription: String
    var location: String
    var severityRaw: String
    var statusRaw: String
    var assignedTo: String
    var dueDate: Date?
    var createdBy: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var severity: DefectSeverity {
        get { DefectSeverity(rawValue: severityRaw) ?? .minor }
        set { severityRaw = newValue.rawValue }
    }

    var status: DefectStatus {
        get { DefectStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && status != .closed
    }

    init(
        id: UUID = UUID(),
        title: String,
        defectDescription: String = "",
        location: String = "",
        severity: DefectSeverity = .minor,
        status: DefectStatus = .open,
        assignedTo: String = "",
        dueDate: Date? = nil,
        createdBy: String = "",
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.defectDescription = defectDescription
        self.location = location
        self.severityRaw = severity.rawValue
        self.statusRaw = status.rawValue
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.createdBy = createdBy
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, defectDescription, location, severityRaw, statusRaw, assignedTo, dueDate, createdBy, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.defectDescription = try container.decodeIfPresent(String.self, forKey: .defectDescription) ?? ""
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.severityRaw = try container.decode(String.self, forKey: .severityRaw)
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo) ?? ""
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(defectDescription, forKey: .defectDescription)
        try container.encode(location, forKey: .location)
        try container.encode(severityRaw, forKey: .severityRaw)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(assignedTo, forKey: .assignedTo)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum DefectSeverity: String, CaseIterable, Codable {
    case minor, major, critical
    var label: String {
        switch self {
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }
}

enum DefectStatus: String, CaseIterable, Codable {
    case open, inProgress, resolved, closed
    var label: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }
}

// MARK: - DailyReport
@Model
final class DailyReport: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var reportDate: Date
    var weather: String
    var temperature: Double
    var workersOnSite: Int
    var workCompleted: String
    var materialsUsed: String
    var equipmentUsed: String
    var issuesDelays: String
    var safetyObservations: String
    var nextDayPlan: String
    var submittedBy: String
    var statusRaw: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var status: DailyReportStatus {
        get { DailyReportStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        reportDate: Date = Date(),
        weather: String = "",
        temperature: Double = 0,
        workersOnSite: Int = 0,
        workCompleted: String = "",
        materialsUsed: String = "",
        equipmentUsed: String = "",
        issuesDelays: String = "",
        safetyObservations: String = "",
        nextDayPlan: String = "",
        submittedBy: String = "",
        status: DailyReportStatus = .draft,
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.reportDate = reportDate
        self.weather = weather
        self.temperature = temperature
        self.workersOnSite = workersOnSite
        self.workCompleted = workCompleted
        self.materialsUsed = materialsUsed
        self.equipmentUsed = equipmentUsed
        self.issuesDelays = issuesDelays
        self.safetyObservations = safetyObservations
        self.nextDayPlan = nextDayPlan
        self.submittedBy = submittedBy
        self.statusRaw = status.rawValue
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, reportDate, weather, temperature, workersOnSite, workCompleted
        case materialsUsed, equipmentUsed, issuesDelays, safetyObservations
        case nextDayPlan, submittedBy, statusRaw, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.reportDate = try container.decode(Date.self, forKey: .reportDate)
        self.weather = try container.decodeIfPresent(String.self, forKey: .weather) ?? ""
        self.temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0
        self.workersOnSite = try container.decodeIfPresent(Int.self, forKey: .workersOnSite) ?? 0
        self.workCompleted = try container.decodeIfPresent(String.self, forKey: .workCompleted) ?? ""
        self.materialsUsed = try container.decodeIfPresent(String.self, forKey: .materialsUsed) ?? ""
        self.equipmentUsed = try container.decodeIfPresent(String.self, forKey: .equipmentUsed) ?? ""
        self.issuesDelays = try container.decodeIfPresent(String.self, forKey: .issuesDelays) ?? ""
        self.safetyObservations = try container.decodeIfPresent(String.self, forKey: .safetyObservations) ?? ""
        self.nextDayPlan = try container.decodeIfPresent(String.self, forKey: .nextDayPlan) ?? ""
        self.submittedBy = try container.decodeIfPresent(String.self, forKey: .submittedBy) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reportDate, forKey: .reportDate)
        try container.encode(weather, forKey: .weather)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(workersOnSite, forKey: .workersOnSite)
        try container.encode(workCompleted, forKey: .workCompleted)
        try container.encode(materialsUsed, forKey: .materialsUsed)
        try container.encode(equipmentUsed, forKey: .equipmentUsed)
        try container.encode(issuesDelays, forKey: .issuesDelays)
        try container.encode(safetyObservations, forKey: .safetyObservations)
        try container.encode(nextDayPlan, forKey: .nextDayPlan)
        try container.encode(submittedBy, forKey: .submittedBy)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum DailyReportStatus: String, CaseIterable, Codable {
    case draft, submitted, approved
    var label: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .approved: return "Approved"
        }
    }
    var color: String {
        switch self {
        case .draft: return "gray"
        case .submitted: return "blue"
        case .approved: return "green"
        }
    }
}
