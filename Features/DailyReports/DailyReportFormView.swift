import SwiftUI
import SwiftData

struct DailyReportFormView: View {
    var report: DailyReport?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var reportDate = Date()
    @State private var weather = ""
    @State private var temperature = ""
    @State private var workersOnSite = ""
    @State private var workCompleted = ""
    @State private var materialsUsed = ""
    @State private var equipmentUsed = ""
    @State private var issuesDelays = ""
    @State private var safetyObservations = ""
    @State private var nextDayPlan = ""
    @State private var submittedBy = ""
    @State private var status: DailyReportStatus = .draft
    var isEditing: Bool { report != nil }
    var isValid: Bool { !submittedBy.trimmingCharacters(in: .whitespaces).isEmpty }

    init(report: DailyReport? = nil) {
        self.report = report
        _reportDate = State(initialValue: report?.reportDate ?? Date())
        _weather = State(initialValue: report?.weather ?? "")
        _temperature = State(initialValue: report.map { String($0.temperature) } ?? "")
        _workersOnSite = State(initialValue: report.map { String($0.workersOnSite) } ?? "")
        _workCompleted = State(initialValue: report?.workCompleted ?? "")
        _materialsUsed = State(initialValue: report?.materialsUsed ?? "")
        _equipmentUsed = State(initialValue: report?.equipmentUsed ?? "")
        _issuesDelays = State(initialValue: report?.issuesDelays ?? "")
        _safetyObservations = State(initialValue: report?.safetyObservations ?? "")
        _nextDayPlan = State(initialValue: report?.nextDayPlan ?? "")
        _submittedBy = State(initialValue: report?.submittedBy ?? "")
        _status = State(initialValue: report?.status ?? .draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Report Date") {
                    DatePicker("Date", selection: $reportDate, displayedComponents: .date)
                }
                Section("Weather & Conditions") {
                    TextField("Weather (e.g. Sunny)", text: $weather)
                    TextField("Temperature (\u00b0C)", text: $temperature)
                        .keyboardType(.decimalPad)
                }
                Section("Site Info") {
                    TextField("Workers on Site", text: $workersOnSite)
                        .keyboardType(.numberPad)
                    TextField("Submitted By", text: $submittedBy)
                }
                Section("Work Completed") {
                    TextField("Description", text: $workCompleted, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Materials Used") {
                    TextField("Materials", text: $materialsUsed, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Equipment Used") {
                    TextField("Equipment", text: $equipmentUsed, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Issues & Delays") {
                    TextField("Issues", text: $issuesDelays, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Safety Observations") {
                    TextField("Observations", text: $safetyObservations, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Next Day Plan") {
                    TextField("Plan", text: $nextDayPlan, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(DailyReportStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isEditing ? "Edit Report" : "New Daily Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        if let report {
            report.reportDate = reportDate
            report.weather = weather
            report.temperature = Double(temperature) ?? 0
            report.workersOnSite = Int(workersOnSite) ?? 0
            report.workCompleted = workCompleted
            report.materialsUsed = materialsUsed
            report.equipmentUsed = equipmentUsed
            report.issuesDelays = issuesDelays
            report.safetyObservations = safetyObservations
            report.nextDayPlan = nextDayPlan
            report.submittedBy = submittedBy
            report.status = status
            report.updatedAt = Date()
        } else {
            let newReport = DailyReport(
                reportDate: reportDate,
                weather: weather,
                temperature: Double(temperature) ?? 0,
                workersOnSite: Int(workersOnSite) ?? 0,
                workCompleted: workCompleted,
                materialsUsed: materialsUsed,
                equipmentUsed: equipmentUsed,
                issuesDelays: issuesDelays,
                safetyObservations: safetyObservations,
                nextDayPlan: nextDayPlan,
                submittedBy: submittedBy,
                status: status
            )
            modelContext.insert(newReport)
        }
        dismiss()
    }
}
