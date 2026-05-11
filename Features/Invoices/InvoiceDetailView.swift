import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    let invoice: Invoice
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
                                Text(invoice.invoiceNumber)
                                    .font(.title2.bold())
                                if !invoice.vendor.isEmpty {
                                    Label(invoice.vendor, systemImage: "person.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            InvoiceStatusBadge(status: invoice.status)
                        }

                        HStack {
                            Text(String(format: "£%.2f", invoice.amount))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(BuildTrackColors.primary)
                            Spacer()
                        }
                    }
                }

                if !invoice.vendor.isEmpty {
                    CardView {
                        SectionHeader(title: "Vendor")
                        Text(invoice.vendor)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Created", value: invoice.createdAt.formatted(date: .abbreviated, time: .shortened))
                        if let due = invoice.dueDate {
                            Divider()
                            DetailRow(icon: "calendar.badge.clock", label: "Due Date", value: due.formatted(date: .abbreviated, time: .omitted))
                        }
                        Divider()
                        DetailRow(icon: "sterlingsign.circle", label: "Amount", value: String(format: "£%.2f", invoice.amount))
                    }
                }

                VStack(spacing: 12) {
                    if invoice.status == .draft || invoice.status == .pending {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                invoice.status = .approved
                                invoice.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(BuildTrackColors.success)
                    }

                    if invoice.status == .approved {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                invoice.status = .paid
                                invoice.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Mark Paid", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(BuildTrackColors.primary)
                    }

                    Button { showEdit = true } label: {
                        Label("Edit Invoice", systemImage: "pencil")
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
        .navigationTitle("Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            InvoiceFormView(invoice: invoice)
        }
        .confirmationDialog("Delete Invoice?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(invoice)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(invoice.invoiceNumber).")
        }
    }
}

struct InvoiceStatusBadge: View {
    let status: InvoiceStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .draft: return .gray
        case .pending: return .blue
        case .approved: return .green
        case .paid: return .green
        case .overdue: return .red
        }
    }
}

#Preview {
    InvoiceDetailView(invoice: Invoice(invoiceNumber: "INV-001", vendor: "Acme Supplies", amount: 2500))
        .modelContainer(for: [Invoice.self])
}
