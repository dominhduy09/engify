import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: EngifyTab = .home
    @State private var tabTransitionDirection: TabTransitionDirection = .forward
    @EnvironmentObject private var authManager: AuthenticationManager

    private static let orderedTabs: [EngifyTab] = [
        .home,
        .vocabulary,
        .dictionary,
        .news,
        .practice
    ]

    private var tabSelection: Binding<EngifyTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                switchToTab(newTab, initiatedBySwipe: false)
            }
        )
    }

    var body: some View {
        ZStack {
            currentTabContent
        }
        .contentShape(Rectangle())
        .gesture(tabSwipeGesture)
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
                .transition(tabContentTransition)
        case .vocabulary:
            VocabularyView()
                .transition(tabContentTransition)
        case .dictionary:
            DictionaryView()
                .transition(tabContentTransition)
        case .news:
            NewsReadingView()
                .transition(tabContentTransition)
        case .practice:
            PracticeView()
                .transition(tabContentTransition)
        }
    }

    private var tabContentTransition: AnyTransition {
        let insertionEdge: Edge = tabTransitionDirection == .forward ? .trailing : .leading
        let removalEdge: Edge = tabTransitionDirection == .forward ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var tabSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height

                guard abs(horizontal) > abs(vertical), abs(horizontal) > 70 else { return }

                if horizontal < 0 {
                    moveToAdjacentTab(step: 1)
                } else {
                    moveToAdjacentTab(step: -1)
                }
            }
    }

    private func moveToAdjacentTab(step: Int) {
        guard let currentIndex = Self.orderedTabs.firstIndex(of: selectedTab) else { return }

        let nextIndex = currentIndex + step
        guard Self.orderedTabs.indices.contains(nextIndex) else { return }

        switchToTab(Self.orderedTabs[nextIndex], initiatedBySwipe: true)
    }

    private func switchToTab(_ newTab: EngifyTab, initiatedBySwipe: Bool) {
        guard newTab != selectedTab else { return }

        if authManager.isGuestMode && newTab == .vocabulary {
            authManager.presentAccountRequired(for: .vocabulary)
            return
        }

        updateTransitionDirection(from: selectedTab, to: newTab)

        withAnimation(EngifySpring.tabSlide) {
            selectedTab = newTab
        }

        if initiatedBySwipe {
            EngifyFeedback.shared.play(.tabSwitch)
        }
    }

    private func updateTransitionDirection(from currentTab: EngifyTab, to newTab: EngifyTab) {
        guard let currentIndex = Self.orderedTabs.firstIndex(of: currentTab),
              let newIndex = Self.orderedTabs.firstIndex(of: newTab) else {
            tabTransitionDirection = .forward
            return
        }

        tabTransitionDirection = newIndex >= currentIndex ? .forward : .backward
    }
}

private enum TabTransitionDirection {
    case forward
    case backward
}

struct FloatingTabBar: View {
    @Binding var selectedTab: EngifyTab
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var activeTabNamespace

    private static let tabs: [(EngifyTab, String, String, String)] = [
        (.home, "house.fill", "Home", "Home"),
        (.vocabulary, "book.fill", "Vocabulary", "Vocab"),
        (.dictionary, "magnifyingglass", "Dictionary", "Lookup"),
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
    let savedWordsManager = SavedWordsManager()
    let gamificationManager = GamificationManager()

    MainTabView()
        .environmentObject(savedWordsManager)
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationManager(
            savedWordsManager: savedWordsManager,
            gamificationManager: gamificationManager
        ))
        .environmentObject(gamificationManager)
        .environmentObject(LearningSettingsManager())
}
