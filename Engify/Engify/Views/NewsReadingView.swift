import SwiftUI

struct NewsReadingView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var showSettingsSheet = false

    var body: some View {
        EngifyScreenScroll {
            globalHeader

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
            } else if viewModel.articles.isEmpty {
                EngifyStateCard(
                    title: "No Articles Yet",
                    message: "The app uses sample articles when the news API key is still set to the placeholder.",
                    systemImage: "newspaper"
                )
            } else {
                articlesSection
            }
        }
        .tabTransition()
        .engifySettingsSheet(isPresented: $showSettingsSheet)
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
            ForEach(viewModel.articles) { article in
                NavigationLink {
                    NewsArticleDetailView(article: article)
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

    private func articleCard(_ article: Article) -> some View {
        EngifyCard(tint: EngifyColors.accent) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(article.title)
                        .font(EngifyTypography.sectionTitle)
                        .foregroundStyle(EngifyColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.sm) {
                        ArticlePreviewTag(text: article.category)
                        ArticlePreviewTag(text: article.readingTime, tint: EngifyColors.sky)
                        Spacer(minLength: 0)
                    }
                }

                Text(article.summary)
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Label(article.source, systemImage: "globe")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    Spacer(minLength: 0)

                    HStack(spacing: Spacing.xs) {
                        Text("Read more")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(EngifyColors.accent)
                }
            }
        }
    }
}

struct NewsArticleDetailView: View {
    let article: Article
    @State private var selectedAnswers: [UUID: Int] = [:]
    @State private var showResult = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
            vocabularySection
            linkSection
            quizSection
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var articleHeader: some View {
        EngifyCard(tint: EngifyColors.accent) {
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
                            ArticlePreviewTag(text: article.readingTime, tint: EngifyColors.sky)
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
                            ArticlePreviewTag(text: article.readingTime, tint: EngifyColors.sky)
                        }
                    }
                }
            }
        }
    }

    private var summarySection: some View {
        articleDetailCard(title: "Summary", icon: "text.alignleft", tint: EngifyColors.accent) {
            Text(article.summary)
        }
    }

    private var contentSection: some View {
        articleDetailCard(title: "Article Content", icon: "doc.text", tint: EngifyColors.sky) {
            Text(article.content)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var vocabularySection: some View {
        EngifyCard(tint: EngifyColors.accent) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Key Vocabulary", systemImage: "book.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EngifyColors.accent)

                Text("Focus on these words to better understand the article.")
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(article.difficultWords, id: \.self) { word in
                            ArticlePreviewTag(text: word)
                        }
                    }
                }
            }
        }
    }

    private var linkSection: some View {
        EngifyCard(tint: EngifyColors.sky) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Full Article", systemImage: "arrow.up.right.square.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EngifyColors.sky)

                if let url = article.url {
                    Link(destination: url) {
                        HStack {
                            Text("Open in browser")
                                .font(EngifyTypography.bodyStrong)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundStyle(EngifyColors.sky)
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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            EngifySectionHeader(
                title: "Comprehension Quiz",
                subtitle: "Check what you understood from the article."
            )

            ForEach(article.questions) { question in
                MultipleChoiceQuestionCard(
                    question: question,
                    selectedAnswer: selectedAnswers[question.id],
                    revealAnswer: showResult && selectedAnswers[question.id] != nil,
                    onSelect: { selectedAnswers[question.id] = $0 }
                )
            }

            EngifyCard(tint: EngifyColors.accent) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    PrimaryButton(title: "Check Answers", systemImage: "checkmark.circle.fill", action: {
                        showResult = true
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
                                    .foregroundStyle(score == article.questions.count ? EngifyColors.sage : EngifyColors.warning)
                            }

                            Text(
                                score == article.questions.count
                                    ? "Great job! You understood the article perfectly."
                                    : "Review the explanations above and try again."
                            )
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)
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
}
