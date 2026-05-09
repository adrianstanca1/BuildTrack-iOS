import SwiftUI

// MARK: - BuildTrack Design System

enum BuildTrackColors {
    // MARK: Primary Palette
    static let primary = Color(red: 37/255, green: 99/255, blue: 235/255)       // #2563EB
    static let primaryLight = Color(red: 59/255, green: 130/255, blue: 246/255)  // #3B82F6
    static let primaryDark = Color(red: 29/255, green: 78/255, blue: 216/255)   // #1D4ED8
    
    // MARK: Semantic Colors
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)        // #22C55E
    static let warning = Color(red: 234/255, green: 179/255, blue: 8/255)         // #EAB308
    static let danger = Color(red: 239/255, green: 68/255, blue: 68/255)          // #EF4444
    static let info = Color(red: 6/255, green: 182/255, blue: 212/255)            // #06B6D4
    
    // MARK: Neutral (Light Mode)
    static let background = Color(red: 248/255, green: 250/255, blue: 252/255)    // #F8FAFC
    static let surface = Color(red: 255/255, green: 255/255, blue: 255/255)         // #FFFFFF
    static let surfaceElevated = Color(red: 255/255, green: 255/255, blue: 255/255) // #FFFFFF
    static let textPrimary = Color(red: 15/255, green: 23/255, blue: 42/255)        // #0F172A
    static let textSecondary = Color(red: 71/255, green: 85/255, blue: 105/255)     // #475569
    static let textTertiary = Color(red: 148/255, green: 163/255, blue: 184/255)   // #94A3B8
    static let border = Color(red: 226/255, green: 232/255, blue: 240/255)         // #E2E8F0
    static let divider = Color(red: 241/255, green: 245/255, blue: 249/255)         // #F1F5F9
    
    // MARK: Dark Mode
    static let darkBackground = Color(red: 2/255, green: 6/255, blue: 23/255)      // #020617
    static let darkSurface = Color(red: 15/255, green: 23/255, blue: 42/255)         // #0F172A
    static let darkSurfaceElevated = Color(red: 30/255, green: 41/255, blue: 59/255) // #1E293B
    static let darkBorder = Color(red: 51/255, green: 65/255, blue: 85/255)        // #334155
    static let darkText = Color(red: 248/255, green: 250/255, blue: 252/255)        // #F8FAFC
    static let darkTextMuted = Color(red: 148/255, green: 163/255, blue: 184/255)   // #94A3B8
    
    // MARK: Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryLight],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [primary, Color(red: 124/255, green: 58/255, blue: 237/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: Status Colors
    static func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .planning: return Color(red: 99/255, green: 102/255, blue: 241/255)   // Indigo
        case .active: return success
        case .onHold: return warning
        case .completed: return Color(red: 14/255, green: 165/255, blue: 233/255) // Sky
        case .cancelled: return danger
        }
    }
    
    static func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return textTertiary
        case .medium: return primary
        case .high: return warning
        case .critical: return danger
        }
    }
    
    static func severityColor(_ severity: IncidentSeverity) -> Color {
        switch severity {
        case .low: return textTertiary
        case .medium: return info
        case .high: return warning
        case .critical: return danger
        }
    }
}

// MARK: - Shape Styles

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
    
    func glassStyle() -> some View {
        modifier(GlassBackground())
    }
}
