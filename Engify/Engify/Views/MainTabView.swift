import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: EngifyTab = .home
    @EnvironmentObject private var authManager: AuthenticationManager

    private var tabSelection: Binding<EngifyTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if authManager.isGuestMode && newTab == .vocabulary {
                    authManager.presentAccountRequired(for: .vocabulary)
                    return
                }

                withAnimation(EngifySpring.tabSlide) {
                    selectedTab = newTab
                }
            }
        )
    }

    var body: some View {
        ZStack {
            currentTabContent
        }
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selectedTab: tabSelection)
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.floatingTabBarBottomPadding)
                .background(Color.clear)
        }
        .ignoresSafeArea(.keyboard)
        .overlay {
            LevelUpOverlay()
        }
        .sheet(item: $authManager.accountRequiredContext) { context in
            if #available(iOS 16.0, *) {
                AccountRequiredSheet(
                    context: context,
                    onSignIn: {
                        authManager.endGuestModeAndShowAuth(
                            message: "Sign in or create an account to unlock full access and keep your progress."
                        )
                    },
                    onMaybeLater: {
                        authManager.dismissAccountRequired()
                        selectedTab = .home
                    }
                )
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
            } else {
                // Fallback on earlier versions
            }
        }
    }

    @ViewBuilder
    private var currentTabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(selectedTab: tabSelection)
                .transition(.opacity)
        case .vocabulary:
            VocabularyView()
                .transition(.opacity)
        case .dictionary:
            DictionaryView()
                .transition(.opacity)
        case .news:
            NewsReadingView()
                .transition(.opacity)
        case .practice:
            PracticeView()
                .transition(.opacity)
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: EngifyTab
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var activeTabNamespace

    private static let tabs: [(EngifyTab, String, String, String)] = [
        (.home, "house.fill", "Home", "Home"),
        (.vocabulary, "book.closed.fill", "Vocabulary", "Vocab"),
        (.dictionary, "magnifyingglass.circle.fill", "Dictionary", "Lookup"),
        (.news, "newspaper.fill", "News", "News"),
        (.practice, "checklist.checked", "Practice", "Practice")
    ]

    var body: some View {
        GeometryReader { proxy in
            tabLayout(for: proxy.size.width)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(colorScheme == .dark ? EngifyColors.surfaceDarkRaised : EngifyColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(colorScheme == .dark ? EngifyColors.borderDark : EngifyColors.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.26 : 0.10), radius: 18, x: 0, y: 10)
        }
        .frame(height: 76)
    }

    private var compactRow: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Self.tabs, id: \.0) { tab, icon, title, compactTitle in
                tabButton(tab: tab, icon: icon, title: title, compactTitle: compactTitle, usesCompactLabel: true)
            }
        }
    }

    private var scrollableRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(Self.tabs, id: \.0) { tab, icon, title, _ in
                    tabButton(tab: tab, icon: icon, title: title, compactTitle: title, usesCompactLabel: false)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private func tabLayout(for width: CGFloat) -> some View {
        Group {
            if width >= 350 {
                compactRow
            } else {
                scrollableRow
            }
        }
    }

    private func tabButton(tab: EngifyTab, icon: String, title: String, compactTitle: String, usesCompactLabel: Bool) -> some View {
        TabBarButton(
            title: title,
            compactTitle: compactTitle,
            icon: icon,
            isSelected: selectedTab == tab,
            usesCompactLabel: usesCompactLabel,
            namespace: activeTabNamespace
        ) {
            withAnimation(EngifySpring.tabSlide) {
                selectedTab = tab
            }
            EngifyFeedback.shared.play(.tabSwitch)
        }
    }
}

struct TabBarButton: View {
    let title: String
    let compactTitle: String
    let icon: String
    let isSelected: Bool
    let usesCompactLabel: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    EngifyGelCapsuleSurface(tint: EngifyColors.accent)
                        .matchedGeometryEffect(id: "active-tab-pill", in: namespace)
                }

                VStack(spacing: Spacing.xxs) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))

                    Text(usesCompactLabel ? compactTitle : title)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .foregroundStyle(isSelected ? EngifyColors.textInverse : EngifyColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .padding(.horizontal, Spacing.xs)
            }
            .clipShape(Capsule())
            .compositingGroup()
            .drawingGroup()
        }
        .buttonStyle(.plain)
        .frame(minWidth: 58)
        .engifyJellyPress()
    }
}

#Preview {
    MainTabView()
        .environmentObject(SavedWordsManager())
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(GamificationManager())
        .environmentObject(LearningSettingsManager())
}
