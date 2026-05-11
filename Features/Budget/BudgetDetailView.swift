import SwiftUI
import SwiftData

struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEditBudget = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Card
                VStack(spacing: 16) {
                    Text(budget.name)
                        .font(.title2.weight(.bold))

                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 12)
                            .frame(width: 140, height: 140)

                        Circle()
                            .trim(from: 0, to: budget.progress)
                            .stroke(
                                budget.progress > 0.9 ? Color.red : budget.progress > 0.75 ? Color.orange : Color.blue,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("\(Int(budget.progress * 100))%")
                                .font(.title3.weight(.bold))
                            Text("spent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text(formatCurrency(budget.totalSpent))
                                .font(.headline)
                                .foregroundStyle(.red)
                            Text("Spent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 4) {
                            Text(formatCurrency(budget.totalBudget))
                                .font(.headline)
                                .foregroundStyle(.blue)
                            Text("Budget")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 4) {
                            Text(formatCurrency(budget.totalBudget - budget.totalSpent))
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text("Remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)

                // Status
                HStack {
                    Text("Status")
                        .font(.headline)
                    Spacer()
                    Text(budget.status.label)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(budget.status.color))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Categories
                if let categories = budget.categories, !categories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline)
                            .padding(.horizontal, 16)

                        ForEach(categories) { category in
                            BudgetCategoryRow(category: category)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Budget Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditBudget = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditBudget) {
            BudgetFormView(budget: budget)
        }
        .alert("Delete Budget?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(budget)
                dismiss()
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = budget.currency
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
}

struct BudgetCategoryRow: View {
    let category: BudgetCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int((category.spent / max(category.allocated, 1)) * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(category.spent / max(category.allocated, 1), 1.0))
                .tint(category.spent > category.allocated ? .red : .blue)

            HStack {
                Text("Allocated: \(formatCurrency(category.allocated))")
                    .font(.caption)
                Spacer()
                Text("Spent: \(formatCurrency(category.spent))")
                    .font(.caption)
                    .foregroundStyle(category.spent > category.allocated ? .red : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
    }
}

#Preview {
    NavigationStack {
        BudgetDetailView(budget: Budget(name: "Foundation Works", totalBudget: 500000, totalSpent: 320000))
    }
}
