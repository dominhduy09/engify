import SwiftUI

struct NewsReadingView: View {
    @StateObject private var viewModel = NewsViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @State private var showSettingsSheet = false
    @State private var showNewsSourcesSettingsSheet = false
    @State private var selectedArticle: Article?
    @State private var savedToastWordTitle: String?
    @State private var showSavedWordBank = false
    @AppStorage("engify.news.filter_content.expanded") private var isNewsFilterContentExpanded = true
    var body: some View {
        EngifyScreenScroll {
            globalHeader
            filterBar

            if viewModel.isLoading {
                EngifyLoadingCard(
                    title: "Loading articles...",
                    message: "Fetching the latest reading practice for you."
                )
            } else if let errorMessage = viewModel.errorMessage {
                EngifyStateCard(
                    title: "Unable to Load News",
                    message: errorMessage,
                    systemImage: "wifi.exclamationmark",
                    tone: .warning,
                    actionTitle: "Try Again",
                    action: {
                        Task { await viewModel.loadArticles() }
                    }
                )
            } else if viewModel.filteredArticles.isEmpty {
                EngifyStateCard(
                    title: "No Articles Match",
                    message: "Try clearing filters or broadening the search.",
                    systemImage: "newspaper"
                )
            } else {
                articlesSection
            }
        }
        .refreshable {
            await viewModel.refreshArticles()
        }
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
        .engifySettingsSheet(isPresented: $showNewsSourcesSettingsSheet, initialSection: .newsSources)
        .sheet(isPresented: $showSavedWordBank) {
            SavedWordBankSheet()
                .environmentObject(savedWordsManager)
        }
        .sheet(item: $selectedArticle) { article in
            if #available(iOS 16.0, *) {
                NavigationView {
                    NewsArticleDetailView(article: article, onSaveWord: handleSaveWord)
                        .environmentObject(gamification)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            } else {
                NavigationView {
                    NewsArticleDetailView(article: article, onSaveWord: handleSaveWord)
                        .environmentObject(gamification)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .task {
            if viewModel.articles.isEmpty {
                await viewModel.loadArticles()
            }
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "News",
            subtitle: "Short reads and story practice",
            showSettings: $showSettingsSheet
        )
    }
    private var articlesSection: some View {
        VStack(spacing: Spacing.lg) {
            if viewModel.isShowingFallbackContent {
                EngifyStateCard(
                    title: "Offline Lesson Mode",
                    message: "Live feeds are unavailable right now, so Engify is showing bundled practice lessons instead of an empty news screen.",
                    systemImage: "newspaper.fill"
                )
            }

            ForEach(viewModel.filteredArticles) { article in
                Button {
                    guard authManager.requestGuestNewsArticleAccess(articleID: article.id) else { return }
                    selectedArticle = article
                } label: {
                    articleCard(article)
                }
                .buttonStyle(.plain)
            }

            PrimaryButton(title: "Load More Articles", systemImage: "arrow.down", action: {
                Task { await viewModel.loadMoreArticles() }
            })
        }
    }

    private var filterBar: some View {
        CardView(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SearchBar(
                    text: Binding(
                        get: { viewModel.filters.searchText },
                        set: { viewModel.updateSearchText($0) }
                    ),
                    placeholder: "Search topics like space, AI, health...",
                    onSubmit: {}
                )

                newsFilterContentToggle

                if isNewsFilterContentExpanded {
                    Group {
                        if viewModel.filters.isActive {
                            HStack(spacing: Spacing.sm) {
                                Label("\(viewModel.filteredArticles.count) articles match", systemImage: "line.3.horizontal.decrease.circle")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)

                                Spacer(minLength: 0)

                                Button("Clear All") {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        viewModel.clearFilters()
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(EngifyTypography.caption.weight(.semibold))
                                .foregroundStyle(theme.accentColor)
                            }
                        }

                        filterSection(
                            title: "Sources",
                            systemImage: "antenna.radiowaves.left.and.right",
                            titles: NewsViewModel.NewsSourceFilter.allCases.map(\.rawValue),
                            selected: viewModel.filters.selectedSources.map(\.rawValue),
                            onToggle: { title in
                                guard let filter = NewsViewModel.NewsSourceFilter.allCases.first(where: { $0.rawValue == title }) else { return }
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    viewModel.toggleSourceFilter(filter)
                                }
                            }
                        )

                        filterSection(
                            title: "Categories",
                            systemImage: "square.grid.2x2",
                            titles: NewsViewModel.NewsCategoryFilter.allCases.map(\.rawValue),
                            selected: viewModel.filters.selectedCategories.map(\.rawValue),
                            onToggle: { title in
                                guard let filter = NewsViewModel.NewsCategoryFilter.allCases.first(where: { $0.rawValue == title }) else { return }
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    viewModel.toggleCategoryFilter(filter)
                                }
                            }
                        )

                        Button {
                            showNewsSourcesSettingsSheet = true
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                Text("Add More Sources")
                                    .font(EngifyTypography.bodyStrong)
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(theme.accentColor)
                            .padding(.horizontal, Spacing.md)
                            .frame(minHeight: 50)
                            .background(theme.accentColor.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var newsFilterContentToggle: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isNewsFilterContentExpanded.toggle()
            }
        } label: {
            HStack(spacing: Spacing.md) {
                EngifyIconBadge(
                    systemImage: isNewsFilterContentExpanded ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle",
                    tint: theme.accentColor,
                    size: 40
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(isNewsFilterContentExpanded ? "Hide Filter Options" : "Show Filter Options")
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(newsFilterSummaryText)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isNewsFilterContentExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EngifyColors.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.accentColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.accentColor.opacity(0.16), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var newsFilterSummaryText: String {
        let activeSourceCount = viewModel.filters.selectedSources.count
        let activeCategoryCount = viewModel.filters.selectedCategories.count

        if viewModel.filters.isActive {
            return "\(viewModel.filteredArticles.count) matches • \(activeSourceCount) source filter\(activeSourceCount == 1 ? "" : "s") • \(activeCategoryCount) category filter\(activeCategoryCount == 1 ? "" : "s")"
        }

        return "Expand to refine sources, categories, and feed management."
    }

    private func filterSection(
        title: String,
        systemImage: String,
        titles: [String],
        selected: [String],
        onToggle: @escaping (String) -> Void
    ) -> some View {
        EngifyChipSection(title: title, systemImage: systemImage) {
            WrapChipsView(items: titles) { item in
                filterChip(title: item, isSelected: selected.contains(item), onTap: {
                    onToggle(item)
                })
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? EngifyColors.textInverse : theme.accentColor)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(EngifyColors.textInverse.opacity(0.92))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? theme.accentColor : theme.accentColor.opacity(0.10))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func articleCard(_ article: Article) -> some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(article.title)
                        .font(EngifyTypography.sectionTitle)
                        .foregroundStyle(EngifyColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.sm) {
                        ArticlePreviewTag(text: article.category)
                        ArticlePreviewTag(text: article.readingTime, tint: theme.accentColor)
                        Spacer(minLength: 0)
                    }
                }

                Text(article.summary)
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Label(article.source, systemImage: "globe")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)

                        Text(article.publishedDate)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(EngifyColors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: Spacing.xs) {
                        Text("Read more")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(theme.accentColor)
                }
            }
        }
    }

    private func handleSaveWord(_ vocabulary: NewsVocabularyItem) {
        let word = vocabulary.asWord
        let wasSaved = savedWordsManager.isSaved(word: word)
        withAnimation(EngifySpring.jellyRelease) {
            savedWordsManager.toggleSaved(word: word)
        }
        EngifyFeedback.shared.play(.successPop, settings: learningSettings)
        if !wasSaved, savedWordsManager.isSaved(word: word) {
            let rewardWordID = word.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            _ = gamification.awardPoints(for: .savedWord(wordID: rewardWordID))
            gamification.registerSavedWord(source: .vocabulary(word))
            showSavedWordToast(for: word.word)
        }
    }

    private func showSavedWordToast(for wordTitle: String) {
        withAnimation(EngifySpring.jellyRelease) {
            savedToastWordTitle = wordTitle
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            guard savedToastWordTitle == wordTitle else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                savedToastWordTitle = nil
            }
        }
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
}

struct NewsArticleDetailView: View {
    let article: Article
    let onSaveWord: (NewsVocabularyItem) -> Void
    @State private var selectedAnswers: [UUID: Int] = [:]
    @State private var showResult = false
    @State private var isVocabularyExpanded = false
    @State private var isQuizExpanded = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @EnvironmentObject private var theme: ThemeManager

    private var score: Int {
        article.questions.reduce(into: 0) { result, question in
            if selectedAnswers[question.id] == question.answerIndex {
                result += 1
            }
        }
    }

    var body: some View {
        EngifyScreenScroll(bottomInset: 96) {
            articleHeader
            summarySection
            contentSection
            linkSection
            vocabularySection
            quizSection
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var articleHeader: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(article.title)
                    .font(EngifyTypography.cardTitle)
                    .foregroundStyle(EngifyColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if horizontalSizeClass == .compact {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label(article.source, systemImage: "globe")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)

                        HStack(spacing: Spacing.sm) {
                            ArticlePreviewTag(text: article.category)
                            ArticlePreviewTag(text: article.readingTime, tint: theme.accentColor)
                        }
                    }
                } else {
                    HStack(spacing: Spacing.md) {
                        Label(article.source, systemImage: "globe")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)

                        Spacer(minLength: 0)

                        HStack(spacing: Spacing.sm) {
                            ArticlePreviewTag(text: article.category)
                            ArticlePreviewTag(text: article.readingTime, tint: theme.accentColor)
                        }
                    }
                }
            }
        }
    }

    private var summarySection: some View {
        articleDetailCard(title: "Summary", icon: "text.alignleft", tint: theme.accentColor) {
            Text(article.summary)
        }
    }

    private var contentSection: some View {
        articleDetailCard(title: "Article Content", icon: "doc.text", tint: theme.accentColor) {
            HighlightedArticleText(
                text: article.content,
                vocabulary: article.keyVocabulary
            )
        }
    }

    private var vocabularySection: some View {
        EngifyCollapsibleCard(
            title: "Key Vocabulary",
            subtitle: "Focus on these words to better understand the article.",
            systemImage: "book.fill",
            tint: theme.accentColor,
            isExpanded: $isVocabularyExpanded
        ) {
            Text(article.keyVocabulary.isEmpty ? "Quick vocabulary list available" : "\(article.keyVocabulary.count) vocabulary item\(article.keyVocabulary.count == 1 ? "" : "s") ready")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
        } detail: {
            if article.keyVocabulary.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(article.difficultWords, id: \.self) { word in
                            ArticlePreviewTag(text: word)
                        }
                    }
                }
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(article.keyVocabulary) { word in
                        vocabularyCard(word)
                    }
                }
            }
        }
    }

    private var linkSection: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Full Article", systemImage: "arrow.up.right.square.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.accentColor)

                if let url = article.url {
                    Link(destination: url) {
                        HStack {
                            Text("Open in browser")
                                .font(EngifyTypography.bodyStrong)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundStyle(theme.accentColor)
                    }
                } else {
                    Text("No article URL is available for this item.")
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                }
            }
        }
    }

    private var quizSection: some View {
        EngifyCollapsibleCard(
            title: "Comprehension Quiz",
            subtitle: "Check what you understood from the article.",
            systemImage: "checkmark.circle.fill",
            tint: theme.accentColor,
            isExpanded: $isQuizExpanded
        ) {
            Text("\(article.questions.count) question\(article.questions.count == 1 ? "" : "s") ready")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
        } detail: {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(article.questions) { question in
                    MultipleChoiceQuestionCard(
                        question: question,
                        selectedAnswer: selectedAnswers[question.id],
                        revealAnswer: showResult && selectedAnswers[question.id] != nil,
                        showsExplanation: learningSettings.showGrammarCorrections,
                        onSelect: { selected in
                            guard !showResult, selectedAnswers[question.id] == nil else { return }
                            selectedAnswers[question.id] = selected
                        }
                    )
                }

                EngifyCard(tint: theme.accentColor) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        PrimaryButton(title: "Check Answers", systemImage: "checkmark.circle.fill", action: {
                        guard !showResult else { return }
                        showResult = true
                        if score == article.questions.count, !article.questions.isEmpty {
                            _ = gamification.awardPoints(for: .completedNewsQuiz(articleID: article.id))
                            gamification.registerPerfectNewsQuiz()
                            gamification.completeLesson(type: .news, xpEarned: 15)
                        }
                    })

                        if showResult {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack(alignment: .top) {
                                    Text("Score: \(score)/\(article.questions.count)")
                                        .font(EngifyTypography.headline)
                                        .foregroundStyle(EngifyColors.textPrimary)

                                    Spacer(minLength: 0)

                                    Text(score == article.questions.count ? "Excellent!" : "Keep practicing!")
                                        .font(EngifyTypography.caption.weight(.semibold))
                                        .foregroundStyle(theme.accentColor)
                                }

                                Text(
                                    score == article.questions.count
                                        ? "Great job! You understood the article perfectly."
                                        : learningSettings.showGrammarCorrections
                                            ? "Review the explanations above and try again."
                                            : "Try another round to improve your score."
                                )
                                .font(EngifyTypography.body)
                                .foregroundStyle(EngifyColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func articleDetailCard<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        EngifyCard(tint: tint) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)

                content()
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textPrimary)
            }
        }
    }

    private func vocabularyCard(_ item: NewsVocabularyItem) -> some View {
        EngifyCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(item.word)
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        if !item.phonetic.isEmpty {
                            Text(item.phonetic)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(EngifyColors.textSecondary)
                        }
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: Spacing.sm) {
                        VocabularyBadge(text: item.partOfSpeech)

                        Button {
                            onSaveWord(item)
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: savedWordsManager.isSaved(word: item.asWord) ? "bookmark.fill" : "bookmark")
                                Text(savedWordsManager.isSaved(word: item.asWord) ? "Saved" : "Save")
                            }
                            .font(EngifyTypography.caption.weight(.semibold))
                            .foregroundStyle(savedWordsManager.isSaved(word: item.asWord) ? theme.accentColor : EngifyColors.textSecondary)
                            .padding(.horizontal, Spacing.md)
                            .frame(minHeight: 38)
                            .background((savedWordsManager.isSaved(word: item.asWord) ? theme.accentColor : EngifyColors.border).opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .engifyJellyPress()
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Vietnamese meaning")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    Text(item.vietnameseMeaning)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Example")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    Text("“\(item.example)”")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(EngifyColors.textPrimary)
                }
            }
        }
    }
}

