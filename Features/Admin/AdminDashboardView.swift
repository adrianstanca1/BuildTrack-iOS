import SwiftUI

struct AdminDashboardView: View {
    @State private var viewModel = AdminDashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary)
                    .padding(.top)
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Users", value: "\(viewModel.stats?.totalUsers ?? 0)", icon: "person.3")
                        StatCard(title: "Projects", value: "\(viewModel.stats?.totalProjects ?? 0)", icon: "building.2")
                        StatCard(title: "Tasks", value: "\(viewModel.stats?.totalTasks ?? 0)", icon: "checklist")
                        StatCard(title: "Workers", value: "\(viewModel.stats?.totalWorkers ?? 0)", icon: "helmet")
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: AdminUsersView()) {
                        AdminRow(title: "Manage Users", icon: "person.crop.rectangle.stack")
                    }
                    
                    NavigationLink(destination: AdminProjectsView()) {
                        AdminRow(title: "All Projects", icon: "folder")
                    }
                    
                    NavigationLink(destination: AdminBillingView()) {
                        AdminRow(title: "Billing", icon: "creditcard")
                    }
                }
            }
        }
        .task {
            await viewModel.loadStats()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AdminRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}
