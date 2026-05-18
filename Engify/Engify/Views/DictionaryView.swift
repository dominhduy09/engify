import AVFoundation
import SwiftUI

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel()
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var audioPlayer: AVPlayer?
    @State private var isHeaderExpanded = false
    @State private var showSettingsSheet = false

    var body: some View {
        EngifyScreenScroll {
            topHeaderBar
            headerSection
            searchSection

            if viewModel.isLoading {
                EngifyLoadingCard(
                    title: "Searching...",
                    message: "Looking up the word in the dictionary."
                )
            } else if let errorMessage = viewModel.errorMessage {
                EngifyStateCard(
                    title: "Word Not Found",
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle.fill",
                    tone: .warning,
                    actionTitle: "Try Again",
                    action: {
                        Task { await viewModel.search() }
                    }
                )
            } else if let entry = viewModel.currentEntry {
                entrySection(entry)
            } else {
                EngifyStateCard(
                    title: "Start Searching",
                    message: "Type an English word above to see its definition, pronunciation, and examples.",
                    systemImage: "text.book.closed.fill"
                )
            }
        }
        .tabTransition()
        .animation(.easeInOut(duration: 0.22), value: viewModel.showSuggestions)
        .engifySettingsSheet(isPresented: $showSettingsSheet)
    }

    private var topHeaderBar: some View {
        EngifyTopHeaderBar(
            title: "Dictionary",
            subtitle: "Search first, read faster",
            showSettings: $showSettingsSheet
        )
    }

    private var headerSection: some View {
        let config = TabHeaderConfig.dictionary
        return EngifyCollapsibleCard(
            title: config.title,
            subtitle: config.subtitle,
            systemImage: config.icon,
            tint: config.primaryColor,
            isExpanded: $isHeaderExpanded
        ) {
            HStack(spacing: Spacing.sm) {
                VocabularyBadge(text: "Search first", tint: config.primaryColor)
                VocabularyBadge(text: "Recent words below", tint: config.secondaryColor)
                Spacer(minLength: 0)
            }
        } detail: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Look up definitions, pronunciation, and examples without wasting space above the search bar.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                LinearGradient(
                    colors: [config.primaryColor.opacity(0.28), config.secondaryColor.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
        }
    }

    private var searchSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SearchBar(
                    text: $viewModel.searchText,
                    placeholder: "Search a word like happy, learn...",
                    isLoading: viewModel.isSuggestionsLoading,
                    onSubmit: {
                        Task { await viewModel.search() }
                    }
                )

                if viewModel.showSuggestions {
                    suggestionsDropdown
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !viewModel.recentSearches.isEmpty,
                   viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    recentSearchesSection
                }
            }
        }
    }

    private var suggestionsDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isSuggestionsLoading {
                SkeletonSuggestionRow()
                SkeletonSuggestionRow()
                SkeletonSuggestionRow()
            } else if viewModel.suggestions.isEmpty {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(EngifyColors.textSecondary)

                    Text("No suggestions yet. Try a shorter word.")
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                }
                .padding(Spacing.lg)
            } else {
                ForEach(viewModel.suggestions) { suggestion in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel.selectSuggestion(suggestion)
                        }
                    } label: {
                        HStack(spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                highlightedWordText(suggestion.word, query: viewModel.searchText)
                                    .font(EngifyTypography.headline)

                                if let hint = suggestion.hint, !hint.isEmpty {
                                    Text(hint.replacingOccurrences(of: "-", with: " "))
                                        .font(EngifyTypography.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)
                                }
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "arrow.up.left")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(EngifyColors.textSecondary)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if suggestion.id != viewModel.suggestions.last?.id {
                        Divider()
                            .padding(.leading, Spacing.lg)
                    }
                }
            }
        }
        .background(EngifyColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(EngifyColors.textSecondary)
                    Text("Recent Searches")
                        .font(EngifyTypography.headline)
                        .foregroundStyle(EngifyColors.textPrimary)
                }

                Spacer(minLength: 0)

                Button("Clear All") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.clearRecentSearches()
                    }
                }
                .buttonStyle(.plain)
                .font(EngifyTypography.caption.weight(.semibold))
                .foregroundStyle(theme.accentColor)
            }

            WrapChipsView(items: viewModel.recentSearches) { term in
                recentSearchChip(term: term)
            }
        }
    }

    private func recentSearchChip(term: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Button {
                viewModel.runSearch(for: term)
            } label: {
                Text(term)
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel.removeRecentSearch(term)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.accentColor.opacity(0.82))
                    .frame(width: 16, height: 16)
                    .background(theme.accentColor.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(term) from recent searches")
        }
        .padding(.leading, Spacing.md)
        .padding(.trailing, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(theme.accentColor.opacity(0.10))
        .clipShape(Capsule())
    }

    private func entrySection(_ entry: DictionaryEntry) -> some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                headerRow(entry)
                Divider()
                detailBlock(title: "Definition", icon: "text.alignleft", tint: theme.accentColor) {
                    Text(entry.definition.isEmpty ? "Definition not available" : entry.definition)
                }
                detailBlock(title: "Vietnamese Meaning", icon: "globe", tint: EngifyColors.sage) {
                    Text(entry.vietnameseMeaning)
                }
                detailBlock(title: "Example", icon: "quote.opening", tint: EngifyColors.sky) {
                    Text(entry.example.isEmpty ? "Example not available" : "“\(entry.example)”")
                        .italic()
                }
            }
        }
    }

    private func headerRow(_ entry: DictionaryEntry) -> some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    wordSummary(entry)
                    headerActions(entry)
                }
            } else {
            HStack(alignment: .top, spacing: Spacing.md) {
                wordSummary(entry)
                Spacer(minLength: 0)
                headerActions(entry)
            }
            }
        }
    }

    private func wordSummary(_ entry: DictionaryEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(entry.word)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(EngifyColors.textPrimary)

            Text(entry.phonetic.isEmpty ? "No phonetic" : entry.phonetic)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(EngifyColors.textSecondary)
        }
    }

    private func headerActions(_ entry: DictionaryEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            VocabularyBadge(text: entry.partOfSpeech)

            if entry.audioURL != nil {
                audioButton(url: entry.audioURL)
            }

            ToggleSaveButton(entry: entry)
                .environmentObject(savedWordsManager)
                .environmentObject(theme)
        }
    }

    private func audioButton(url: URL?) -> some View {
        Button {
            playAudio(url: url)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.accentColor)
                .frame(width: 42, height: 42)
                .background(theme.accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func detailBlock<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            content()
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func playAudio(url: URL?) {
        guard let url else { return }
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }

    private func highlightedWordText(_ word: String, query: String) -> Text {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var attributed = AttributedString(word)

        if !normalizedQuery.isEmpty,
           let range = attributed.range(of: normalizedQuery, options: [.caseInsensitive]) {
            attributed[range].foregroundColor = theme.accentColor
            attributed[range].font = .headline
        }

        return Text(attributed)
    }
}

private struct WrapChipsView<Item: Hashable, Chip: View>: View {
    let items: [Item]
    let chip: (Item) -> Chip

    var body: some View {
        FlexibleChipsLayout(items: items, chip: chip)
    }
}

private struct FlexibleChipsLayout<Item: Hashable, Chip: View>: View {
    let items: [Item]
    let chip: (Item) -> Chip

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: Spacing.sm)],
            alignment: .leading,
            spacing: Spacing.sm
        ) {
            ForEach(items, id: \.self) { item in
                chip(item)
            }
        }
    }
}
