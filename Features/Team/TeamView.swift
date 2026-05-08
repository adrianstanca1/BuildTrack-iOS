import SwiftUI
import SwiftData

struct TeamView: View {
    @Query(sort: \Worker.name) private var workers: [Worker]
    @State private var searchText = ""
    @State private var roleFilter: WorkerRole?
    @State private var showAddWorker = false
    
    var filteredWorkers: [Worker] {
        var result = workers
        if let r = roleFilter { result = result.filter { $0.role == r } }
        if !searchText.isEmpty { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return result
    }
    
    var roleBreakdown: [(WorkerRole, Int)] {
        WorkerRole.allCases.map { role in (role, workers.filter { $0.role == role && $0.isActive }.count) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Role summary
                CardView {
                    SectionHeader(title: "Role Breakdown")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(roleBreakdown, id: \.0) { role, count in
                            HStack {
                                Image(systemName: role.icon).foregroundStyle(BuildTrackColors.primary)
                                Text("\(count) \(role.label)").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Workers list
                LazyVStack(spacing: 12) {
                    if filteredWorkers.isEmpty {
                        EmptyStateView(icon: "person.3", title: "No Workers", message: "Add team members")
                    }
                    ForEach(filteredWorkers) { worker in
                        WorkerCard(worker: worker)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search workers...")
        .navigationTitle("Team")
        .toolbar { Button { showAddWorker = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $showAddWorker) { WorkerFormView() }
    }
}

struct WorkerCard: View {
    let worker: Worker
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(BuildTrackColors.primary.opacity(0.12)).frame(width: 44, height: 44)
                Text(String(worker.name.prefix(2))).font(.headline).foregroundStyle(BuildTrackColors.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.name).font(.subheadline.weight(.medium))
                Text(worker.role.label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !worker.certifications.isEmpty {
                Text("\(worker.certifications.count) certs").font(.caption2).foregroundStyle(.blue)
            }
            Circle().fill(worker.isActive ? Color.green : Color.gray).frame(width: 8, height: 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct WorkerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var role: WorkerRole = .labourer
    @State private var phone = ""
    @State private var email = ""
    @State private var certText = ""
    @State private var certifications: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Full Name", text: $name) }
                Section { Picker("Role", selection: $role) { ForEach(WorkerRole.allCases, id: \.self) { Text($0.label).tag($0) } } }
                Section("Contact") { TextField("Phone", text: $phone).keyboardType(.phonePad); TextField("Email", text: $email).keyboardType(.emailAddress) }
                Section("Certifications") {
                    HStack {
                        TextField("Add certification", text: $certText)
                        Button("Add") {
                            if !certText.isEmpty { certifications.append(certText); certText = "" }
                        }
                    }
                    ForEach(certifications, id: \.self) { cert in
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
                            Text(cert).font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Add Worker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let worker = Worker(name: name, role: role, phone: phone, email: email, certifications: certifications)
                        modelContext.insert(worker)
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TeamView().modelContainer(for: [Worker.self])
}
