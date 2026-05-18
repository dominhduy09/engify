import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: EngifyTab = .home

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tag(EngifyTab.home)

                VocabularyView()
                    .tag(EngifyTab.vocabulary)

                DictionaryView()
                    .tag(EngifyTab.dictionary)

                NewsReadingView()
                    .tag(EngifyTab.news)

                PracticeView()
                    .tag(EngifyTab.practice)
            }
            .tint(EngifyColors.accent)
            .safeAreaInset(edge: .bottom) {
                FloatingTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.floatingTabBarBottomPadding)
                    .background(Color.clear)
            }
            .ignoresSafeArea(.keyboard)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: EngifyTab
    @Environment(\.colorScheme) private var colorScheme

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
            usesCompactLabel: usesCompactLabel
        ) {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

struct TabBarButton: View {
    let title: String
    let compactTitle: String
    let icon: String
    let isSelected: Bool
    let usesCompactLabel: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
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
            .background(
                Group {
                    if isSelected {
                        EngifyColors.accentGradient
                    }
                }
            )
            .clipShape(Capsule())
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 58)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                        isPressed = false
                    }
                }
        )
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
