import SwiftUI
import SwiftData

struct SafetyView: View {
    @Query(sort: \Incident.date, order: .reverse) private var incidents: [Incident]
    @Query(sort: \Inspection.date, order: .reverse) private var inspections: [Inspection]
    @State private var selectedTab = 0
    @State private var showAddIncident = false
    @State private var showAddInspection = false
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("Incidents (\(incidents.count))").tag(0)
                Text("Inspections (\(inspections.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    if selectedTab == 0 {
                        if incidents.isEmpty {
                            EmptyStateView(icon: "shield.checkered", title: "No Incidents", message: "Report safety incidents to keep your team safe")
                        }
                        ForEach(incidents) { incident in
                            IncidentCard(incident: incident)
                        }
                    } else {
                        if inspections.isEmpty {
                            EmptyStateView(icon: "checklist.checked", title: "No Inspections", message: "Schedule safety inspections for your sites")
                        }
                        ForEach(inspections) { inspection in
                            InspectionCard(inspection: inspection)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Safety")
        .toolbar {
            Button {
                if selectedTab == 0 { showAddIncident = true } else { showAddInspection = true }
            } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showAddIncident) { IncidentFormView() }
        .sheet(isPresented: $showAddInspection) { InspectionFormView() }
    }
}

struct IncidentCard: View {
    let incident: Incident
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(severityColor)
                Text(incident.title).font(.headline)
                Spacer()
                SeverityBadge(severity: incident.severity)
            }
            if !incident.descriptionText.isEmpty {
                Text(incident.descriptionText).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            HStack {
                Label(incident.location, systemImage: "mappin").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(incident.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
    
    var severityColor: Color {
        switch incident.severity {
        case .low: .yellow; case .medium: .orange; case .high: .red; case .critical: .purple
        }
    }
}

struct InspectionCard: View {
    let inspection: Inspection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: inspection.result == .pass ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .foregroundStyle(inspection.result == .pass ? .green : .red)
                Text(inspection.title).font(.headline)
                Spacer()
                ResultBadge(result: inspection.result)
            }
            if !inspection.notes.isEmpty {
                Text(inspection.notes).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            HStack {
                Label("Inspector: \(inspection.inspector)", systemImage: "person").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(inspection.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct ResultBadge: View {
    let result: InspectionResult
    var body: some View {
        Text(result.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(result == .pass ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
            .foregroundStyle(result == .pass ? .green : .red)
            .clipShape(Capsule())
    }
}

struct IncidentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var severity: IncidentSeverity = .low
    @State private var reportedBy = ""
    @State private var location = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Title", text: $title) }
                Section { TextField("Description", text: $descriptionText, axis: .vertical).lineLimit(2...5) }
                Section { Picker("Severity", selection: $severity) { ForEach(IncidentSeverity.allCases, id: \.self) { Text($0.label).tag($0) } } }
                Section { TextField("Reported By", text: $reportedBy); TextField("Location", text: $location); DatePicker("Date", selection: $date) }
            }
            .navigationTitle("Report Incident")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Report") {
                        let incident = Incident(title: title, descriptionText: descriptionText, severity: severity, reportedBy: reportedBy, location: location, date: date)
                        modelContext.insert(incident)
                        dismiss()
                    }.disabled(title.isEmpty)
                }
            }
        }
    }
}

struct InspectionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var inspector = ""
    @State private var result: InspectionResult = .pass
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Title", text: $title) }
                Section {
                    Picker("Result", selection: $result) { ForEach(InspectionResult.allCases, id: \.self) { Text($0.label).tag($0) } }
                }
                Section { TextField("Inspector", text: $inspector); DatePicker("Date", selection: $date) }
                Section("Notes") { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5) }
            }
            .navigationTitle("New Inspection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let inspection = Inspection(title: title, inspector: inspector, result: result, date: date, notes: notes)
                        modelContext.insert(inspection)
                        dismiss()
                    }.disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SafetyView().modelContainer(for: [Incident.self, Inspection.self])
}
