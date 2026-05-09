import SwiftUI
import MapKit

// MARK: - Map View (Redesigned)

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedProject: Project?
    @State private var showProjectSheet = false
    
    var body: some View {
        Map(position: $cameraPosition) {
            // Project markers will be added here
            // For now, show a default region
        }
        .mapStyle(.standard)
        .navigationTitle("Site Map")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetCamera()
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
        .sheet(isPresented: $showProjectSheet) {
            if let project = selectedProject {
                ProjectDetailSheet(project: project)
            }
        }
    }
    
    private func resetCamera() {
        cameraPosition = .automatic
    }
}

struct ProjectDetailSheet: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(project.name)
                            .font(.title2.bold())
                            .foregroundStyle(BuildTrackColors.textPrimary)
                        
                        if !project.locationName.isEmpty {
                            Label(project.locationName, systemImage: "mappin.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(BuildTrackColors.primary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Status
                    HStack(spacing: 8) {
                        StatusBadge(status: project.status)
                        Text("\(Int(project.progress * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(BuildTrackColors.border)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(BuildTrackColors.statusColor(project.status))
                                .frame(width: geometry.size.width * CGFloat(project.progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                    
                    // Details
                    VStack(spacing: 16) {
                        DetailRow(icon: "calendar", label: "Start Date", value: project.startDate.formatted(date: .long, time: .omitted))
                        
                        if let endDate = project.endDate {
                            DetailRow(icon: "calendar.badge.clock", label: "End Date", value: endDate.formatted(date: .long, time: .omitted))
                        }
                        
                        DetailRow(icon: "sterlingsign.circle", label: "Budget", value: formatCurrency(project.budget))
                        
                        if project.spentToDate > 0 {
                            DetailRow(icon: "creditcard", label: "Spent", value: formatCurrency(project.spentToDate))
                        }
                        
                        if !project.clientName.isEmpty {
                            DetailRow(icon: "building.2", label: "Client", value: project.clientName)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Project Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 32, height: 32)
                .background(BuildTrackColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(BuildTrackColors.textTertiary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BuildTrackColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MapView()
}
