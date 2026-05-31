import SwiftUI

private struct OnboardingSlide: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let description: String
    let accentTint: Color
}

struct IntroView: View {
    @EnvironmentObject private var theme: ThemeManager
    @State private var currentPage = 0

    let onContinue: () -> Void

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            systemImage: "graduationcap.fill",
            title: "Welcome to Your Learning Dashboard",
            description: "Track your daily streak, monitor your level momentum, and check your metrics seamlessly from any screen across our unified green layout.",
            accentTint: EngifyColors.accent
        ),
        OnboardingSlide(
            systemImage: "doc.text.fill",
            title: "Read and Speak with Confidence",
            description: "Deep-dive into custom News Articles and interactive Grammar Practice. No more hidden options—everything works together inline inside your flow.",
            accentTint: EngifyColors.sage
        ),
        OnboardingSlide(
            systemImage: "bookmark.fill",
            title: "Perfect Word Lookup",
            description: "Search any phrase and look up precise meanings instantly. Save fresh vocabulary words straight inline into your personal study deck with a single tap.",
            accentTint: EngifyColors.sky
        )
    ]

    private var isLastPage: Bool {
        currentPage == slides.count - 1
    }

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                headerZone
                carouselZone
                bottomZone
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.screenTopPadding)
            .padding(.bottom, 36)
        }
    }

    private var onboardingBackground: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    EngifyColors.canvas,
                    EngifyColors.surface,
                    Color(red: 0.99, green: 0.98, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    theme.accentColor.opacity(0.14),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
            .offset(x: 70, y: -70)

            RadialGradient(
                colors: [
                    EngifyColors.sky.opacity(0.10),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 260
            )
            .offset(x: -60, y: 110)
        }
    }

    private var headerZone: some View {
        HStack {
            Spacer()

            Button("Skip") {
                completeOnboarding()
            }
            .font(EngifyTypography.caption)
            .foregroundStyle(EngifyColors.textSecondary.opacity(0.75))
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
            .engifyJellyPress()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var carouselZone: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                OnboardingSlideCard(slide: slide)
                    .tag(index)
                    .padding(.vertical, Spacing.xl)
                    .padding(.horizontal, Spacing.xxs)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.interactiveSpring(response: 0.42, dampingFraction: 0.84), value: currentPage)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomZone: some View {
        VStack(spacing: Spacing.lg) {
            pageIndicators

            if #available(iOS 16.0, *) {
                PrimaryButton(
                    title: isLastPage ? "Get Started" : "Next",
                    systemImage: isLastPage ? "arrow.right.circle.fill" : "chevron.right",
                    action: advance
                )
                .environmentObject(theme)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.22), value: isLastPage)
            } else {
                // Fallback on earlier versions
            }
        }
        .padding(.top, Spacing.md)
    }

    private var pageIndicators: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(slides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? theme.accentColor : EngifyColors.textSecondary.opacity(0.20))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(slides.count)")
    }

    private func advance() {
        if isLastPage {
            completeOnboarding()
            return
        }

        withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.84)) {
            currentPage += 1
        }
        EngifyFeedback.shared.play(.tabSwitch)
    }

    private func completeOnboarding() {
        EngifyFeedback.shared.play(.successPop)
        onContinue()
    }
}

private struct OnboardingSlideCard: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: 0)

            iconHero

            VStack(spacing: Spacing.md) {
                Text(slide.title)
                    .font(EngifyTypography.screenTitle)
                    .foregroundStyle(EngifyColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(slide.description)
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 340)

            featureHighlights

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, 36)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: EngifyColors.primary.opacity(0.08), radius: 24, x: 0, y: 14)
    }

    private var iconHero: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [slide.accentTint.opacity(0.22), Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 176, height: 176)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [slide.accentTint, slide.accentTint.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 104)
                .shadow(color: slide.accentTint.opacity(0.28), radius: 18, x: 0, y: 10)

            Image(systemName: slide.systemImage)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var featureHighlights: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(highlightTokens, id: \.self) { token in
                Text(token)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(slide.accentTint)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        Capsule(style: .continuous)
                            .fill(slide.accentTint.opacity(0.10))
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var highlightTokens: [String] {
        switch slide.title {
        case "Welcome to Your Learning Dashboard":
            return ["Streaks", "Levels", "Progress"]
        case "Read and Speak with Confidence":
            return ["News", "Grammar", "Speaking"]
        default:
            return ["Lookup", "Save", "Review"]
        }
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.98),
                slide.accentTint.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .stroke(slide.accentTint.opacity(0.14), lineWidth: 1)
    }
}

#Preview {
    let savedWordsManager = SavedWordsManager()
    let gamificationManager = GamificationManager()

    IntroView(onContinue: {})
        .environmentObject(AuthenticationManager(
            savedWordsManager: savedWordsManager,
            gamificationManager: gamificationManager
        ))
        .environmentObject(ThemeManager())
}
