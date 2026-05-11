import SwiftUI
struct PermitDetailView: View { let permit: Permit; var body: some View { Text("Permit: \(permit.permitNumber)").navigationTitle("Permit") } }
