import SwiftUI
import SwiftData

struct BudgetListView: View {
    @Query(sort: \Budget.updatedAt, order: .reverse) private var budgets: [Budget]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddBudget = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(budgets) { budget in
                    BudgetRow(budget: budget)
                }
                .onDelete(perform: deleteBudget)
            }
            .listStyle(.plain)
            .navigationTitle("Budgets")
            .toolbar {
                Button { showAddBudget = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddBudget) {
                BudgetFormView()
            }
            .overlay {
                if budgets.isEmpty {
                    EmptyStateView(
                        icon: "sterlingsign.circle",
                        title: "No Budgets",
                        message: "Create a budget to track project costs"
                    )
                }
            }
        }
    }

    private func deleteBudget(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(budgets[index])
        }
    }
}

struct BudgetRow: View {
    let budget: Budget

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: budget.status)
            }

            ProgressView(value: budget.progress)
                .tint(budget.progress > 0.9 ? .red : budget.progress > 0.75 ? .orange : .blue)

            HStack {
                Text("Spent: \(formatCurrency(budget.totalSpent))")
                Spacer()
                Text("Budget: \(formatCurrency(budget.totalBudget))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = budget.currency
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
}

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var totalBudget = ""
    @State private var currency = "GBP"

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Total Budget", text: $totalBudget)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $currency) {
                        Text("GBP").tag("GBP")
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                    }
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let budget = Budget(
                            name: name,
                            totalBudget: Double(totalBudget) ?? 0,
                            currency: currency
                        )
                        modelContext.insert(budget)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    BudgetListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
