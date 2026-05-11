import SwiftUI
import SwiftData

struct EquipmentFormView: View {
    var equipment: Equipment?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var equipmentType = ""
    @State private var make = ""
    @State private var model = ""
    @State private var serialNumber = ""
    @State private var status: EquipmentStatus = .available
    @State private var location = ""
    @State private var hoursUsed = ""
    @State private var notes = ""
    var isEditing: Bool { equipment != nil }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(equipment: Equipment? = nil) {
        self.equipment = equipment
        _name = State(initialValue: equipment?.name ?? "")
        _equipmentType = State(initialValue: equipment?.equipmentType ?? "")
        _make = State(initialValue: equipment?.make ?? "")
        _model = State(initialValue: equipment?.model ?? "")
        _serialNumber = State(initialValue: equipment?.serialNumber ?? "")
        _status = State(initialValue: equipment?.status ?? .available)
        _location = State(initialValue: equipment?.location ?? "")
        _hoursUsed = State(initialValue: equipment.map { String($0.hoursUsed) } ?? "")
        _notes = State(initialValue: equipment?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Type", text: $equipmentType)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Serial Number", text: $serialNumber)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(EquipmentStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    TextField("Location", text: $location)
                    TextField("Hours Used", text: $hoursUsed)
                        .keyboardType(.decimalPad)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Equipment" : "New Equipment")
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
        if let equipment {
            equipment.name = name
            equipment.equipmentType = equipmentType
            equipment.make = make
            equipment.model = model
            equipment.serialNumber = serialNumber
            equipment.status = status
            equipment.location = location
            equipment.hoursUsed = Double(hoursUsed) ?? 0
            equipment.notes = notes
            equipment.updatedAt = Date()
        } else {
            let newEquipment = Equipment(
                name: name,
                equipmentType: equipmentType,
                make: make,
                model: model,
                serialNumber: serialNumber,
                status: status,
                location: location,
                hoursUsed: Double(hoursUsed) ?? 0,
                notes: notes
            )
            modelContext.insert(newEquipment)
        }
        dismiss()
    }
}
