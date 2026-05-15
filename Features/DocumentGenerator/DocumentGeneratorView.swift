import SwiftUI

struct DocumentGeneratorView: View {
    @State private var selectedTemplate: DocumentTemplate? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(title: "Document Templates")

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(DocumentTemplate.allCases) { template in
                            TemplateCard(template: template) {
                                selectedTemplate = template
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Document Generator")
            .sheet(item: $selectedTemplate) { template in
                ReportGeneratorFormView(template: template)
            }
        }
    }
}

struct TemplateCard: View {
    let template: DocumentTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(templateColor)
                    Spacer()
                }

                Text(template.title)
                    .font(.headline)
                    .foregroundStyle(Color(.label))

                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    var templateColor: Color {
        switch template.color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "purple": return .purple
        case "orange": return .orange
        case "indigo": return .indigo
        default: return .gray
        }
    }
}
