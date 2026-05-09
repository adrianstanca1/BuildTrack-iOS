import SwiftUI
import SwiftData

// MARK: - Safety View (Redesigned)

struct SafetyView: View {
    @Query(sort: \Incident.date, order: .reverse) private var incidents: [Incident]
    @Query(sort: \Inspection.date, order: .reverse) private var inspections: [Inspection]
    @State private var selectedTab = 0
    @State private var showAddIncident = false
    @State private var showAddInspection = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented control
            Picker("View", selection: $selectedTab) {
                Text("Incidents (\(incidents.count))").tag(0)
                Text("Inspections (\(inspections.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    if selectedTab == 0 {
                        if incidents.isEmpty {
                            EmptyStateView(
                                icon: "shield.checkered",
                                title: "No Incidents",
                                message: "Report safety incidents to keep your team safe"
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(incidents) { incident in
                                ModernIncidentCard(incident: incident)
                            }
                        }
                    } else {
                        if inspections.isEmpty {
                            EmptyStateView(
                                icon: "checklist.checked",
                                title: "No Inspections",
                                message: "Schedule safety inspections for your sites"
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(inspections) { inspection in
                                ModernInspectionCard(inspection: inspection)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Safety")
        .toolbar {
            Button {
                if selectedTab == 0 { showAddIncident = true } else { showAddInspection = true }
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(BuildTrackColors.primary)
            }
        }
        .sheet(isPresented: $showAddIncident) { IncidentFormView() }
        .sheet(isPresented: $showAddInspection) { InspectionFormView() }
    }
}

// MARK: - Modern Incident Card

struct ModernIncidentCard: View {
    let incident: Incident
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(severityColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(severityColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    Text(incident.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
                
                Spacer()
                
                SeverityBadge(severity: incident.severity)
            }
            
            if !incident.descriptionText.isEmpty {
                Text(incident.descriptionText)
                    .font(.caption)
                    .foregroundStyle(BuildTrackColors.textSecondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 8) {
                if !incident.location.isEmpty {
                    Label(incident.location, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
                
                if !incident.reportedBy.isEmpty {
                    Label(incident.reportedBy, systemImage: "person")
                        .font(.caption2)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
                
                Spacer()
                
                StatusBadge(status: incident.incidentStatus)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
    
    var severityColor: Color {
        BuildTrackColors.severityColor(incident.severity)
    }
}

// MARK: - Modern Inspection Card

struct ModernInspectionCard: View {
    let inspection: Inspection
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: inspection.result == .pass ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(resultColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(inspection.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                if !inspection.inspector.isEmpty {
                    Text("Inspector: \(inspection.inspector)")
                        .font(.caption)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                }
                
                Text(inspection.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(BuildTrackColors.textTertiary)
            }
            
            Spacer()
            
            ResultBadge(result: inspection.result)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
    
    var resultColor: Color {
        inspection.result == .pass ? BuildTrackColors.success : BuildTrackColors.danger
    }
}

// MARK: - Status Badge for Incidents

extension StatusBadge {
    init(status: IncidentStatus) {
        self.status = {
            switch status {
            case .open: return .active
            case .investigating: return .onHold
            case .resolved: return .completed
            case .closed: return .completed
            }
        }()
    }
}

// MARK: - Incident Form

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
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(2...5)
                }
                
                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(IncidentSeverity.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Info") {
                    TextField("Reported By", text: $reportedBy)
                    TextField("Location", text: $location)
                    DatePicker("Date", selection: $date)
                }
            }
            .navigationTitle("Report Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Report") {
                        let incident = Incident(
                            title: title,
                            descriptionText: descriptionText,
                            severity: severity,
                            reportedBy: reportedBy,
                            location: location,
                            date: date
                        )
                        modelContext.insert(incident)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
    }
}

// MARK: - Inspection Form

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
                Section("Details") {
                    TextField("Title", text: $title)
                }
                
                Section("Result") {
                    Picker("Result", selection: $result) {
                        ForEach(InspectionResult.allCases, id: \.self) { r in
                            Text(r.label).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Info") {
                    TextField("Inspector", text: $inspector)
                    DatePicker("Date", selection: $date)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("New Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let inspection = Inspection(
                            title: title,
                            inspector: inspector,
                            result: result,
                            date: date,
                            notes: notes
                        )
                        modelContext.insert(inspection)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
    }
}

#Preview {
    SafetyView()
        .modelContainer(for: [Incident.self, Inspection.self])
}
