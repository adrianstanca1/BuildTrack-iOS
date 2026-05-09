import SwiftUI

struct AdminProjectsView: View {
    @State private var viewModel = AdminProjectsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                ForEach(viewModel.projects) { project in
                    ProjectAdminRow(project: project)
                }
            }
        }
        .navigationTitle("All Projects")
        .task {
            await viewModel.loadProjects()
        }
        .refreshable {
            await viewModel.loadProjects()
        }
    }
}

struct ProjectAdminRow: View {
    let project: AdminProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.headline)
            Text(project.status)
                .font(.caption)
                .foregroundColor(statusColor)
            if let user = project.userEmail {
                Text("Owner: \(user)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    var statusColor: Color {
        switch project.status {
        case "active": return .green
        case "completed": return .blue
        case "planning": return .orange
        case "on-hold": return .yellow
        default: return .gray
        }
    }
}
