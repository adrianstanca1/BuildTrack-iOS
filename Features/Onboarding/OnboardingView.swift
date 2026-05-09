import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "building.2.fill",
            title: "Manage Projects",
            description: "Create and track construction projects with budgets, timelines, and progress tracking."
        ),
        OnboardingPage(
            image: "checklist",
            title: "Organise Tasks",
            description: "Assign tasks to workers, set priorities, and track completion in real time."
        ),
        OnboardingPage(
            image: "shield.fill",
            title: "Safety First",
            description: "Report incidents, schedule inspections, and ensure compliance on every site."
        ),
        OnboardingPage(
            image: "map.fill",
            title: "Site Mapping",
            description: "View all your project locations on an interactive map with satellite imagery."
        ),
        OnboardingPage(
            image: "bell.fill",
            title: "Stay Informed",
            description: "Get real-time notifications about task updates, safety alerts, and team activity."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            BuildTrackColors.heroGradient
                .ignoresSafeArea()
                .overlay(
                    // MeshGradient requires iOS 18+; fallback for iOS 17
                    if #available(iOS 18.0, *) {
                        MeshGradient(
                            width: 3,
                            height: 3,
                            points: [
                                .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
                                .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
                                .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1)
                            ],
                            colors: [
                                BuildTrackColors.primary.opacity(0.3),
                                BuildTrackColors.primaryLight.opacity(0.2),
                                Color.purple.opacity(0.15),
                                BuildTrackColors.primaryDark.opacity(0.2),
                                BuildTrackColors.primary.opacity(0.25),
                                BuildTrackColors.primaryLight.opacity(0.15),
                                Color.blue.opacity(0.1),
                                BuildTrackColors.primary.opacity(0.2),
                                Color.indigo.opacity(0.15)
                            ]
                        )
                        .ignoresSafeArea()
                        .opacity(0.6)
                    } else {
                        LinearGradient(
                            colors: [
                                BuildTrackColors.primary.opacity(0.3),
                                BuildTrackColors.primaryLight.opacity(0.2),
                                Color.purple.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        .opacity(0.6)
                    }
                )
            
            VStack(spacing: 0) {
                Spacer()
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)
                
                // Pagination dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Bottom buttons
                VStack(spacing: 12) {
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    } label: {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                                .font(.headline.weight(.semibold))
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            onComplete()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 110, height: 110)
                
                Image(systemName: page.image)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isActive ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isActive)
            
            // Text
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
        .opacity(isActive ? 1 : 0)
        .offset(y: isActive ? 0 : 20)
        .animation(.easeOut(duration: 0.5), value: isActive)
    }
}

#Preview {
    OnboardingView { }
}
