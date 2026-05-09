import SwiftUI

struct AdminBillingView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Billing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(BuildTrackColors.primary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Free Plan")
                                .font(.headline)
                            Text("All features available to every user")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "checkmark", text: "Unlimited Projects")
                    FeatureRow(icon: "checkmark", text: "Unlimited Team Members")
                    FeatureRow(icon: "checkmark", text: "Unlimited Storage")
                    FeatureRow(icon: "checkmark", text: "Advanced Reports")
                    FeatureRow(icon: "checkmark", text: "Priority Support")
                }
                .padding(.horizontal)
                
                Text("No payment processing is configured. All users have full access to every feature.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Billing")
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
            Spacer()
        }
        .padding(.horizontal)
    }
}
