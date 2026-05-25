import AVFoundation
import SwiftUI

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel(persistLookupState: true)
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @FocusState private var isSearchFieldFocused: Bool
    @State private var audioPlayer: AVPlayer?
    @State private var showSettingsSheet = false
    @State private var savedToastWordTitle: String?
    @State private var showSavedWordBank = false

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            lookupCard
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.showSuggestions)
        .overlay(alignment: .top) {
            if let savedToastWordTitle {
                savedWordToast(wordTitle: savedToastWordTitle)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .scale(scale: 0.92)).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .engifySettingsSheet(isPresented: $showSettingsSheet)
        .sheet(isPresented: $showSavedWordBank) {
            SavedWordBankSheet()
                .environmentObject(savedWordsManager)
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "Lookup",
            subtitle: "Specific word analysis, one meaning at a time",
            showSettings: $showSettingsSheet
        )
    }

    private var lookupCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                searchCapsule

                if viewModel.showSuggestions && isSearchFieldFocused {
                    suggestionsDropdown
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if viewModel.isLoading {
                    EngifyLoadingCard(
                        title: "Searching...",
                        message: "Looking up the word with the public dictionary API."
                    )
                } else if let displayedEntry = viewModel.currentEntry {
                    resultContent(for: displayedEntry)
                } else {
                    emptyLookupState
                }
            }
        }
    }

    @ViewBuilder
    private func resultContent(for displayedEntry: DictionaryEntry) -> some View {
        wordSummary(for: displayedEntry)
        Divider()
        formsSection(for: displayedEntry)
        detailBlock(
            title: "Definition",
            icon: "list.bullet.rectangle.portrait",
            tint: theme.accentColor
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                dictionaryLine(label: "Part of speech", value: displayValue(displayedEntry.partOfSpeech.capitalizedIfAvailable))
                dictionaryLine(label: "Specific sense", value: displayValue(displayedEntry.definition))
            }
        }
        detailBlock(
            title: "Vietnamese Meaning",
            icon: "globe",
            tint: EngifyColors.sage
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                dictionaryLine(label: "Translation", value: displayValue(displayedEntry.vietnameseMeaning))
            }
        }
        detailBlock(
            title: "Example",
            icon: "quote.opening",
            tint: EngifyColors.sky
        ) {
            if #available(iOS 16.0, *) {
                Text(exampleText(for: displayedEntry))
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(EngifyColors.textPrimary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Fallback on earlier versions
            }
        }
    }

    private var emptyLookupState: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Search for a word")
                .font(EngifyTypography.headline)
                .foregroundStyle(EngifyColors.textPrimary)

            Text("Type any word and search with the public dictionary API to see pronunciation, definition, example, and available forms.")
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var searchCapsule: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(EngifyColors.textSecondary)

            TextField("Search a word", text: $viewModel.searchText)
                .font(EngifyTypography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFieldFocused)
                .onSubmit {
                    isSearchFieldFocused = false
                    viewModel.showSuggestions = false
                    Task { await viewModel.search() }
                }

            if viewModel.isSuggestionsLoading {
                ProgressView()
                    .scaleEffect(0.9)
            } else if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(EngifyColors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(EngifyColors.border.opacity(0.18))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(EngifyColors.canvasRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(EngifyColors.border.opacity(0.9), lineWidth: 1)
        )
        .onTapGesture {
            isSearchFieldFocused = true
            if !viewModel.suggestions.isEmpty {
                viewModel.showSuggestions = true
            }
        }
        .onChange(of: isSearchFieldFocused) { isFocused in
            if isFocused {
                viewModel.showSuggestions = !viewModel.suggestions.isEmpty
            } else {
                viewModel.showSuggestions = false
            }
        }
    }

    private var suggestionsDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.suggestions.isEmpty {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(EngifyColors.textSecondary)

                    Text("No suggestions yet.")
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                }
                .padding(Spacing.lg)
            } else {
                ForEach(viewModel.suggestions) { suggestion in
                    Button {
                        viewModel.selectSuggestion(suggestion)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text(suggestion.word)
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

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
                            .overlay(EngifyColors.border.opacity(0.22))
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .engifyGlassPanel(cornerRadius: 20, tint: theme.accentColor, shadowOpacity: 0.12)
    }

    private func wordSummary(for displayedEntry: DictionaryEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                VocabularyBadge(
                    text: displayValue(displayedEntry.partOfSpeech.capitalizedIfAvailable),
                    tint: theme.accentColor
                )
                bookmarkButton(for: displayedEntry)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(displayValue(displayedEntry.word))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(EngifyColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Spacing.xs) {
                    Text(displayValue(displayedEntry.phonetic))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(EngifyColors.textSecondary)

                    Button {
                        playAudio(for: displayedEntry)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func bookmarkButton(for displayedEntry: DictionaryEntry) -> some View {
        let isSaved = savedWordsManager.isSaved(displayedEntry)

        return Button {
            let wasSaved = isSaved
            withAnimation(EngifySpring.jellyRelease) {
                savedWordsManager.toggleSaved(displayedEntry)
            }
            EngifyFeedback.shared.play(.successPop, settings: learningSettings)
            if !wasSaved, savedWordsManager.isSaved(displayedEntry) {
                showSavedWordToast(for: displayedEntry.word)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                Text("Bookmark")
            }
            .font(EngifyTypography.caption.weight(.semibold))
            .foregroundStyle(isSaved ? EngifyColors.textInverse : theme.accentColor)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 42)
            .background(
                Capsule()
                    .fill(isSaved ? theme.accentColor : theme.accentColor.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }

    private func formsSection(for displayedEntry: DictionaryEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Forms", systemImage: "tag.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(EngifyColors.warning)

            HStack(spacing: Spacing.sm) {
                VocabularyBadge(text: "N: \(displayValue(displayedEntry.nounForm))", tint: EngifyColors.warning)
                VocabularyBadge(text: "Adj: \(displayValue(displayedEntry.adjectiveForm))", tint: EngifyColors.warning)
                VocabularyBadge(text: "V: \(displayValue(displayedEntry.verbForm))", tint: EngifyColors.warning)
            }
        }
    }

    private func exampleText(for displayedEntry: DictionaryEntry) -> String {
        let example = displayValue(displayedEntry.example)
        return example == "N/A" ? "N/A" : "“\(example)”"
    }

    private func dictionaryLine(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(EngifyTypography.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textSecondary)

            Text(value)
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
        }
    }

    private func playAudio(for displayedEntry: DictionaryEntry) {
        guard let url = displayedEntry.audioURL else {
            EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
            return
        }

        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }

    private func displayValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "N/A" : value
    }

    private func savedWordToast(wordTitle: String) -> some View {
        Button {
            withAnimation(EngifySpring.jellyRelease) {
                savedToastWordTitle = nil
                showSavedWordBank = true
            }
            EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: "bookmark.circle.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.accentColor)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Saved to Word Bank")
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text("\"\(wordTitle)\" is ready to review. Tap to open.")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.accentColor)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(EngifyColors.surface.opacity(0.97))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(theme.accentColor.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: EngifyColors.primary.opacity(0.12), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }

    private func showSavedWordToast(for wordTitle: String) {
        withAnimation(EngifySpring.jellyRelease) {
            savedToastWordTitle = wordTitle
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard savedToastWordTitle == wordTitle else { return }

            await MainActor.run {
                withAnimation(EngifySpring.settle) {
                    savedToastWordTitle = nil
                }
            }
        }
    }
}
