import SwiftUI
import SwiftData

// MARK: - Professional Safety View

struct SafetyView: View {
    @Query(sort: \Incident.date, order: .reverse) private var incidents: [Incident]
    @Query(sort: \Inspection.date, order: .reverse) private var inspections: [Inspection]
    @State private var selectedTab = 0
    @State private var showAddIncident = false
    @State private var showAddInspection = false
    @State private var selectedIncident: Incident?
    @State private var selectedInspection: Inspection?

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control with professional styling
            Picker("View", selection: $selectedTab) {
                Text("Incidents").tag(0)
                Text("Inspections").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
            .padding(.vertical, DesignTokens.Spacing.md)

            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    if selectedTab == 0 {
                        incidentsSection
                    } else {
                        inspectionsSection
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Safety")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    DesignTokens.Haptic.medium()
                    if selectedTab == 0 {
                        showAddIncident = true
                    } else {
                        showAddInspection = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(BuildTrackColors.primary)
                        .frame(width: DesignTokens.Spacing.minTapTarget, height: DesignTokens.Spacing.minTapTarget)
                        .background(BuildTrackColors.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibleTapTarget(label: selectedTab == 0 ? "Report incident" : "Add inspection")
            }
        }
        .sheet(isPresented: $showAddIncident) { IncidentFormView() }
        .sheet(isPresented: $showAddInspection) { InspectionFormView() }
        .sheet(item: $selectedIncident) { incident in
            NavigationStack {
                SafetyDetailView(incident: incident)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedIncident = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Incidents Section
    private var incidentsSection: some View {
        Group {
            if incidents.isEmpty {
                ProEmptyState(
                    icon: "shield.checkered",
                    title: "No Incidents",
                    message: "Report safety incidents to keep your team safe and compliant.",
                    actionTitle: "Report Incident"
                ) {
                    DesignTokens.Haptic.medium()
                    showAddIncident = true
                }
                .padding(.top, DesignTokens.Spacing.xl)
            } else {
                // Stats summary
                HStack(spacing: DesignTokens.Spacing.md) {
                    StatMiniCard(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(incidents.filter { $0.severity == .critical || $0.severity == .high }.count)",
                        label: "Critical",
                        color: BuildTrackColors.danger
                    )
                    StatMiniCard(
                        icon: "checkmark.shield.fill",
                        value: "\(incidents.filter { $0.incidentStatus == .resolved }.count)",
                        label: "Resolved",
                        color: BuildTrackColors.success
                    )
                    StatMiniCard(
                        icon: "shield.fill",
                        value: "\(incidents.count)",
                        label: "Total",
                        color: BuildTrackColors.primary
                    )
                }

                // Incidents list
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(Array(incidents.enumerated()), id: \.element.id) { index, incident in
                        IncidentCardPro(incident: incident)
                            .onTapGesture {
                                DesignTokens.Haptic.light()
                                selectedIncident = incident
                            }
                            .fadeIn(delay: Double(index) * 0.05)
                    }
                }
            }
        }
    }

    // MARK: - Inspections Section
    private var inspectionsSection: some View {
        Group {
            if inspections.isEmpty {
                ProEmptyState(
                    icon: "checklist.checked",
                    title: "No Inspections",
                    message: "Schedule safety inspections for your construction sites.",
                    actionTitle: "Add Inspection"
                ) {
                    DesignTokens.Haptic.medium()
                    showAddInspection = true
                }
                .padding(.top, DesignTokens.Spacing.xl)
            } else {
                // Stats summary
                HStack(spacing: DesignTokens.Spacing.md) {
                    StatMiniCard(
                        icon: "checkmark.circle.fill",
                        value: "\(inspections.filter { $0.result == .pass }.count)",
                        label: "Passed",
                        color: BuildTrackColors.success
                    )
                    StatMiniCard(
                        icon: "xmark.circle.fill",
                        value: "\(inspections.filter { $0.result == .fail }.count)",
                        label: "Failed",
                        color: BuildTrackColors.danger
                    )
                    StatMiniCard(
                        icon: "checklist",
                        value: "\(inspections.count)",
                        label: "Total",
                        color: BuildTrackColors.primary
                    )
                }

                // Inspections list
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(Array(inspections.enumerated()), id: \.element.id) { index, inspection in
                        InspectionCardPro(inspection: inspection)
                            .fadeIn(delay: Double(index) * 0.05)
                    }
                }
            }
        }
    }
}

// MARK: - Professional Incident Card

struct IncidentCardPro: View {
    let incident: Incident

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Severity icon
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(severityColor)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(incident.title)
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    ProBadge(text: incident.severity.label, color: severityColor)
                    ProBadge(text: incident.incidentStatus.label, color: statusColor)
                }

                if !incident.descriptionText.isEmpty {
                    Text(incident.descriptionText)
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    if !incident.location.isEmpty {
                        Label(incident.location, systemImage: "mappin")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }

                    Label(incident.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textTertiary)
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }

    private var severityColor: Color {
        BuildTrackColors.severityColor(incident.severity)
    }

    private var statusColor: Color {
        switch incident.incidentStatus {
        case .open: return BuildTrackColors.warning
        case .investigating: return BuildTrackColors.info
        case .resolved: return BuildTrackColors.success
        case .closed: return BuildTrackColors.textTertiary
        }
    }
}

// MARK: - Professional Inspection Card

struct InspectionCardPro: View {
    let inspection: Inspection

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Result icon
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: inspection.result == .pass ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(resultColor)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(inspection.title)
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                    .lineLimit(1)

