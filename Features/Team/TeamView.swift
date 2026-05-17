import SwiftUI
import SwiftData

// MARK: - Professional Team View

@MainActor
struct TeamView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Worker.name) private var allWorkers: [Worker]
    @State private var showAddWorker = false
    @State private var searchQuery = ""
    @State private var roleFilter: WorkerRole? = nil
    @State private var selectedWorker: Worker?

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
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Search Bar
                    ProSearchBar(text: $searchQuery, placeholder: "Search team members...")
                        .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                        .fadeIn(delay: 0)

                    // Role Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ProFilterChip(label: "All", isSelected: roleFilter == nil) {
                                DesignTokens.Haptic.light()
                                roleFilter = nil
                            }
                            ForEach(WorkerRole.allCases, id: \.self) { role in
                                ProFilterChip(label: role.label, isSelected: roleFilter == role) {
                                    DesignTokens.Haptic.light()
                                    roleFilter = role
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    }
                    .fadeIn(delay: 0.05)

                    // Stats Row
                    HStack(spacing: DesignTokens.Spacing.md) {
                        StatMiniCard(
                            icon: "person.3.fill",
                            value: "\(allWorkers.count)",
                            label: "Total",
                            color: BuildTrackColors.primary
                        )
                        StatMiniCard(
                            icon: "person.fill.checkmark",
                            value: "\(allWorkers.filter { $0.isActive }.count)",
                            label: "Active",
                            color: BuildTrackColors.success
                        )
                        StatMiniCard(
                            icon: "person.fill.xmark",
                            value: "\(allWorkers.filter { !$0.isActive }.count)",
                            label: "Inactive",
                            color: BuildTrackColors.warning
                        )
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                    .fadeIn(delay: 0.1)

                    // Worker List
                    if filteredWorkers.isEmpty {
                        ProEmptyState(
                            icon: "person.3",
                            title: "No Team Members",
                            message: "Add workers to build your project teams.",
                            action: { showAddWorker = true }
                        )
                        .padding(.top, DesignTokens.Spacing.xl)
                        .fadeIn(delay: 0.15)
                    } else {
                        LazyVStack(spacing: DesignTokens.Spacing.md) {
                            ForEach(filteredWorkers) { worker in
                                WorkerCardPro(worker: worker)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        DesignTokens.Haptic.medium()
                                        selectedWorker = worker
                                    }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                        .fadeIn(delay: 0.15)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Team")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        DesignTokens.Haptic.medium()
                        showAddWorker = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(BuildTrackColors.primary)
                            .frame(width: 36, height: 36)
                            .background(BuildTrackColors.primary.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showAddWorker) {
                NavigationStack {
                    WorkerFormViewPro()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showAddWorker = false }
                            }
                        }
                }
            }
            .sheet(item: $selectedWorker) { worker in
                NavigationStack {
                    WorkerDetailView(worker: worker)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { selectedWorker = nil }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Professional Worker Card

struct WorkerCardPro: View {
    let worker: Worker
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(worker.isActive ? BuildTrackColors.primary.opacity(0.15) : BuildTrackColors.textTertiary.opacity(0.15))
                    .frame(width: 52, height: 52)

                Text(worker.initials)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(worker.isActive ? BuildTrackColors.primary : BuildTrackColors.textTertiary)
            }

            // Info
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(worker.name)
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)

                Text(worker.role.label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(BuildTrackColors.textSecondary)

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: worker.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(worker.isActive ? BuildTrackColors.success : BuildTrackColors.textTertiary)

                    Text(worker.isActive ? "Active" : "Inactive")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(worker.isActive ? BuildTrackColors.success : BuildTrackColors.textTertiary)
                }
            }

            Spacer()

            // Cert count
            if !worker.certifications.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(BuildTrackColors.info)
                    Text("\(worker.certifications.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BuildTrackColors.info)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(BuildTrackColors.info.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BuildTrackColors.textTertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(BuildTrackColors.border, lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete \(worker.name)?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(worker)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this worker from your team.")
        }
    }
}

// MARK: - Professional Worker Form

struct WorkerFormViewPro: View {
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
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(BuildTrackColors.primary.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Text(isEditing ? String(name.prefix(2)).uppercased() : "+")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(BuildTrackColors.primary)
                    }

