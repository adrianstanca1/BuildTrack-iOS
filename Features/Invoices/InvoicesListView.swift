import SwiftUI
import SwiftData

struct InvoicesListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InvoiceViewModel()
    @State private var showNewInvoice = false
    @State private var searchQuery = ""
    @State private var statusFilter: InvoiceStatus? = nil

    var filteredInvoices: [Invoice] {
        var result = viewModel.invoices
        if let filter = statusFilter {
            result = result.filter { $0.status == filter }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.invoiceNumber.localizedCaseInsensitiveContains(searchQuery) ||
                $0.vendor.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search
                SearchBar(query: $searchQuery, placeholder: "Search invoices...")

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                        ForEach(InvoiceStatus.allCases, id: \.self) { status in
                            FilterChip(
                                label: status.label,
                                isSelected: statusFilter == status
                            ) { statusFilter = status }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Summary card
                SummaryCard(
                    title: "Outstanding",
                    value: String(format: "£%.2f", viewModel.totalOutstanding),
                    subtitle: "\(viewModel.overdueInvoices.count) overdue",
                    color: .red
                )
                .padding(.horizontal, 16)

                // List
                LazyVStack(spacing: 12) {
                    ForEach(filteredInvoices) { invoice in
                        NavigationLink {
                            InvoiceDetailView(invoice: invoice)
                        } label: {
                            InvoiceRowCard(invoice: invoice)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                if filteredInvoices.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Invoices",
                        message: "Create your first invoice to track payments."
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Invoices")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewInvoice = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
        .sheet(isPresented: $showNewInvoice) {
            InvoiceFormView()
        }
        .onAppear {
            viewModel.fetchInvoices(context: modelContext)
        }
    }
}

struct InvoiceRowCard: View {
    let invoice: Invoice

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.invoiceNumber)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)

                if !invoice.vendor.isEmpty {
                    Text(invoice.vendor)
                        .font(.caption)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                }

                HStack(spacing: 6) {
                    Text(invoice.status.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.12))
                        .clipShape(Capsule())

                    if let due = invoice.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "£%.2f", invoice.amount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var statusColor: Color {
        switch invoice.status {
        case .draft: return .gray
        case .pending: return .blue
        case .approved: return .green
        case .paid: return .green
        case .overdue: return .red
        }
    }
}

#Preview {
    InvoicesListView()
        .modelContainer(for: [Invoice.self])
}
