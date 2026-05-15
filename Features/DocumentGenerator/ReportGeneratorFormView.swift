import SwiftUI
import SwiftData

struct ReportGeneratorFormView: View {
    let template: DocumentTemplate
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]
    @Query(sort: \Worker.name) private var workers: [Worker]

    @State private var selectedProject: Project?
    @State private var selectedWorker: Worker?
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var generatedPDF: Data?
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            Form {
                if template == .timesheetSummary {
                    Section("Worker") {
                        Picker("Select Worker", selection: $selectedWorker) {
                            Text("All Workers").tag(Worker?.none)
                            ForEach(workers) { worker in
                                Text(worker.name).tag(Worker?.some(worker))
                            }
                        }
                    }
                } else if template != .safetyIncident {
                    Section("Project") {
                        Picker("Select Project", selection: $selectedProject) {
                            Text("All Projects").tag(Project?.none)
                            ForEach(projects) { project in
                                Text(project.name).tag(Project?.some(project))
                            }
                        }
                    }
                }

                Section("Date Range") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, displayedComponents: .date)
                }

                Section {
                    Button {
                        Task { await generate() }
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                            } else {
                                Text("Generate PDF")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isGenerating || (!needsProject || selectedProject != nil))
                }
            }
            .navigationTitle(template.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: Binding(
                get: { generatedPDF != nil },
                set: { if !$0 { generatedPDF = nil } }
            )) {
                if let data = generatedPDF {
                    PDFPreviewView(pdfData: data, title: template.title)
                }
            }
        }
    }

    private var needsProject: Bool {
        template == .projectStatus || template == .punchList || template == .dailyReport || template == .budgetOverview
    }

    private func generate() async {
        isGenerating = true
        defer { isGenerating = false }

        // Simulate data fetch/generation
        try? await Task.sleep(nanoseconds: 800_000_000)

        var pdfData: Data
        switch template {
        case .dailyReport:
            pdfData = PDFGenerator.generateDailyReport(project: selectedProject ?? Project(name: "All Projects", budget: 0), reports: [])
        case .timesheetSummary:
            pdfData = PDFGenerator.generateTimesheetSummary(workerName: selectedWorker?.name ?? "All Workers", entries: [])
        case .safetyIncident:
            pdfData = PDFGenerator.generateSafetyReport(incidents: [])
        case .projectStatus:
            pdfData = PDFGenerator.generateProjectStatus(project: selectedProject ?? Project(name: "Project", budget: 0), tasks: [], budget: nil)
        case .budgetOverview:
            let budget = Budget(name: "Budget", totalBudget: selectedProject?.budget ?? 0, totalSpent: selectedProject?.spentToDate ?? 0)
            pdfData = PDFGenerator.generateBudgetOverview(project: selectedProject ?? Project(name: "Project", budget: 0), budget: budget, items: [])
        case .punchList:
            pdfData = PDFGenerator.generatePunchList(project: selectedProject ?? Project(name: "Project", budget: 0), items: [])
        }

        await MainActor.run {
            generatedPDF = pdfData
        }
    }
}