                    Text(isEditing ? "Edit Worker" : "New Worker")
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                }
                .padding(DesignTokens.Spacing.lg)
                .professionalCard()

                // Form Fields
                VStack(spacing: 0) {
                    ProTextField(title: "Full Name", text: $name, icon: "person.fill", placeholder: "Enter worker's name")

                    Divider().padding(.leading, 44)

                    HStack {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(BuildTrackColors.primary)
                            .frame(width: 32, height: 32)
                            .background(BuildTrackColors.primary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Role")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(BuildTrackColors.textSecondary)

                            Picker("Role", selection: $role) {
                                ForEach(WorkerRole.allCases, id: \.self) { r in
                                    Text(r.label).tag(r)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Spacer()
                    }
                    .frame(minHeight: DesignTokens.Spacing.listRowHeight)
                    .padding(.horizontal, DesignTokens.Spacing.md)

                    Divider().padding(.leading, 44)

                    ProTextField(title: "Phone", text: $phone, icon: "phone.fill", placeholder: "Phone number", keyboardType: .phonePad)

                    Divider().padding(.leading, 44)

                    ProTextField(title: "Email", text: $email, icon: "envelope.fill", placeholder: "Email address", keyboardType: .emailAddress)

                    Divider().padding(.leading, 44)

                    ToggleRow(icon: "checkmark.circle.fill", title: "Active Status", isOn: $isActive)
                }
                .professionalCard(padding: DesignTokens.Spacing.sm)

                // Certifications
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(BuildTrackColors.info)
                            .frame(width: 32, height: 32)
                            .background(BuildTrackColors.info.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("Certifications")
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.textPrimary)

                        Spacer()

                        Text("\(certifications.count)")
                            .font(DesignTokens.Typography.caption.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(BuildTrackColors.textTertiary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)

                    if !certifications.isEmpty {
                        ForEach(certifications, id: \.self) { cert in
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(BuildTrackColors.success)

                                Text(cert)
                                    .font(DesignTokens.Typography.callout)
                                    .foregroundStyle(BuildTrackColors.textPrimary)

                                Spacer()

                                Button {
                                    DesignTokens.Haptic.medium()
                                    certifications.removeAll { $0 == cert }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(BuildTrackColors.danger)
                                }
                            }
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                        }
                    }

                    // Add certification
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProTextField(title: "", text: $newCertification, icon: "", placeholder: "Add certification...")
                            .padding(.horizontal, DesignTokens.Spacing.md)

                        Button {
                            DesignTokens.Haptic.medium()
                            if !newCertification.isEmpty {
                                certifications.append(newCertification)
                                newCertification = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(BuildTrackColors.primary)
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.sm)
                }
                .professionalCard(padding: DesignTokens.Spacing.md)

                // Save Button
                Button {
                    DesignTokens.Haptic.success()
                    save()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text(isEditing ? "Update Worker" : "Add Worker")
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        isValid
                        ? BuildTrackColors.primary
                        : BuildTrackColors.textTertiary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                }
                .disabled(!isValid)
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditing ? "Edit Worker" : "New Worker")
        .navigationBarTitleDisplayMode(.large)
    }

    private func save() {
        if let worker = worker {
            worker.name = name
            worker.roleRaw = role.rawValue
            worker.phone = phone
            worker.email = email
            worker.isActive = isActive
            worker.certifications = certifications
        } else {
            let newWorker = Worker(
                name: name,
                roleRaw: role.rawValue,
                phone: phone,
                email: email,
                isActive: isActive,
                certifications: certifications
            )
            modelContext.insert(newWorker)
        }
        dismiss()
    }
}

// MARK: - Worker Initials Extension

extension Worker {
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Worker Detail View (embedded)

struct WorkerDetailView: View {
    let worker: Worker
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(worker.isActive ? BuildTrackColors.primary.opacity(0.15) : BuildTrackColors.textTertiary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Text(worker.initials)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(worker.isActive ? BuildTrackColors.primary : BuildTrackColors.textTertiary)
                    }
                    
                    Text(worker.name)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    Text(worker.role.label)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(BuildTrackColors.textSecondary)
                    
                    ProBadge(text: worker.isActive ? "Active" : "Inactive", color: worker.isActive ? .green : .gray)
                }
                .padding(DesignTokens.Spacing.lg)
                .professionalCard()
                
                // Details
                VStack(alignment: .leading, spacing: 0) {
                    DetailRowPro(label: "Phone", value: worker.phone, icon: "phone.fill")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Email", value: worker.email, icon: "envelope.fill")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Role", value: worker.role.label, icon: "briefcase.fill")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Status", value: worker.isActive ? "Active" : "Inactive", icon: "checkmark.circle.fill")
                }
                .professionalCard(padding: 0)
                
                // Certifications
                if !worker.certifications.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Certifications")
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.textSecondary)
                        
                        ForEach(worker.certifications, id: \.self) { cert in
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(BuildTrackColors.success)
                                Text(cert)
                                    .font(DesignTokens.Typography.callout)
                                    .foregroundStyle(BuildTrackColors.textPrimary)
                                Spacer()
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .professionalCard()
                }
                
                // Actions
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        showEditSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(BuildTrackColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                    
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(BuildTrackColors.danger)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Worker Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                WorkerFormViewPro(worker: worker)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showEditSheet = false }
                        }
                    }
            }
        }
        .alert("Delete \(worker.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(worker)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this worker from your team.")
        }
    }
}

#Preview("Professional Team") {
    TeamView()
}
