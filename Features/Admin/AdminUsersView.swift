import SwiftUI

struct AdminUsersView: View {
    @State private var viewModel = AdminUsersViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                ForEach(viewModel.users) { user in
                    UserRow(user: user)
                }
            }
        }
        .navigationTitle("Users")
        .task {
            await viewModel.loadUsers()
        }
        .refreshable {
            await viewModel.loadUsers()
        }
    }
}

struct UserRow: View {
    let user: AdminUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.email)
                .font(.headline)
            Text(user.role)
                .font(.caption)
                .foregroundColor(.secondary)
            if let company = user.companyName {
                Text(company)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
