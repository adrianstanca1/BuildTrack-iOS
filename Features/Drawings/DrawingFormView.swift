import SwiftUI
import SwiftData

struct DrawingFormView: View {
    var drawing: Drawing?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var viewModel = DrawingViewModel()
    @State private var title: String = ""
    @State private var drawingNumber: String = ""
    @State private var revision: String = "A"
    @State private var fileUrl: String = ""
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false
    var isEditing: Bool { drawing != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    init(drawing: Drawing? = nil) {
        self.drawing = drawing
        _title = State(initialValue: drawing?.title ?? "")
        _drawingNumber = State(initialValue: drawing?.drawingNumber ?? "")
        _revision = State(initialValue: drawing?.revision ?? "A")
        _fileUrl = State(initialValue: drawing?.fileUrl ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundStyle(.secondary)
                        TextField("Drawing title", text: $title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Drawing Number").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. A-101", text: $drawingNumber)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Revision").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. A, B, 1", text: $revision)
                    }
                }
                Section("File URL") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File URL").font(.caption).foregroundStyle(.secondary)
                        TextField("https://...", text: $fileUrl)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                }
                Section("Project") {
                    Button {
                        showProjectPicker = true
                    } label: {
                        HStack {
                            Text(selectedProject?.name ?? drawing?.projectId.map { _ in "Linked" } ?? "Select Project")
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Drawing" : "New Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        if isEditing {
                            drawing?.title = title
                            drawing?.drawingNumber = drawingNumber
                            drawing?.revision = revision
                            drawing?.fileUrl = fileUrl
                            try? modelContext.save()
                        } else {
                            viewModel.createDrawing(
                                title: title,
                                drawingNumber: drawingNumber,
                                revision: revision,
                                fileUrl: fileUrl,
                                projectId: selectedProject?.id,
                                context: modelContext
                            )
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showProjectPicker) {
                ProjectPickerView(selectedProject: $selectedProject, projects: projects)
            }
        }
    }
}
