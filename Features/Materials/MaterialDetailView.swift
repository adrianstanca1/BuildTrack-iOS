import SwiftUI
struct MaterialDetailView: View { let material: Material; var body: some View { Text("Material: \(material.name)").navigationTitle(material.name) } }
