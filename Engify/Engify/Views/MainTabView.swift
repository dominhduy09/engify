import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: EngifyTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tag(EngifyTab.home)

            VocabularyView()
                .tag(EngifyTab.vocabulary)

            DictionaryView()
                .tag(EngifyTab.dictionary)
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
}

struct FloatingTabBar: View {
    @Binding var selectedTab: EngifyTab
    @Environment(\.colorScheme) private var colorScheme

    private static let tabs: [(EngifyTab, String, String)] = [
        (.home, "house.fill", "Home"),
        (.vocabulary, "book.closed.fill", "Vocabulary"),
        (.dictionary, "magnifyingglass.circle.fill", "Dictionary")
    ]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            compactRow
            scrollingRow
        }
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

    private var compactRow: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Self.tabs, id: \.0) { tab, icon, title in
                tabButton(tab: tab, icon: icon, title: title)
            }
        }
    }

    private var scrollingRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(Self.tabs, id: \.0) { tab, icon, title in
                    tabButton(tab: tab, icon: icon, title: title)
                }
            }
            .padding(.horizontal, 1)
        }
        .scrollClipDisabled()
    }

    private func tabButton(tab: EngifyTab, icon: String, title: String) -> some View {
        TabBarButton(
            title: title,
            icon: icon,
            isSelected: selectedTab == tab
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
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? EngifyColors.textInverse : EngifyColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, Spacing.sm)
            .background(
                Group {
                    if isSelected {
                        EngifyColors.accentGradient
                    }
                }
            }
            .clipShape(Capsule())
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
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
