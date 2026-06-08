import AVFoundation
import SwiftUI

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel(persistLookupState: true)
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @FocusState private var isSearchFieldFocused: Bool
    @State private var audioPlayer: AVPlayer?
    @State private var showSettingsSheet = false
    @State private var savedToastWordTitle: String?
    @State private var showSavedWordBank = false
    @State private var detailsExpanded = false

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
        .onAppear {
            detailsExpanded = learningSettings.showDefinitionsByDefault
        }
        .onChange(of: learningSettings.showDefinitionsByDefault) { newValue in
            detailsExpanded = newValue
        }
        .onChange(of: viewModel.currentEntry?.id) { _ in
            detailsExpanded = learningSettings.showDefinitionsByDefault
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
        EngifyCollapsibleCard(
            title: "Word details",
            subtitle: detailsExpanded ? "Full definition, meaning, and examples" : "Tap to expand this word",
            systemImage: "text.book.closed.fill",
            tint: theme.accentColor,
            isExpanded: $detailsExpanded
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(displayValue(displayedEntry.definition))
                    .font(EngifyTypography.bodyStrong)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(displayValue(displayedEntry.vietnameseMeaning))
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
            }
        } detail: {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                formsSection(for: displayedEntry)

                if learningSettings.explanationDepth != "simple" {
                    detailBlock(
                        title: "Tutor Note",
                        icon: "sparkles",
                        tint: theme.accentColor
                    ) {
                        Text(tutorNote(for: displayedEntry))
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

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
                    tint: theme.accentColor
                ) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        dictionaryLine(label: "Translation", value: displayValue(displayedEntry.vietnameseMeaning))
                    }
                }

                detailBlock(
                    title: "Example",
                    icon: "quote.opening",
                    tint: theme.accentColor
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

                if displayValue(displayedEntry.idiom) != "N/A" {
                    detailBlock(
                        title: "Idiom",
                        icon: "text.quote",
                        tint: theme.accentColor
                    ) {
                        dictionaryLine(label: "Common phrase", value: displayValue(displayedEntry.idiom))
                    }
                }

                if !displayedEntry.phrasalVerbs.isEmpty {
                    detailBlock(
                        title: "Phrasal Verbs",
                        icon: "arrow.triangle.branch",
                        tint: theme.accentColor
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(displayedEntry.phrasalVerbs, id: \.self) { phrasalVerb in
                                dictionaryLine(label: "Related form", value: displayValue(phrasalVerb))
                            }
                        }
                    }
                }

                if learningSettings.generateExtraExamples {
                    detailBlock(
                        title: "Extra Examples",
                        icon: "text.quote",
                        tint: theme.accentColor
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(extraExamples(for: displayedEntry), id: \.self) { example in
                                Text(example)
                                    .font(EngifyTypography.body)
                                    .foregroundStyle(EngifyColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
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
                if displayValue(displayedEntry.category) != "N/A" {
                    VocabularyBadge(text: displayValue(displayedEntry.category), tint: theme.accentColor)
                }
                if displayValue(displayedEntry.wordLevel) != "N/A" {
                    VocabularyBadge(text: displayValue(displayedEntry.wordLevel), tint: theme.accentColor)
                }
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
                let rewardWordID = displayedEntry.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                _ = gamification.awardPoints(for: .savedWord(wordID: rewardWordID))
                showSavedWordToast(for: displayedEntry.word)
            }
        } label: {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSaved ? EngifyColors.textInverse : theme.accentColor)
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(isSaved ? theme.accentColor : theme.accentColor.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
        .accessibilityLabel(isSaved ? "Remove bookmark" : "Save word")
    }

    private func formsSection(for displayedEntry: DictionaryEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Forms", systemImage: "tag.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.accentColor)

            HStack(spacing: Spacing.sm) {
                VocabularyBadge(text: "N: \(displayValue(displayedEntry.nounForm))", tint: theme.accentColor)
                VocabularyBadge(text: "Adj: \(displayValue(displayedEntry.adjectiveForm))", tint: theme.accentColor)
                VocabularyBadge(text: "V: \(displayValue(displayedEntry.verbForm))", tint: theme.accentColor)
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

        guard learningSettings.repeatPronunciation else { return }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard audioPlayer != nil else { return }
            await audioPlayer?.seek(to: .zero)
            audioPlayer?.play()
        }
    }

    private func tutorNote(for entry: DictionaryEntry) -> String {
        let word = displayValue(entry.word)
        let partOfSpeech = displayValue(entry.partOfSpeech).lowercased()
        let meaning = displayValue(entry.vietnameseMeaning) == "N/A" ? displayValue(entry.definition) : displayValue(entry.vietnameseMeaning)

        switch learningSettings.explanationDepth {
        case "detailed":
            if partOfSpeech.contains("verb") {
                return "\"\(word)\" works best in a full action. Try adding who does it, what happens, and when."
            } else if partOfSpeech.contains("adjective") {
                return "Use \"\(word)\" to describe a person, thing, or situation. Pair it with a noun you already know."
            }
            return "\"\(word)\" means \(meaning). Read the example once, then make a similar sentence about your own life."
        case "balanced":
            return "\"\(word)\" means \(meaning). Try using it in one simple sentence."
        default:
            return meaning
        }
    }

    private func extraExamples(for entry: DictionaryEntry) -> [String] {
        let word = displayValue(entry.word)
        let partOfSpeech = displayValue(entry.partOfSpeech).lowercased()

        if partOfSpeech.contains("verb") {
            return [
                "I can \(word) this word more confidently now.",
                "We will \(word) the phrase again in practice."
            ]
        }

        if partOfSpeech.contains("adjective") {
            return [
                "The explanation was more \(word) after one review.",
                "A \(word) example is easier to remember."
            ]
        }

        return [
            "This lesson introduced the word \(word).",
            "I want to review \(word) again tomorrow."
        ]
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
