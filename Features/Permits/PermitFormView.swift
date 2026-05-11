import SwiftUI
import SwiftData

struct PermitFormView: View {
    var permit: Permit?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var permitNumber = ""
    @State private var permitType = ""
    @State private var authority = ""
    @State private var status: PermitStatus = .applied
    @State private var issueDate = Date()
    @State private var expiryDate = Date().addingTimeInterval(365 * 86400)
    @State private var permitDescription = ""
    var isEditing: Bool { permit != nil }
    var isValid: Bool { !permitNumber.trimmingCharacters(in: .whitespaces).isEmpty }

    init(permit: Permit? = nil) {
        self.permit = permit
        _permitNumber = State(initialValue: permit?.permitNumber ?? "")
        _permitType = State(initialValue: permit?.permitType ?? "")
        _authority = State(initialValue: permit?.authority ?? "")
        _status = State(initialValue: permit?.status ?? .applied)
        _issueDate = State(initialValue: permit?.issueDate ?? Date())
        _expiryDate = State(initialValue: permit?.expiryDate ?? Date().addingTimeInterval(365 * 86400))
        _permitDescription = State(initialValue: permit?.permitDescription ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Permit Number", text: $permitNumber)
                    TextField("Type", text: $permitType)
                    TextField("Authority", text: $authority)
                }
                Section("Dates") {
                    DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(PermitStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Description") {
                    TextField("Description", text: $permitDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Permit" : "New Permit")
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
        if let permit {
            permit.permitNumber = permitNumber
            permit.permitType = permitType
            permit.authority = authority
            permit.status = status
            permit.issueDate = issueDate
            permit.expiryDate = expiryDate
            permit.permitDescription = permitDescription
            permit.updatedAt = Date()
        } else {
            let newPermit = Permit(
                permitNumber: permitNumber,
                permitType: permitType,
                authority: authority,
                status: status,
                issueDate: issueDate,
                expiryDate: expiryDate,
                permitDescription: permitDescription
            )
            modelContext.insert(newPermit)
        }
        dismiss()
    }
}
