import SwiftUI
import SwiftData

struct InvoiceFormView: View {
    var invoice: Invoice?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var invoiceNumber: String = ""
    @State private var vendor: String = ""
    @State private var amount: String = ""
    @State private var status: InvoiceStatus = .draft
    @State private var dueDate: Date = Date().addingTimeInterval(86400 * 30)
    @State private var hasDueDate = false
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    init(invoice: Invoice? = nil) {
        self.invoice = invoice
        _invoiceNumber = State(initialValue: invoice?.invoiceNumber ?? "")
        _vendor = State(initialValue: invoice?.vendor ?? "")
        _amount = State(initialValue: invoice != nil ? String(invoice!.amount) : "")
        _status = State(initialValue: invoice?.status ?? .draft)
        _dueDate = State(initialValue: invoice?.dueDate ?? Date().addingTimeInterval(86400 * 30))
        _hasDueDate = State(initialValue: invoice?.dueDate != nil)
    }

    var isEditing: Bool { invoice != nil }
    var isValid: Bool {
        !invoiceNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !amount.isEmpty &&
        Double(amount) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Invoice Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invoice Number").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. INV-001", text: $invoiceNumber)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vendor").font(.caption).foregroundStyle(.secondary)
                        TextField("Vendor name", text: $vendor)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount (£)").font(.caption).foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Status & Dates") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status").font(.caption).foregroundStyle(.secondary)
                        Picker("Status", selection: $status) {
                            ForEach(InvoiceStatus.allCases, id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Project") {
                    Button {
                        showProjectPicker = true
                    } label: {
                        HStack {
                            Text("Project")
                            Spacer()
                            if let project = selectedProject {
                                Text(project.name)
                                    .foregroundStyle(BuildTrackColors.primary)
                                Image(systemName: "building.2.fill")
                                    .foregroundStyle(BuildTrackColors.primary)
                            } else {
                                Text("None")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Invoice" : "New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showProjectPicker) {
                ProjectPicker(selectedProject: $selectedProject, projects: projects)
            }
        }
    }

    private func save() {
        let trimmedNumber = invoiceNumber.trimmingCharacters(in: .whitespaces)
        let amt = Double(amount) ?? 0

        if let invoice {
            invoice.invoiceNumber = trimmedNumber
            invoice.vendor = vendor
            invoice.amount = amt
            invoice.status = status
            invoice.dueDate = hasDueDate ? dueDate : nil
            invoice.projectId = selectedProject?.id
            invoice.updatedAt = Date()
        } else {
            let newInvoice = Invoice(
                invoiceNumber: trimmedNumber,
                vendor: vendor,
                amount: amt,
                status: status,
                dueDate: hasDueDate ? dueDate : nil,
                projectId: selectedProject?.id
            )
            modelContext.insert(newInvoice)
        }
        try? modelContext.save()
    }
}

#Preview {
    InvoiceFormView()
        .modelContainer(for: [Invoice.self, Project.self])
}
