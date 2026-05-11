import SwiftUI
import SwiftData

struct DailyReportDetailView: View {
    let report: DailyReport
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                statusSection
                weatherSection
                workSection
                materialsSection
                issuesSection
                safetySection
                nextDaySection
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Daily Report")
        .toolbar {
            Button { showEdit = true } label: {
                Text("Edit")
            }
        }
        .sheet(isPresented: $showEdit) {
            DailyReportFormView(report: report)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(report.reportDate.formatted(date: .long, time: .omitted))
                .font(.title2.weight(.semibold))
            Label(report.submittedBy, systemImage: "person")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusSection: some View {
        DetailSection(title: "Status") {
            StatusBadge(status: report.status)
        }
    }

    private var weatherSection: some View {
        DetailSection(title: "Weather") {
            HStack(spacing: 16) {
                DetailRow(icon: "cloud.sun", label: "Condition", value: report.weather.isEmpty ? "—" : report.weather)
                DetailRow(icon: "thermometer", label: "Temperature", value: "\(Int(report.temperature))\u00b0C")
                DetailRow(icon: "person.2", label: "Workers", value: "\(report.workersOnSite)")
            }
        }
    }

    private var workSection: some View {
        DetailSection(title: "Work Completed") {
            Text(report.workCompleted.isEmpty ? "No details" : report.workCompleted)
                .font(.body)
        }
    }

    private var materialsSection: some View {
        DetailSection(title: "Materials & Equipment") {
            if !report.materialsUsed.isEmpty {
                Text(report.materialsUsed)
                    .font(.body)
            }
            if !report.equipmentUsed.isEmpty {
                Text(report.equipmentUsed)
                    .font(.body)
            }
            if report.materialsUsed.isEmpty && report.equipmentUsed.isEmpty {
                Text("No details")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var issuesSection: some View {
        DetailSection(title: "Issues & Delays") {
            Text(report.issuesDelays.isEmpty ? "None reported" : report.issuesDelays)
                .font(.body)
        }
    }

    private var safetySection: some View {
        DetailSection(title: "Safety Observations") {
            Text(report.safetyObservations.isEmpty ? "None reported" : report.safetyObservations)
                .font(.body)
        }
    }

    private var nextDaySection: some View {
        DetailSection(title: "Next Day Plan") {
            Text(report.nextDayPlan.isEmpty ? "No plan set" : report.nextDayPlan)
                .font(.body)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Created: \(report.createdAt.formatted())")
            Text("Updated: \(report.updatedAt.formatted())")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        DailyReportDetailView(report: DailyReport(
            reportDate: Date(),
            weather: "Partly cloudy",
            temperature: 18,
            workersOnSite: 12,
            workCompleted: "Foundation pour completed for Block B",
            submittedBy: "Mike Chen"
        ))
    }
}
