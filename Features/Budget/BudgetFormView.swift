import SwiftUI
import SwiftData

struct BudgetFormView: View {
    var budget: Budget?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var budgetDescription = ""
    @State private var totalBudget = ""
    @State private var currency = "GBP"
    @State private var status: BudgetStatus = .draft
    var isEditing: Bool { budget != nil }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(budget: Budget? = nil) {
        self.budget = budget
        _name = State(initialValue: budget?.name ?? "")
        _budgetDescription = State(initialValue: budget?.budgetDescription ?? "")
        _totalBudget = State(initialValue: budget.map { String($0.totalBudget) } ?? "")
        _currency = State(initialValue: budget?.currency ?? "GBP")
        _status = State(initialValue: budget?.status ?? .draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $budgetDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Budget") {
                    TextField("Total Budget", text: $totalBudget)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $currency) {
                        Text("GBP").tag("GBP")
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(BudgetStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isEditing ? "Edit Budget" : "New Budget")
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
        if let budget {
            budget.name = name
            budget.budgetDescription = budgetDescription
            budget.totalBudget = Double(totalBudget) ?? 0
            budget.currency = currency
            budget.status = status
            budget.updatedAt = Date()
        } else {
            let newBudget = Budget(
                name: name,
                budgetDescription: budgetDescription,
                totalBudget: Double(totalBudget) ?? 0,
                currency: currency,
                status: status
            )
            modelContext.insert(newBudget)
        }
        dismiss()
    }
}
