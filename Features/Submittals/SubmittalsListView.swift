import SwiftUI
import SwiftData

struct SubmittalsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SubmittalViewModel()
    @State private var showNewSubmittal = false
    @State private var searchQuery = ""
    @State private var statusFilter: SubmittalStatus? = nil

    var filteredSubmittals: [Submittal] {
        var result = viewModel.submittals
        if let filter = statusFilter {
            result = result.filter { $0.status == filter }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.descriptionText.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SearchBar(query: $searchQuery, placeholder: "Search submittals...")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                        ForEach(SubmittalStatus.allCases, id: \.self) { status in
                            FilterChip(
                                label: status.label,
                                isSelected: statusFilter == status
                            ) { statusFilter = status }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                SummaryCard(
                    title: "Pending Review",
                    value: "\(viewModel.pendingCount)",
                    subtitle: "Awaiting approval",
                    color: .orange
                )
                .padding(.horizontal, 16)

                LazyVStack(spacing: 12) {
                    ForEach(filteredSubmittals) { submittal in
                        NavigationLink {
                            SubmittalDetailView(submittal: submittal)
                        } label: {
                            SubmittalRowCard(submittal: submittal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                if filteredSubmittals.isEmpty {
                    EmptyStateView(
                        icon: "doc.on.doc",
                        title: "No Submittals",
                        message: "Create your first submittal to track shop drawings and materials."
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Submittals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewSubmittal = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
        .sheet(isPresented: $showNewSubmittal) {
            SubmittalFormView()
        }
        .onAppear {
            viewModel.fetchSubmittals(context: modelContext)
        }
    }
}

struct SubmittalRowCard: View {
    let submittal: Submittal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(submittal.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)

                HStack(spacing: 6) {
                    Text(submittal.status.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.12))
                        .clipShape(Capsule())

                    Text(submittal.type.label)
                        .font(.caption2)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }

                if !submittal.submittedBy.isEmpty {
                    Label(submittal.submittedBy, systemImage: "person")
                        .font(.caption2)
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
            }

            Spacer()

            Text(submittal.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(BuildTrackColors.textTertiary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var statusColor: Color {
        switch submittal.status {
        case .draft: return .gray
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .closed: return .gray
        }
    }
}

#Preview {
    SubmittalsListView()
        .modelContainer(for: [Submittal.self])
}
