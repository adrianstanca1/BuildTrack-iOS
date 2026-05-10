import SwiftUI
import SwiftData

struct RFIDetailView: View {
    let rfi: RFI
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RFIViewModel()
    @State private var showResponseSheet = false
    @State private var responseText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                detailSection
                if !rfi.response.isEmpty { responseSection }
                actionButtons
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("RFI Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.deleteRFI(rfi, context: modelContext)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showResponseSheet) {
            ResponseSheet(rfi: rfi, responseText: $responseText)
        }
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RFIStatusBadge(status: rfi.status)
                Spacer()
                PriorityBadge(text: rfi.priority.label, color: priorityColor(rfi.priority))
            }
            Text(rfi.title)
                .font(.title2.weight(.bold))
            Text(rfi.descriptionText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(label: "Assigned To", value: rfi.assignedTo.isEmpty ? "Unassigned" : rfi.assignedTo, icon: "person")
            DetailRow(label: "Created", value: rfi.createdAt.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
            if let respondedAt = rfi.respondedAt {
                DetailRow(label: "Responded", value: respondedAt.formatted(date: .abbreviated, time: .shortened), icon: "checkmark.circle")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response")
                .font(.headline)
            Text(rfi.response)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var actionButtons: some View {
        VStack(spacing: 12) {
            if rfi.status == .draft {
                Button { viewModel.updateStatus(rfi, to: .submitted, context: modelContext) } label: {
                    Label("Submit RFI", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            if rfi.status == .submitted || rfi.status == .underReview {
                Button { showResponseSheet = true } label: {
                    Label("Add Response", systemImage: "text.bubble.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            if rfi.status == .approved || rfi.status == .rejected {
                Button { viewModel.updateStatus(rfi, to: .closed, context: modelContext) } label: {
                    Label("Close RFI", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    func statusColor(_ status: RFIStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .closed: return .gray
        }
    }

    func priorityColor(_ priority: RFIPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct ResponseSheet: View {
    let rfi: RFI
    @Binding var responseText: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RFIViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Response") {
                    TextEditor(text: $responseText)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Add Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addResponse(rfi, response: responseText, context: modelContext)
                        dismiss()
                    }
                    .disabled(responseText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
