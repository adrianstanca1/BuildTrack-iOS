import SwiftUI
import SwiftData
import PhotosUI
import OSLog

struct PunchItemFormView: View {
    var punchItem: PunchItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var severity: PunchItemSeverity = .minor
    @State private var status: PunchItemStatus = .open
    @State private var location: String = ""
    @State private var assignee: String = ""
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    // Photos: existing URLs (any of file:// or http(s)://), staged picker items
    // not yet written to disk, and any photo-save errors to surface inline.
    @State private var photoUrls: [String] = []
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var photoError: String?
    @State private var isImportingPhotos = false

    private let logger = Logger(subsystem: "com.buildtrack.ios", category: "PunchItemForm")

    init(punchItem: PunchItem? = nil) {
        self.punchItem = punchItem
        _title = State(initialValue: punchItem?.title ?? "")
        _descriptionText = State(initialValue: punchItem?.descriptionText ?? "")
        _severity = State(initialValue: punchItem?.severity ?? .minor)
        _status = State(initialValue: punchItem?.status ?? .open)
        _location = State(initialValue: punchItem?.location ?? "")
        _assignee = State(initialValue: punchItem?.assignee ?? "")
        _photoUrls = State(initialValue: punchItem?.photoUrls ?? [])
    }

    var isEditing: Bool { punchItem != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    /// New items don't have a stable id until insert, but photos still need a folder
    /// keyed by something. Allocate one up front and reuse it for the inserted PunchItem.
    @State private var pendingItemId: UUID = UUID()
    private var photoOwnerId: UUID { punchItem?.id ?? pendingItemId }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundStyle(.secondary)
                        TextField("What needs fixing?", text: $title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description").font(.caption).foregroundStyle(.secondary)
                        TextField("Add details...", text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }

                Section("Severity & Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Severity").font(.caption).foregroundStyle(.secondary)
                        Picker("Severity", selection: $severity) {
                            ForEach(PunchItemSeverity.allCases, id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status").font(.caption).foregroundStyle(.secondary)
                            Picker("Status", selection: $status) {
                                ForEach(PunchItemStatus.allCases, id: \.self) { s in
                                    Text(s.label).tag(s)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                Section("Location & Assignment") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location").font(.caption).foregroundStyle(.secondary)
                        TextField("Where is the defect?", text: $location)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assignee").font(.caption).foregroundStyle(.secondary)
                        TextField("Who is responsible?", text: $assignee)
                    }
                }

                Section("Project") {
                    Button {
                        showProjectPicker = true
                    } label: {
                        HStack {
                            Text("Project")
                            Spacer()
                            if let project = selectedProject {
                                Text(project.name)
                                    .foregroundStyle(BuildTrackColors.primary)
                                Image(systemName: "building.2.fill")
                                    .foregroundStyle(BuildTrackColors.primary)
                            } else {
                                Text("None")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                photosSection
            }
            .navigationTitle(isEditing ? "Edit Punch Item" : "New Punch Item")
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
            .sheet(isPresented: $showProjectPicker) {
                ProjectPicker(selectedProject: $selectedProject, projects: projects)
            }
            .onChange(of: pickerSelection) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task { await importPickedPhotos(newItems) }
            }
        }
    }

    // MARK: - Photos UI

    @ViewBuilder
    private var photosSection: some View {
        Section("Photos") {
            if !photoUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photoUrls, id: \.self) { urlString in
                            PhotoThumbnail(urlString: urlString) {
                                removePhoto(urlString)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            PhotosPicker(
                selection: $pickerSelection,
                maxSelectionCount: 10,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: isImportingPhotos ? "arrow.triangle.2.circlepath" : "photo.badge.plus")
                    Text(isImportingPhotos ? "Importing…" : "Add photos")
                }
            }
            .disabled(isImportingPhotos)

            if let photoError {
                Text(photoError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func importPickedPhotos(_ items: [PhotosPickerItem]) async {
        isImportingPhotos = true
        defer {
            isImportingPhotos = false
            pickerSelection = []
        }
        photoError = nil

        var newUrls: [String] = []
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { continue }
                let url = try PunchPhotoStore.save(image, for: photoOwnerId)
                newUrls.append(url.absoluteString)
            } catch {
                logger.error("Failed to import punch photo: \(error.localizedDescription)")
                photoError = "Couldn't import a photo: \(error.localizedDescription)"
            }
        }
        if !newUrls.isEmpty {
            photoUrls.append(contentsOf: newUrls)
        }
    }

    private func removePhoto(_ urlString: String) {
        photoUrls.removeAll { $0 == urlString }
        // Only delete from disk on save — keeps cancellation reversible. We hold the
        // file in place; orphaned files in PunchPhotos will be cleaned up below at save.
    }

    // MARK: - Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespaces)

        if let punchItem {
            // Photos that were removed from the form should be deleted from disk now.
            let removed = Set(punchItem.photoUrls).subtracting(photoUrls)
            removed.forEach(PunchPhotoStore.delete(urlString:))

            punchItem.title = trimmedTitle
            punchItem.descriptionText = trimmedDesc
            punchItem.severity = severity
            punchItem.status = status
            punchItem.location = location
            punchItem.assignee = assignee
            punchItem.projectId = selectedProject?.id
            punchItem.photoUrls = photoUrls
            if status == .resolved || status == .closed, punchItem.resolvedAt == nil {
                punchItem.resolvedAt = Date()
            }
        } else {
            let newItem = PunchItem(
                id: pendingItemId,
                title: trimmedTitle,
                descriptionText: trimmedDesc,
                severity: severity,
                location: location,
                assignee: assignee,
                photoUrls: photoUrls,
                projectId: selectedProject?.id
            )
            modelContext.insert(newItem)
        }
        try? modelContext.save()
    }
}

// MARK: - Thumbnail

private struct PhotoThumbnail: View {
    let urlString: String
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 96, height: 96)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.65))
                    .font(.system(size: 22))
            }
            .buttonStyle(.plain)
            .padding(4)
            .accessibilityLabel("Remove photo")
        }
    }
}

#Preview {
    PunchItemFormView()
        .modelContainer(for: [PunchItem.self, Project.self])
}
