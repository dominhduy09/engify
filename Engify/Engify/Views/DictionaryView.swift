import AVFoundation
import SwiftUI

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel()
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var audioPlayer: AVPlayer?
    @State private var showSettingsSheet = false

    var body: some View {
        EngifyScreenScroll {
            globalHeader
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

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "Lookup",
            subtitle: "Search first, read faster",
            showSettings: $showSettingsSheet
        )
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
    @State private var itemSizes: [Int: CGSize] = [:]
    @State private var availableWidth: CGFloat = 0

    private let horizontalSpacing = Spacing.xs
    private let verticalSpacing = Spacing.xs

    var body: some View {
        GeometryReader { proxy in
            let layout = layout(for: proxy.size.width)

            ZStack(alignment: .topLeading) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    chip(item)
                        .fixedSize()
                        .background(sizeReader(for: index))
                        .offset(
                            x: layout.positions[index]?.x ?? 0,
                            y: layout.positions[index]?.y ?? 0
                        )
                }
            }
            .frame(width: proxy.size.width, height: max(layout.height, 1), alignment: .topLeading)
            .onAppear {
                availableWidth = proxy.size.width
            }
            .onChange(of: proxy.size.width) { newWidth in
                availableWidth = newWidth
            }
        }
        .frame(height: max(layout(for: availableWidth).height, 1))
        .onPreferenceChange(FlexibleChipSizePreferenceKey.self) { itemSizes = $0 }
    }

    private func layout(for availableWidth: CGFloat) -> (positions: [Int: CGPoint], height: CGFloat) {
        guard availableWidth > 0, !items.isEmpty else {
            return ([:], 0)
        }

        var positions: [Int: CGPoint] = [:]
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for index in items.indices {
            let size = itemSizes[index] ?? .zero
            let chipWidth = size.width
            let chipHeight = size.height

            if currentX > 0, currentX + chipWidth > availableWidth {
                currentX = 0
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            }

            positions[index] = CGPoint(x: currentX, y: currentY)
            currentX += chipWidth + horizontalSpacing
            rowHeight = max(rowHeight, chipHeight)
        }

        return (positions, currentY + rowHeight)
    }

    private func sizeReader(for index: Int) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: FlexibleChipSizePreferenceKey.self,
                value: [index: proxy.size]
            )
        }
    }
}

private struct FlexibleChipSizePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGSize] = [:]

    static func reduce(value: inout [Int: CGSize], nextValue: () -> [Int: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
