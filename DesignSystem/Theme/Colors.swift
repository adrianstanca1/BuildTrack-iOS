import SwiftUI

// MARK: - BuildTrack Color Palette
enum BuildTrackColors {
    // Primary palette
    static let primary = Color.orange
    static let primaryLight = Color.orange.opacity(0.7)
    static let primaryDark = Color.orange.opacity(0.3)
    
    // Semantic
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let info = Color.blue
    
    // Neutral
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.systemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let border = Color(.separator)
    
    // Status colours
    static func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .planning: .blue
        case .active: .green
        case .onHold: .orange
        case .completed: .gray
        case .cancelled: .red
        }
    }
    
    // Priority colours
    static func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: .gray
        case .medium: .blue
        case .high: .orange
        case .critical: .red
        }
    }
}
