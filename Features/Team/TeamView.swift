import SwiftUI
import SwiftData

struct TeamView: View {
    @Query(sort: \Worker.name) private var workers: [Worker]
    @State private var showAddWorker = false
    @State private var searchText = ""
    
    var filteredWorkers: [Worker] {
        if searchText.isEmpty { return workers }
        return workers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.role.label.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    TextField("Search team members...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Team grid
                LazyVStack(spacing: 12) {
                    if filteredWorkers.isEmpty {
                        EmptyStateView(
                            icon: "person.3.fill",
                            title: "No Team Members",
                            message: "Add workers to build your construction team"
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredWorkers) { worker in
                            ModernWorkerCard(worker: worker)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Team")
        .toolbar {
            Button { showAddWorker = true } label: {
                Image(systemName: "plus")
                    .foregroundStyle(BuildTrackColors.primary)
            }
        }
        .sheet(isPresented: $showAddWorker) {
            WorkerFormView()
        }
    }
}

struct ModernWorkerCard: View {
    let worker: Worker
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(BuildTrackColors.primary.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: worker.role.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(BuildTrackColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                HStack(spacing: 6) {
                    Text(worker.role.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(BuildTrackColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(BuildTrackColors.primary.opacity(0.1))
                        .clipShape(Capsule())
                    
                    if !worker.phone.isEmpty {
                        Label(worker.phone, systemImage: "phone.fill")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            Circle()
                .fill(worker.isActive ? BuildTrackColors.success : BuildTrackColors.textTertiary)
                .frame(width: 10, height: 10)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

struct WorkerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var role: WorkerRole = .labourer
    @State private var phone = ""
    @State private var email = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Full Name", text: $name)
                    Picker("Role", selection: $role) {
                        ForEach(WorkerRole.allCases, id: \.self) { r in
                            Label(r.label, systemImage: r.icon).tag(r)
                        }
                    }
                }
                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("New Team Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let worker = Worker(
                            name: name,
                            role: role,
                            phone: phone,
                            email: email
                        )
                        modelContext.insert(worker)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
    }
}

#Preview {
    TeamView()
        .modelContainer(for: [Worker.self])
}
