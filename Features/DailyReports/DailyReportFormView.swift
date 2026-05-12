import SwiftUI
import SwiftData

struct DailyReportFormView: View {
    var report: DailyReport?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var date = Date()
    @State private var weather: WeatherCondition = .clear
    @State private var temperature = ""
    @State private var workersOnSite = ""
    @State private var status: DailyReportStatus = .draft
    @State private var summary = ""
    @State private var workCompleted = ""
    @State private var notes = ""
    var isEditing: Bool { report != nil }
    var isValid: Bool { !summary.trimmingCharacters(in: .whitespaces).isEmpty }

    init(report: DailyReport? = nil) {
        self.report = report
        _date = State(initialValue: report?.date ?? Date())
        _weather = State(initialValue: report?.weather ?? .clear)
        _temperature = State(initialValue: report.map { String(Int($0.temperature)) } ?? "")
        _workersOnSite = State(initialValue: report.map { String($0.workersOnSite) } ?? "")
        _status = State(initialValue: report?.status ?? .draft)
        _summary = State(initialValue: report?.summary ?? "")
        _workCompleted = State(initialValue: report?.workCompleted ?? "")
        _notes = State(initialValue: report?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Report") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Status", selection: $status) {
                        ForEach(DailyReportStatus.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Conditions") {
                    Picker("Weather", selection: $weather) {
                        ForEach(WeatherCondition.allCases, id: \.self) { w in
                            Text(w.rawValue.capitalized).tag(w)
                        }
                    }
                    TextField("Temperature (°C)", text: $temperature)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Workers on site", text: $workersOnSite)
                        .keyboardType(.numberPad)
                }
                Section("Summary") {
                    TextField("Summary", text: $summary, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Work Completed") {
                    TextField("Describe work completed", text: $workCompleted, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
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
        let temp = Double(temperature) ?? 0
        let workers = Int(workersOnSite) ?? 0
        if let report {
            report.date = date
            report.reportDate = date
            report.weather = weather
            report.temperature = temp
            report.workersOnSite = workers
            report.status = status
            report.summary = summary
            report.workCompleted = workCompleted
            report.notes = notes
            report.updatedAt = Date()
        } else {
            let newReport = DailyReport(
                date: date,
                reportDate: date,
                weather: weather,
                temperature: temp,
                workersOnSite: workers,
                status: status,
                summary: summary,
                workCompleted: workCompleted,
                notes: notes
            )
            modelContext.insert(newReport)
        }
        dismiss()
    }
}
