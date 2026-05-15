import Foundation
import Supabase

// MARK: - Timesheet Repository

struct TimesheetRepository {
    static let live = TimesheetRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseTimesheet] = try await client
                .from("timesheet_entries")
                .select()
                .order("date", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByWorker: { workerName in
            let client = SupabaseManager.shared.client
            let response: [SupabaseTimesheet] = try await client
                .from("timesheet_entries")
                .select()
                .eq("worker_name", value: workerName)
                .order("date", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByDateRange: { startDate, endDate in
            let client = SupabaseManager.shared.client
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let response: [SupabaseTimesheet] = try await client
                .from("timesheet_entries")
                .select()
                .gte("date", value: formatter.string(from: startDate))
                .lte("date", value: formatter.string(from: endDate))
                .order("date", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { entry in
            let client = SupabaseManager.shared.client
            let payload = SupabaseTimesheetPayload(from: entry)
            let response: SupabaseTimesheet = try await client
                .from("timesheet_entries")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { entry in
            let client = SupabaseManager.shared.client
            let payload = SupabaseTimesheetPayload(from: entry)
            let _: SupabaseTimesheet = try await client
                .from("timesheet_entries")
                .update(payload)
                .eq("id", value: entry.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("timesheet_entries")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )
    
    let fetchAll: () async throws -> [TimesheetEntry]
    let fetchByWorker: (String) async throws -> [TimesheetEntry]
    let fetchByDateRange: (Date, Date) async throws -> [TimesheetEntry]
    let create: (TimesheetEntry) async throws -> TimesheetEntry
    let update: (TimesheetEntry) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Timesheet Payload

struct SupabaseTimesheetPayload: Codable {
    let id: String
    let workerName: String
    let hoursWorked: Double
    let task: String
    let status: String
    let date: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case workerName = "worker_name"
        case hoursWorked = "hours_worked"
        case task
        case status
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from entry: TimesheetEntry) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = entry.id.uuidString
        self.workerName = entry.workerName
        self.hoursWorked = entry.hoursWorked
        self.task = entry.task
        self.status = entry.status.supabaseValue
        self.date = formatter.string(from: entry.date)
        self.createdAt = formatter.string(from: entry.createdAt)
        self.updatedAt = formatter.string(from: entry.updatedAt)
    }
}
