import SwiftUI
import SwiftData

// MARK: - Professional Invoices List View

struct InvoicesListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InvoicesListViewModel()
    @State private var showNewInvoice = false
    @State private var searchQuery = ""
    @State private var statusFilter: InvoiceStatus? = nil
    @State private var selectedInvoice: Invoice?

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
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Search Bar
                    ProSearchBar(query: $searchQuery, placeholder: "Search invoices...")
                        .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                        .fadeIn(delay: 0)

                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ProFilterChip(label: "All", isSelected: statusFilter == nil) {
                                DesignTokens.Haptic.light()
                                statusFilter = nil
                            }
                            ForEach(InvoiceStatus.allCases, id: \.self) { status in
                                ProFilterChip(label: status.label, isSelected: statusFilter == status) {
                                    DesignTokens.Haptic.light()
                                    statusFilter = status
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    }
                    .fadeIn(delay: 0.05)

                    // Stats Row
                    HStack(spacing: DesignTokens.Spacing.md) {
                        StatMiniCard(
                            icon: "doc.text.fill",
                            value: "\(viewModel.invoices.count)",
                            label: "Total",
                            color: BuildTrackColors.primary
                        )
                        StatMiniCard(
                            icon: "sterlingsign.circle.fill",
                            value: String(format: "£%.0f", viewModel.totalOutstanding),
                            label: "Outstanding",
                            color: BuildTrackColors.warning
                        )
                        StatMiniCard(
                            icon: "exclamationmark.triangle.fill",
                            value: "\(viewModel.overdueInvoices.count)",
                            label: "Overdue",
                            color: BuildTrackColors.danger
                        )
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.1)

                    // Invoices List
                    if filteredInvoices.isEmpty {
                        ProEmptyState(
                            icon: "doc.text",
                            title: "No Invoices",
                            message: "Create your first invoice to track payments.",
                            action: { showNewInvoice = true }
                        )
                        .padding(.top, DesignTokens.Spacing.xl)
                        .fadeIn(delay: 0.15)
                    } else {
                        LazyVStack(spacing: DesignTokens.Spacing.md) {
                            ForEach(filteredInvoices) { invoice in
                                InvoiceCardPro(invoice: invoice)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        DesignTokens.Haptic.medium()
                                        selectedInvoice = invoice
                                    }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                        .fadeIn(delay: 0.15)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        DesignTokens.Haptic.medium()
                        showNewInvoice = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(BuildTrackColors.primary)
                            .frame(width: 36, height: 36)
                            .background(BuildTrackColors.primary.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showNewInvoice) {
                NavigationStack {
                    InvoiceFormView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showNewInvoice = false }
                            }
                        }
                }
            }
            .sheet(item: $selectedInvoice) { invoice in
                NavigationStack {
                    InvoiceDetailView(invoice: invoice)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { selectedInvoice = nil }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Professional Invoice Card

struct InvoiceCardPro: View {
    let invoice: Invoice

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header
            HStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(invoice.invoiceNumber)
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    Text(invoice.vendor)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(String(format: "£%.2f", invoice.amount))
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
            }
            
            // Status and Date
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(invoice.status.label)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(statusColor)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    Text(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(BuildTrackColors.border, lineWidth: 0.5)
        )
    }
    
    private var statusColor: Color {
        switch invoice.status {
        case .draft: return BuildTrackColors.textTertiary
        case .sent: return BuildTrackColors.info
        case .paid: return BuildTrackColors.success
        case .overdue: return BuildTrackColors.danger
        case .cancelled: return BuildTrackColors.textTertiary
        }
    }
}

// MARK: - Invoice Form View (Placeholder)

struct InvoiceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var invoiceNumber = ""
    @State private var vendor = ""
    @State private var amount = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(BuildTrackColors.primary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(BuildTrackColors.primary)
                    }
                    
                    Text("New Invoice")
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                }
                .padding(DesignTokens.Spacing.lg)
                .professionalCard()
                
                VStack(spacing: 0) {
                    ProTextField(title: "Invoice Number", text: $invoiceNumber, icon: "number", placeholder: "INV-001")
                    Divider().padding(.leading, 44)
                    ProTextField(title: "Vendor", text: $vendor, icon: "building", placeholder: "Vendor name")
                    Divider().padding(.leading, 44)
                    ProTextField(title: "Amount", text: $amount, icon: "sterlingsign", placeholder: "0.00", keyboardType: .decimalPad)
                }
                .professionalCard(padding: DesignTokens.Spacing.sm)
                
                Button {
                    DesignTokens.Haptic.success()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Create Invoice")
                    }
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(BuildTrackColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("New Invoice")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Invoice Detail View (Placeholder)

struct InvoiceDetailView: View {
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(statusColor)
                    }
                    
                    Text(invoice.invoiceNumber)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    ProBadge(text: invoice.status.label, color: statusColor)
                }
                .padding(DesignTokens.Spacing.lg)
                .professionalCard()
                
                // Details
                VStack(alignment: .leading, spacing: 0) {
                    DetailRowPro(label: "Vendor", value: invoice.vendor, icon: "building")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Amount", value: String(format: "£%.2f", invoice.amount), icon: "sterlingsign")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Due Date", value: invoice.dueDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Status", value: invoice.status.label, icon: "checkmark.circle")
                }
                .professionalCard(padding: 0)
                
                // Actions
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        DesignTokens.Haptic.medium()
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(BuildTrackColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Invoice Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
    
    private var statusColor: Color {
        switch invoice.status {
        case .draft: return BuildTrackColors.textTertiary
        case .sent: return BuildTrackColors.info
        case .paid: return BuildTrackColors.success
        case .overdue: return BuildTrackColors.danger
        case .cancelled: return BuildTrackColors.textTertiary
        }
    }
}

// MARK: - View Model

@MainActor
final class InvoicesListViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var totalOutstanding: Double = 0
    @Published var overdueInvoices: [Invoice] = []
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        invoices = [
            Invoice(invoiceNumber: "INV-001", vendor: "ABC Construction", amount: 5000, status: .paid, dueDate: Date()),
            Invoice(invoiceNumber: "INV-002", vendor: "XYZ Supplies", amount: 3200, status: .sent, dueDate: Date().addingTimeInterval(86400 * 7)),
            Invoice(invoiceNumber: "INV-003", vendor: "Steel Works Ltd", amount: 8500, status: .overdue, dueDate: Date().addingTimeInterval(-86400 * 5))
        ]
        totalOutstanding = invoices.filter { $0.status != .paid }.reduce(0) { $0 + $1.amount }
        overdueInvoices = invoices.filter { $0.status == .overdue }
    }
}

extension InvoiceStatus {
    var label: String {
        switch self {
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
        }
    }
}

#Preview("Professional Invoices") {
    InvoicesListView()
}
