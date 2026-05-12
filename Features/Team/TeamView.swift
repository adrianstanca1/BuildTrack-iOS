import SwiftUI
import SwiftData

// MARK: - Team View

@MainActor
struct TeamView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Worker.name) private var allWorkers: [Worker]
    @State private var showAddWorker = false
    @State private var searchQuery = ""
    @State private var roleFilter: WorkerRole? = nil
    @State private var showDeleteConfirmation = false
    @State private var workerToDelete: Worker?

    var filteredWorkers: [Worker] {
        var result = allWorkers
        if let role = roleFilter {
            result = result.filter { $0.role == role }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.email.localizedCaseInsensitiveContains(searchQuery) ||
                $0.phone.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar(query: $searchQuery, placeholder: "Search team members...")

                    // Role filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: roleFilter == nil) { roleFilter = nil }
                            ForEach(WorkerRole.allCases, id: \.self) { role in
                                FilterChip(label: role.label, isSelected: roleFilter == role) { roleFilter = role }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Stats
                    HStack(spacing: 12) {
                        SummaryCard(title: "Total", value: "\(allWorkers.count)", icon: "person.3", color: BuildTrackColors.primary)
                        SummaryCard(title: "Active", value: "\(allWorkers.filter { $0.isActive }.count)", icon: "person.fill.checkmark", color: .green)
                        SummaryCard(title: "On Leave", value: "\(allWorkers.filter { !$0.isActive }.count)", icon: "person.fill.xmark", color: .orange)
                    }

                    // Worker list
                    if filteredWorkers.isEmpty {
                        EmptyStateView(
                            icon: "person.3",
                            title: "No Team Members",
                            message: "Add workers to build your project teams."
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredWorkers) { worker in
                                NavigationLink {
                                    WorkerDetailView(worker: worker)
                                } label: {
                                    WorkerRowCard(worker: worker)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Team")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddWorker = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(BuildTrackColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddWorker) {
                WorkerFormView()
            }
        }
    }
}

// MARK: - Worker Form View

struct WorkerFormView: View {
    var worker: Worker?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var role: WorkerRole = .operator
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var isActive: Bool = true
    @State private var certifications: [String] = []
    @State private var newCertification: String = ""

    init(worker: Worker? = nil) {
        self.worker = worker
        _name = State(initialValue: worker?.name ?? "")
        _role = State(initialValue: worker?.role ?? .operator)
        _phone = State(initialValue: worker?.phone ?? "")
        _email = State(initialValue: worker?.email ?? "")
        _isActive = State(initialValue: worker?.isActive ?? true)
        _certifications = State(initialValue: worker?.certifications ?? [])
    }

    var isEditing: Bool { worker != nil }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name").font(.caption).foregroundStyle(.secondary)
                        TextField("Full name", text: $name)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Role").font(.caption).foregroundStyle(.secondary)
                        Picker("Role", selection: $role) {
                            ForEach(WorkerRole.allCases, id: \.self) { r in
                                Text(r.label).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone").font(.caption).foregroundStyle(.secondary)
                        TextField("Phone number", text: $phone)
                            .keyboardType(.phonePad)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email").font(.caption).foregroundStyle(.secondary)
                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    Toggle("Active", isOn: $isActive)
                }

                Section("Certifications") {
                    ForEach(certifications, id: \.self) { cert in
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(BuildTrackColors.primary)
                            Text(cert)
                                .font(.subheadline)
                            Spacer()
                            Button {
                                certifications.removeAll { $0 == cert }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack {
                        TextField("Add certification", text: $newCertification)
                        Button {
                            let trimmed = newCertification.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty, !certifications.contains(trimmed) {
                                certifications.append(trimmed)
                                newCertification = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(BuildTrackColors.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Worker" : "New Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let worker {
            worker.name = trimmedName
            worker.role = role
            worker.phone = phone
            worker.email = email
            worker.isActive = isActive
            worker.certifications = certifications
        } else {
            let newWorker = Worker(
                name: trimmedName,
                role: role,
                phone: phone,
                email: email,
                certifications: certifications
            )
            newWorker.isActive = isActive
            modelContext.insert(newWorker)
        }
        try? modelContext.save()
    }
}

// MARK: - Worker Detail View

struct WorkerDetailView: View {
    let worker: Worker
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                CardView {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(BuildTrackColors.primary.opacity(0.12))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(initials)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(BuildTrackColors.primary)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(worker.name)
                                .font(.title2.bold())
                                .foregroundStyle(BuildTrackColors.textPrimary)

                            HStack(spacing: 6) {
                                Text(worker.role.label)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(roleColor)
                                    .clipShape(Capsule())

                                Text(worker.isActive ? "Active" : "Inactive")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(worker.isActive ? .green : .gray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(worker.isActive ? Color.green.opacity(0.12) : Color.gray.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }

                        Spacer()
                    }
                }

                // Contact
                CardView {
                    SectionHeader(title: "Contact")
                    VStack(spacing: 12) {
                        if !worker.phone.isEmpty {
                            DetailRow(icon: "phone", label: "Phone", value: worker.phone)
                        }
                        if !worker.email.isEmpty {
                            Divider()
                            DetailRow(icon: "envelope", label: "Email", value: worker.email)
                        }
                    }
                }

                // Certifications
                if !worker.certifications.isEmpty {
                    CardView {
                        SectionHeader(title: "Certifications")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(worker.certifications, id: \.self) { cert in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundStyle(BuildTrackColors.primary)
                                    Text(cert)
                                        .font(.subheadline)
                                        .foregroundStyle(BuildTrackColors.textPrimary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button { showEdit = true } label: {
                        Label("Edit Worker", systemImage: "pencil")
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
        .navigationTitle("Team Member")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            WorkerFormView(worker: worker)
        }
        .confirmationDialog("Delete Team Member?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(worker)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(worker.name).")
        }
    }

    private var initials: String {
        let parts = worker.name.split(separator: " ")
        let first = parts.first?.prefix(1).uppercased() ?? "?"
        let last = parts.count > 1 ? parts.last?.prefix(1).uppercased() ?? "" : ""
        return first + last
    }

    private var roleColor: Color {
        switch worker.role {
        case .foreman: return .blue
        case .supervisor: return .indigo
        case .electrician: return .yellow
        case .plumber: return .cyan
        case .carpenter: return .orange
        case .engineer: return .purple
        case .operator: return .green
        case .labourer: return .gray
        case .safetyOfficer: return .green
        }
    }
}

#Preview {
    TeamView()
        .modelContainer(for: [Worker.self, Project.self])
}
