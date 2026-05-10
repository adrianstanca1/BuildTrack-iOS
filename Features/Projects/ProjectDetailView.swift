import SwiftUI
import SwiftData
struct ProjectDetailView: View {
    let project: Project
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                CardView {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.title2.bold())
                                Text(project.clientName)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge(status: project.status)
                        }
                        
                        // Progress
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Progress")
                                    .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(project.progress))%")
                                    .font(.caption.bold()).foregroundStyle(BuildTrackColors.primary)
                            }
                            ProgressView(value: project.progress, total: 100)
                                .tint(BuildTrackColors.primary)
                        }
                    }
                }
                
                // Budget details
                CardView {
                    SectionHeader(title: "Budget")
                    VStack(spacing: 12) {
                        DetailRow(label: "Total Budget", value: "$\(Int(project.budget).formatted())")
                        Divider()
                        DetailRow(label: "Spent to Date", value: "$\(Int(project.spentToDate).formatted())")
                        Divider()
                        DetailRow(
                            label: "Remaining",
                            value: "$\(max(0, Int(project.budget - project.spentToDate)).formatted())",
                            valueColor: project.spentToDate > project.budget ? .red : .green
                        )
                    }
                }
                
                // Location & Dates
                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(label: "Location", value: project.locationName)
                        Divider()
                        DetailRow(label: "Start Date", value: project.startDate.formatted(date: .abbreviated, time: .omitted))
                        if let endDate = project.endDate {
                            Divider()
                            DetailRow(label: "End Date", value: endDate.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                }
                
                // Description
                if !project.descriptionText.isEmpty {
                    CardView {
                        SectionHeader(title: "Description")
                        Text(project.descriptionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Actions
                VStack(spacing: 12) {
                    Button { showEdit = true } label: {
                        Label("Edit Project", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete Project", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Project Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            ProjectFormView(mode: .edit(project))
        }
        .confirmationDialog("Delete Project?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(project)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(project.name) and all associated data.")
        }
    }
}
