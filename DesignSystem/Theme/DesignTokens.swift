import SwiftUI
import UIKit

// MARK: - Professional iOS Design Tokens

enum DesignTokens {
    
    // MARK: Typography Scale (Dynamic Type Support)
    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title1 = Font.system(.title, design: .rounded, weight: .bold)
        static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
        static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let callout = Font.system(.callout, design: .default, weight: .regular)
        static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
        static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .medium)
        
        // Monospace for numbers/data
        static let numeric = Font.system(.body, design: .monospaced, weight: .medium)
        static let numericLarge = Font.system(.title2, design: .monospaced, weight: .bold)
    }
    
    // MARK: Spacing Scale (8pt Grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        static let sectionPadding: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let listRowHeight: CGFloat = 56
        static let minTapTarget: CGFloat = 44
    }
    
    // MARK: Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }
    
    // MARK: Shadows (Material Design 3 inspired)
    enum Shadow {
        static let sm = ShadowStyle(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let md = ShadowStyle(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        static let lg = ShadowStyle(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        static let xl = ShadowStyle(color: .black.opacity(0.16), radius: 24, x: 0, y: 12)
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: Animation Curves
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let bouncy = SwiftUI.Animation.interpolatingSpring(stiffness: 300, damping: 25)
    }
    
    // MARK: Haptic Feedback
    enum Haptic {
        static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
        static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    }
}

// MARK: - Professional View Modifiers

struct ProfessionalCard: ViewModifier {
    let hasShadow: Bool
    let padding: CGFloat
    
    init(hasShadow: Bool = true, padding: CGFloat = DesignTokens.Spacing.cardPadding) {
        self.hasShadow = hasShadow
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
            .shadow(
                color: hasShadow ? .black.opacity(0.06) : .clear,
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

struct PrimaryButtonStyle: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                LinearGradient(
                    colors: [BuildTrackColors.primary, BuildTrackColors.primaryLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .shadow(color: BuildTrackColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            .opacity(isLoading ? 0.7 : 1)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
            )
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.headline)
            .foregroundStyle(BuildTrackColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }
}

struct DangerButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.headline)
            .foregroundStyle(BuildTrackColors.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(BuildTrackColors.danger.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }
}

// MARK: - Animation Modifiers

struct FadeIn: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct ScaleIn: ViewModifier {
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Accessibility Modifiers

struct AccessibleTapTarget: ViewModifier {
    let label: String
    let hint: String?
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: DesignTokens.Spacing.minTapTarget, minHeight: DesignTokens.Spacing.minTapTarget)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - View Extensions

extension View {
    func professionalCard(hasShadow: Bool = true, padding: CGFloat = DesignTokens.Spacing.cardPadding) -> some View {
        modifier(ProfessionalCard(hasShadow: hasShadow, padding: padding))
    }
    
    func primaryButton(isLoading: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isLoading: isLoading))
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButtonStyle())
    }
    
    func dangerButton() -> some View {
        modifier(DangerButtonStyle())
    }
    
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeIn(delay: delay))
    }
    
    func scaleIn() -> some View {
        modifier(ScaleIn())
    }
    
    func accessibleTapTarget(label: String, hint: String? = nil) -> some View {
        modifier(AccessibleTapTarget(label: label, hint: hint))
    }
}

// MARK: - Professional Components

struct ProBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct ProEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(BuildTrackColors.textTertiary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.title3)
                    .foregroundStyle(BuildTrackColors.textPrimary)
                
                Text(message)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(BuildTrackColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .primaryButton()
                }
                .padding(.top, DesignTokens.Spacing.md)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

struct ProSearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(BuildTrackColors.textTertiary)
                .font(.system(size: 17, weight: .semibold))
            
            TextField(placeholder, text: $text)
                .font(DesignTokens.Typography.body)
            
            if !text.isEmpty {
                Button {
                    text = ""
                    DesignTokens.Haptic.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
                .accessibleTapTarget(label: "Clear search", hint: "Double tap to clear search text")
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm + 2)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }
}

struct ProLoadingView: View {
    let message: String?
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(BuildTrackColors.primary)
            
            if let message {
                Text(message)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(BuildTrackColors.textSecondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xl)
    }
}

struct ProErrorView: View {
    let error: String
    let retry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(BuildTrackColors.danger)
                .symbolRenderingMode(.hierarchical)
            
            Text("Something went wrong")
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text(error)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(BuildTrackColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            if let retry {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .secondaryButton()
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.xxl)
    }
}

// MARK: - HIG Compliant Form Components

struct ProTextField: View {
    let title: String
    let icon: String?
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(BuildTrackColors.textSecondary)
                .textCase(.uppercase)
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(BuildTrackColors.primary)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                if isSecure {
                    SecureField(title, text: $text)
                        .font(DesignTokens.Typography.body)
                } else {
                    TextField(title, text: $text)
                        .font(DesignTokens.Typography.body)
                        .keyboardType(keyboardType)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 4)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(BuildTrackColors.primary.opacity(text.isEmpty ? 0 : 0.3), lineWidth: 1.5)
            )
        }
    }
}

struct ProPickerField<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let display: (T) -> String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(BuildTrackColors.textSecondary)
                .textCase(.uppercase)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(display(option)) {
                        selection = option
                        DesignTokens.Haptic.selection()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(BuildTrackColors.primary)
                    Text(display(selection))
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textTertiary)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm + 4)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            }
        }
    }
}

// MARK: - Preview

#Preview("Design System") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Typography
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Typography").font(DesignTokens.Typography.title2)
                Text("Large Title").font(DesignTokens.Typography.largeTitle)
                Text("Title 1").font(DesignTokens.Typography.title1)
                Text("Title 2").font(DesignTokens.Typography.title2)
                Text("Headline").font(DesignTokens.Typography.headline)
                Text("Body").font(DesignTokens.Typography.body)
                Text("Numeric: 1,234.56").font(DesignTokens.Typography.numeric)
            }
            
            // Badges
            HStack {
                ProBadge(text: "Active", color: .green)
                ProBadge(text: "Warning", color: .orange)
                ProBadge(text: "Critical", color: .red)
            }
            
            // Cards
            Text("Professional Card")
                .font(DesignTokens.Typography.headline)
                .professionalCard()
            
            // Buttons
            Button("Primary Button") {}
                .primaryButton()
            
            Button("Secondary Button") {}
                .secondaryButton()
            
            Button("Danger Button") {}
                .dangerButton()
            
            // Search
            ProSearchBar(text: .constant(""), placeholder: "Search projects...")
            
            // Form Fields
            ProTextField(title: "Project Name", icon: "folder", text: .constant("Site A"))
            
            // Loading & Error
            ProLoadingView(message: "Loading projects...")
            
            ProErrorView(error: "Network connection failed. Please check your internet connection and try again.") {
                print("Retry")
            }
            
            // Empty State
            ProEmptyState(
                icon: "checklist",
                title: "No Tasks Yet",
                message: "Create your first task to get started with project management.",
                actionTitle: "Create Task"
            ) {
                print("Create")
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