                if !inspection.inspector.isEmpty {
                    Label(inspection.inspector, systemImage: "person")
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                }

                Label(inspection.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(BuildTrackColors.textTertiary)
            }

            Spacer()

            ProBadge(text: inspection.result.label, color: resultColor)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textTertiary)
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }

    private var resultColor: Color {
        inspection.result == .pass ? BuildTrackColors.success : BuildTrackColors.danger
    }
}

// MARK: - Forms (Professional)

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
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    ProTextField(title: "Title", icon: "exclamationmark.triangle", text: $title)
                    ProTextField(title: "Description", icon: "text.alignleft", text: $descriptionText)

                    ProPickerField(
                        title: "Severity",
                        selection: $severity,
                        options: IncidentSeverity.allCases,
                        display: { $0.label },
                        icon: "exclamationmark.circle"
                    )

                    ProTextField(title: "Reported By", icon: "person", text: $reportedBy)
                    ProTextField(title: "Location", icon: "mappin", text: $location)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Date")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                            .textCase(.uppercase)

                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }

                    Button {
                        DesignTokens.Haptic.success()
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
                    } label: {
                        Text("Report Incident")
                            .primaryButton()
                    }
                    .disabled(title.isEmpty)
                    .padding(.top, DesignTokens.Spacing.md)
                }
                .padding(DesignTokens.Spacing.sectionPadding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    ProTextField(title: "Title", icon: "checklist", text: $title)
                    ProTextField(title: "Inspector", icon: "person", text: $inspector)

                    ProPickerField(
                        title: "Result",
                        selection: $result,
                        options: InspectionResult.allCases,
                        display: { $0.label },
                        icon: "checkmark.circle"
                    )

                    ProTextField(title: "Notes", icon: "text.alignleft", text: $notes)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Date")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                            .textCase(.uppercase)

                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }

                    Button {
                        DesignTokens.Haptic.success()
                        let inspection = Inspection(
                            title: title,
                            inspector: inspector,
                            result: result,
                            date: date,
                            notes: notes
                        )
                        modelContext.insert(inspection)
                        dismiss()
                    } label: {
                        Text("Save Inspection")
                            .primaryButton()
                    }
                    .disabled(title.isEmpty)
                    .padding(.top, DesignTokens.Spacing.md)
                }
                .padding(DesignTokens.Spacing.sectionPadding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Professional Safety View") {
    SafetyView()
        .modelContainer(for: [Incident.self, Inspection.self])
}

// MARK: - Embedded Safety Detail View

@MainActor
struct SafetyDetailView: View {
    let incident: Incident
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProBadge(text: incident.severity.label, color: incident.severity == .high ? .red : incident.severity == .medium ? .orange : .gray)
                        ProBadge(text: incident.incidentStatus.label, color: incident.incidentStatus == .resolved ? .green : .blue)
                        Spacer()
                    }
                    
                    Text(incident.title)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)

                // Details Card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Details")
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.top, DesignTokens.Spacing.md)
                    
                    DetailRowPro(label: "Severity", value: incident.severity.label, icon: "exclamationmark.triangle")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Status", value: incident.incidentStatus.label, icon: "checkmark.circle")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Date", value: incident.date.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
                    if !incident.location.isEmpty {
                        Divider().padding(.leading, 44)
                        DetailRowPro(label: "Location", value: incident.location, icon: "mappin")
                    }
                    if !incident.reportedBy.isEmpty {
                        Divider().padding(.leading, 44)
                        DetailRowPro(label: "Reported By", value: incident.reportedBy, icon: "person")
                    }
                }
                .professionalCard(padding: DesignTokens.Spacing.sm)
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)

                // Description
                if !incident.descriptionText.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Description")
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.textSecondary)
                        
                        Text(incident.descriptionText)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .professionalCard()
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                }

                // Actions
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        showEditSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Spacing.buttonHeight)
                        .background(BuildTrackColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                    
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Spacing.buttonHeight)
                        .background(BuildTrackColors.danger)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Incident Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                IncidentFormView(incident: incident)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showEditSheet = false }
                        }
                    }
            }
        }
        .alert("Delete Incident?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(incident)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This incident will be permanently deleted.")
        }
    }
}
