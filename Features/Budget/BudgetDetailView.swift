import SwiftUI
struct BudgetDetailView: View { let budget: Budget; var body: some View { Text("Budget: \(budget.name)").navigationTitle("Budget Detail") } }