private struct HighlightedArticleText: View {
    let text: String
    let vocabulary: [NewsVocabularyItem]
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        composedText
            .fixedSize(horizontal: false, vertical: true)
    }

    private var composedText: Text {
        highlightedSegments.reduce(Text("")) { partial, segment in
            let piece = Text(segment.text)
            if segment.isHighlighted {
                return partial + piece.foregroundColor(theme.accentColor).underline()
            } else {
                return partial + piece
            }
        }
    }

    private var highlightedSegments: [HighlightedSegment] {
        let candidates = vocabulary
            .map(\.word)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }

        guard !candidates.isEmpty else {
            return [HighlightedSegment(text: text, isHighlighted: false)]
        }

        let nsText = text as NSString
        let lowercaseText = text.lowercased() as NSString
        var ranges: [NSRange] = []

        for candidate in candidates {
            let search = candidate.lowercased()
            var location = 0

            while location < lowercaseText.length {
                let searchRange = NSRange(location: location, length: lowercaseText.length - location)
                let foundRange = lowercaseText.range(of: search, options: [], range: searchRange)
                if foundRange.location == NSNotFound { break }

                let overlaps = ranges.contains { NSIntersectionRange($0, foundRange).length > 0 }
                if !overlaps {
                    ranges.append(foundRange)
                }

                location = foundRange.location + max(foundRange.length, 1)
            }
        }

        let sortedRanges = ranges.sorted { $0.location < $1.location }
        guard !sortedRanges.isEmpty else {
            return [HighlightedSegment(text: text, isHighlighted: false)]
        }

        var segments: [HighlightedSegment] = []
        var currentLocation = 0

        for range in sortedRanges {
            if range.location > currentLocation {
                let prefix = nsText.substring(with: NSRange(location: currentLocation, length: range.location - currentLocation))
                segments.append(HighlightedSegment(text: prefix, isHighlighted: false))
            }

            let highlighted = nsText.substring(with: range)
            segments.append(HighlightedSegment(text: highlighted, isHighlighted: true))
            currentLocation = range.location + range.length
        }

        if currentLocation < nsText.length {
            let suffix = nsText.substring(with: NSRange(location: currentLocation, length: nsText.length - currentLocation))
            segments.append(HighlightedSegment(text: suffix, isHighlighted: false))
        }

        return segments
    }
}

private struct HighlightedSegment {
    let text: String
    let isHighlighted: Bool
}
