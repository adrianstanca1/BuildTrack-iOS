import SwiftUI
import SwiftData

struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(budget.name)
                                    .font(.title2.bold())
                                Text(budget.currency)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            BudgetStatusBadge(status: budget.status)
                        }
                    }
                }

                if budget.totalBudget > 0 {
                    CardView {
                        SectionHeader(title: "Budget")
                        VStack(spacing: 12) {
                            DetailRow(icon: "creditcard", label: "Total", value: formatCurrency(budget.totalBudget))
                            Divider()
                            DetailRow(icon: "arrow.down.circle", label: "Spent", value: formatCurrency(budget.totalSpent))
                            Divider()
                            DetailRow(icon: "banknote", label: "Remaining", value: formatCurrency(max(0, budget.totalBudget - budget.totalSpent)), valueColor: remainingColor)
                            Divider()
                            DetailRow(icon: "chart.pie", label: "Utilisation", value: String(format: "%.1f%%", budget.totalBudget > 0 ? (budget.totalSpent / budget.totalBudget) * 100 : 0))
                        }

                        if budget.totalBudget > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Progress")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(Int(min(budget.totalSpent / budget.totalBudget, 1.0) * 100))%")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(remainingColor)
                                }
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color(.systemGray5)).frame(height: 6)
                                        let ratio = min(budget.totalSpent / budget.totalBudget, 1.0)
                                        Capsule().fill(remainingColor).frame(width: max(geometry.size.width * CGFloat(ratio), 4), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(.top, 8)
                        }
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Created", value: budget.createdAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        DetailRow(icon: "pencil", label: "Updated", value: budget.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                VStack(spacing: 12) {
                    Button { showEdit = true } label: {
                        Label("Edit Budget", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            BudgetFormView(budget: budget)
        }
        .confirmationDialog("Delete Budget?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(budget)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(budget.name).")
        }
    }

    private var remainingColor: Color {
        guard budget.totalBudget > 0 else { return .secondary }
        let ratio = budget.totalSpent / budget.totalBudget
        if ratio < 0.6 { return .green }
        else if ratio < 0.85 { return .orange }
        else { return .red }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = budget.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
    }
}

struct BudgetStatusBadge: View {
    let status: BudgetStatus
    var color: Color {
        switch status {
        case .draft: return .gray
        case .approved: return .green
        case .inProgress: return .blue
        case .overBudget: return .red
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    BudgetDetailView(budget: Budget(name: "Q3 Renovation", totalBudget: 500000, currency: "GBP"))
        .modelContainer(for: [Budget.self])
}
