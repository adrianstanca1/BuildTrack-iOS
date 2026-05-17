import SwiftUI
import SwiftData

@MainActor
struct SafetyDetailView: View {
    let incident: Incident
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SeverityBadge(severity: incident.severity)
                        StatusBadge(status: incident.incidentStatus)
                        Spacer()
                    }
                    Text(incident.title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)

                // Details Card
                DetailCard(title: "Details") {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "exclamationmark.triangle", label: "Severity", value: incident.severity.label)
                        DetailRow(icon: "checkmark.circle", label: "Status", value: incident.incidentStatus.label)
                        DetailRow(icon: "calendar", label: "Date", value: incident.date.formatted(date: .abbreviated, time: .shortened))
                        if !incident.location.isEmpty {
                            DetailRow(icon: "mappin", label: "Location", value: incident.location)
                        }
                        if !incident.reportedBy.isEmpty {
                            DetailRow(icon: "person", label: "Reported By", value: incident.reportedBy)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Description
                if !incident.descriptionText.isEmpty {
                    DetailCard(title: "Description") {
                        Text(incident.descriptionText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Incident", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(BuildTrackColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Incident", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Incident Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditSheet = true } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            SafetyFormView(incident: incident)
        }
        .alert("Delete Incident?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteIncident()
            }
        } message: {
            Text("Are you sure you want to delete this incident?")
        }
    }

    private func deleteIncident() {
        // TODO: Delete from model context
        dismiss()
    }
}

struct SeverityBadge: View {
    let severity: IncidentSeverity

    var body: some View {
        Text(severity.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(severityColor.opacity(0.15))
            .foregroundStyle(severityColor)
            .clipShape(Capsule())
    }

    private var severityColor: Color {
        switch severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct StatusBadge: View {
    let status: IncidentStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .open: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .closed: return .gray
        }
    }
}

#Preview {
    let incident = Incident(
        title: "Fall Protection Violation",
        descriptionText: "Worker observed without harness at height exceeding 2 meters on Site B scaffolding.",
        severity: .high,
        status: .open,
        reportedBy: "John Smith",
        location: "Site B - Block C",
        date: Date()
    )
    return NavigationStack {
        SafetyDetailView(incident: incident)
    }
}
