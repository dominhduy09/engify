# Engify - English Learning App Documentation

## Project Overview

Engify is an iOS app for learning English through vocabulary flashcards, a smart dictionary, news reading with comprehension quizzes, and practice exercises. Built with SwiftUI.

---

## App Entry & Navigation

### 1. [EngifyApp.swift](Engify/EngifyApp.swift) — App Entry Point
**What it does:** The `@main` entry point. Creates three app-wide `StateObject` managers and launches `ContentView` with them injected as environment objects.
**When it shows:** Runs once at app launch (before any UI appears).
**How it works:** Sets up `AuthenticationManager`, `SavedWordsManager`, and `ThemeManager` as the single source of truth for auth state, saved words, and visual theme across the entire app.

---

### 2. [ContentView.swift](Engify/Engify/ContentView.swift) — Root View Router
**What it does:** Decides whether the user has seen the intro screen. If not, shows `IntroView`; otherwise shows `MainTabView`.
**When it shows:** Immediately after `EngifyApp` runs, every time the app opens.
**How it works:** Uses `@AppStorage("engify_has_seen_intro")` to persist a boolean. The intro only shows on first launch (or after a reset).

---

### 3. [MainTabView.swift](Engify/Engify/Views/MainTabView.swift) — Tab Navigation Shell
**What it does:** Hosts a `TabView` with 5 tabs (Home, Vocabulary, Dictionary, News, Practice) and overlays a custom `FloatingTabBar` at the bottom.
**When it shows:** After the intro has been completed — this is the main shell for the app.
**How it works:**
- `TabView` holds all 5 view screens but only renders the selected one.
- `FloatingTabBar` is a custom-styled floating pill bar that sits above the system tab bar (which is hidden via `.tint()`).
- `TabBarButton` animates a gradient pill behind the selected icon.
- `EngifyColors` enum consolidates theme colors used across the tab bar.

---

### 4. [Spacing.swift](Engify/Engify/Design/Spacing.swift) — Design Constants
**What it does:** Defines a systematic spacing scale (`xs` through `xxl`) based on a 4px grid unit.
**When it shows:** Used everywhere in the app for consistent padding/margins — never directly visible but underpins the layout.
**How it works:** A simple `struct` with `static let` constants. Import wherever spacing values are needed.

---

## Onboarding

### 5. [IntroView.swift](Engify/Engify/Views/IntroView.swift) — Onboarding Welcome Screen
**What it shows:** First time a user opens the app. Displays the Engify logo, a tagline, three feature highlights (Daily vocabulary, Simple reading, Quick practice), and a "Start Learning" button.
**When it shows:** Only on first launch before the user has set `hasSeenIntro = true`.
**How it works:** Calls `authManager.continueAsGuest()` and fires `onContinue()` to mark the intro as seen. Uses `LearningCard` and `IntroFeatureRow` to display features.

### 6. [IntroPagerView.swift](Engify/Engify/Views/IntroPagerView.swift) — Card Pager (unused/incomplete)
**What it does:** A swipeable pager of `IntroCard` views with Previous/Next controls and animated page indicators.
**When it shows:** Embedded inside `IntroView` but currently bypassed (intro goes directly to feature rows).

### 7. [IntroCardView.swift](Engify/Engify/Views/IntroCardView.swift) — Single Intro Card
**What it does:** Renders a single intro card with icon circle, title, subtitle, and description.
**When it shows:** Used by `IntroPagerView` to display feature pages.

---

## Main Tab Screens

### 8. [HomeView.swift](Engify/Engify/Views/HomeView.swift) — Home Dashboard
**What it shows:** A personalized dashboard with:
- Greeting header with user name and decorative avatar
- Two stat cards: day streak and progress percentage
- "Continue Learning" primary button (jumps to Vocabulary tab)
- Recommended content card (hardcoded "Travel Vocabulary")
- Recent activity list (hardcoded items)

**When it shows:** The default landing tab after logging in/guest mode. The user always lands here first.
**How it works:** Reads `authManager.currentUser` for the display name. `selectedTab = .vocabulary` on "Continue Learning". Pull-to-refresh triggers a card rotation animation.

---

### 9. [VocabularyView.swift](Engify/Engify/Views/VocabularyView.swift) — Flashcard Learning
**What it shows:** A single vocabulary flashcard with:
- Word, pronunciation, part of speech, Vietnamese meaning, and example sentence
- Bookmark/save button that persists to `SavedWordsManager`
- Progress bar showing current position
- Previous/Next navigation buttons

**When it shows:** User taps the Vocabulary tab. Designed for learning one word at a time by swiping through the word list.
**How it works:** Cycles through `EngifySampleData.vocabularyWords` with circular wraparound. Pull-to-refresh advances to a random word with a spring animation.

---

### 10. [DictionaryView.swift](Engify/Engify/Views/DictionaryView.swift) — Smart Dictionary Search
**What it shows:**
- A search bar at the top with real-time suggestions
- Dropdown suggestion list fetched from Datamuse API as the user types
- Recent searches displayed as chips when the search bar is empty
- A detailed word entry: word, phonetic, part of speech, definition, Vietnamese meaning, example, and audio playback button
- Save/bookmark toggle to persist to `SavedWordsManager`

**When it shows:** User taps the Dictionary tab. Fetches live data from the free DictionaryAPI and Datamuse API.
**How it works:**
- `DictionaryViewModel` debounces search text (300ms) and fetches suggestions
- On submit, calls `DictionaryService.searchWord()` which hits `dictionaryapi.dev`
- Falls back to sample data if the API key is the placeholder
- `AVPlayer` handles pronunciation audio playback

---

### 11. [NewsReadingView.swift](Engify/Engify/Views/NewsReadingView.swift) — News Feed
**What it shows:**
- List of curated English articles suitable for learners
- Each article card shows title, category tag, reading time, summary, and source
- Tapping an article navigates to `NewsArticleDetailView`
- Detail view shows: article header, summary, full content, key vocabulary chips, full article link, and a comprehension quiz

**When it shows:** User taps the News tab. Articles load from `NewsService` (live API or sample data fallback).
**How it works:**
- `NewsViewModel.loadArticles()` triggers on appear if the list is empty
- If `NewsService.apiKey` is still the placeholder, returns `EngifySampleData.articles`
- The quiz tracks selected answers per question and shows a score when "Check Answers" is tapped

---

### 12. [PracticeView.swift](Engify/Engify/Views/PracticeView.swift) — Practice Hub
**What it shows:** Three practice sections:
- **Speaking Practice:** Displays a sentence prompt with a "Start Speaking" button (mic feature coming in future update)
- **Grammar Lesson:** Segmented picker switching between grammar topics, each with explanation and example sentences
- **Quick Quiz:** Multiple choice questions from `EngifySampleData.practiceQuizQuestions` with answer reveal and score

**When it shows:** User taps the Practice tab. Badge celebration overlay appears on perfect quiz score.

---

## Authentication & Settings

### 13. [LoginView.swift](Engify/Engify/Views/LoginView.swift) — Login / Sign Up
**What it shows:** Email + password form with segmented Login/Sign Up toggle, decorative gradient background, error/info messages, and "Try as Guest" option.
**When it shows:** Slides up as a sheet from `HomeView` when the user taps the profile button.
**How it works:** Validates email non-empty and password ≥ 6 chars. Currently demo/mock mode — any valid input creates a session. Delegates actual auth to `AuthenticationManager`.

### 14. [SettingsView.swift](Engify/Engify/Views/SettingsView.swift) — Theme Settings
**What it shows:** A `Form`-based settings screen with:
- Accent color picker (5 color options)
- Appearance mode picker (System / Light / Dark)
- Font size slider

**When it shows:** Slides up as a sheet from `HomeView` when the gear icon is tapped.
**How it works:** All controls directly mutate `ThemeManager` properties which persist to `UserDefaults` via `didSet`.

---

## Reusable Components

### 15. [EngifyUIComponents.swift](Engify/Engify/Components/EngifyUIComponents.swift) — Core UI Building Blocks
Contains:
- **`EngifyAppBackground`** — Adaptive gradient background (light: blue-tinted white; dark: deep navy)
- **`CardView`** / **`EngifyCard`** — Rounded card containers with frosted glass effect, used everywhere
- **`SearchBar`** — Styled search input with loading spinner and clear button
- **`EngifySectionHeader`** — Standard title + subtitle header text
- **`EngifyPrimaryButtonStyle`** — Gradient-filled button style for primary CTAs
- **`EngifyFeatureButton`** — Card-wrapped feature button with icon + title + subtitle
- **`VocabularyBadge`** — Blue capsule label (e.g., "noun", "Word 3 of 10")
- **`ArticlePreviewTag`** — Green capsule tag for article category/reading time
- **`MultipleChoiceQuestionCard`** — Quiz question card with option buttons that change color on reveal
- **`highlightedArticleText()`** — Highlights difficult words in article text

---

### 16. [PrimaryButton.swift](Engify/Engify/Components/PrimaryButton.swift) — Primary Action Button
**What it does:** A prominent, gradient-filled button with haptic feedback and press animation.
**When it shows:** Used for main CTAs like "Start Learning", "Continue Learning", "Log In".
**How it works:** Uses `ThemeManager.accentColor` for dynamic theming. Disabled state dims the gradient.

---

### 17. [ToggleSaveButton.swift](Engify/Engify/Components/ToggleSaveButton.swift) — Bookmark Toggle
**What it does:** A bookmark icon button that toggles the saved state of a `DictionaryEntry`.
**When it shows:** Appears in `DictionaryView` on each word entry and in the article detail view.
**How it works:** Reads/writes through `SavedWordsManager`. Animates with spring + scale on tap.

---

### 18. [LearningCard.swift](Engify/Engify/Components/LearningCard.swift) — Friendly Learning Card
**What it does:** A soft, rounded card used in onboarding (`IntroView`) with a subtle shadow and system background fill.
**When it shows:** Wraps the feature list in `IntroView`.

---

### 19. [EngifyLogoView.swift](Engify/Engify/Components/EngifyLogoView.swift) — App Logo
**What it does:** Renders the Engify graduation-cap logo inside a gradient rounded square.
**When it shows:** `IntroView`, `LoginView`, and anywhere the brand logo needs to appear.

---

### 20. [TabHeaderBuilder.swift](Engify/Engify/Components/TabHeaderBuilder.swift) — Standard Tab Header
**What it does:** A reusable utility struct that builds consistent gradient-icon headers for each tab screen.
**When it shows:** Called from Vocabulary, Dictionary, News, and Practice views.
**How it works:**
- `buildTabHeader()` composes: gradient icon circle + title + subtitle + gradient separator line
- `TabHeaderConfig` enum holds per-tab color presets (Vocabulary: orange, Dictionary: purple, News: red-orange, Practice: green)
- `View.tabTransition()` extension applies a slide-in-from-right / fade navigation animation used on every tab switch

---

### 21. [ThemePickerView.swift](Engify/Engify/Components/ThemePickerView.swift) — Theme Controls
**What it does:** A `Form`-based UI for picking accent color, appearance mode, and font size.
**When it shows:** Embedded inside `SettingsView`.

---

### 22. [ProgressRing.swift](Engify/Engify/Components/ProgressRing.swift) — Animated Progress Ring
**What it does:** A circular ring that fills from 0 to `progress` (0..1) with an animated entry and value change.
**When it shows:** Could be used for dashboard stats (currently hardcoded values in `HomeView`).

---

### 23. [EmptyStateView.swift](Engify/Engify/Components/EmptyStateView.swift) — Empty State Placeholder
**What it does:** Centered icon + title + message for when a list is empty.
**When it shows:** Not currently used but available for future empty states (e.g., no saved words).

---

### 24. [LoadingView.swift](Engify/Engify/Components/LoadingView.swift) — Loading Indicator
**What it does:** A themed `ProgressView` with a message label.
**When it shows:** Not currently used directly but available as a reusable component.

---

### 25. [ErrorView.swift](Engify/Engify/Components/ErrorView.swift) — Error State View
**What it does:** Yellow warning icon + title + message + optional retry button.
**When it shows:** Not currently used directly but available for future error handling.

---

### 26. [ShimmerModifier.swift](Engify/Engify/Components/ShimmerModifier.swift) — Skeleton Loading Animation
**What it does:** A sweeping white shimmer overlay for placeholder content during loading.
**When it shows:** Used by `SkeletonSuggestionRow` in `DictionaryView` while suggestions are being fetched.

---

## Managers (State & Persistence)

### 27. [ThemeManager.swift](Engify/Engify/Managers/ThemeManager.swift) — Theme State
**What it does:** Manages accent color, appearance (light/dark/system), and font size. Persists all three to `UserDefaults`.
**When it shows:** App-wide — controls the look of every view via environment object injection.

---

### 28. [SavedWordsManager.swift](Engify/Engify/Managers/SavedWordsManager.swift) — Saved Words Persistence
**What it does:** Stores bookmarked vocabulary words and dictionary entries to `UserDefaults`.
**When it shows:** The bookmark icon in `VocabularyView` and `DictionaryView` updates immediately.

---

### 29. [AuthenticationManager.swift](Engify/Engify/Managers/AuthenticationManager.swift) — Auth State
**What it does:** Manages the current user session (mock/demo — no real backend). Handles login, sign up, guest mode, and logout.
**When it shows:** `HomeView` reads `currentUser?.displayName` for personalization. Login sheet presented from Home.

---

## ViewModels

### 30. [DictionaryViewModel.swift](Engify/Engify/ViewModels/DictionaryViewModel.swift) — Dictionary Search State
**What it does:** Bridges `DictionaryView` and `DictionaryService`. Manages search text, debounced suggestion fetching, loading/error states, and recent searches.
**When it shows:** Active only while the Dictionary tab is open. Coordinates the suggestion dropdown and final entry display.

---

### 31. [NewsViewModel.swift](Engify/Engify/ViewModels/NewsViewModel.swift) — News State
**What it does:** Manages the articles list, loading state, and error messages for `NewsReadingView`.
**When it shows:** Active while News tab is open. Triggers `NewsService.fetchArticles()` on appear if list is empty.

---

## Services (Data Layer)

### 32. [DictionaryService.swift](Engify/Engify/Services/DictionaryService.swift) — Dictionary API
**What it does:**
- `searchWord()` — Calls `dictionaryapi.dev` to get word definitions
- `suggestWords()` — Calls `datamuse.com/sug` for real-time spelling suggestions as the user types

**When it shows:** Called by `DictionaryViewModel` on submit and on debounced text change.

---

### 33. [NewsService.swift](Engify/Engify/Services/NewsService.swift) — News Feed API
**What it does:** Fetches top headlines from `newsapi.org` if a valid API key is configured. Falls back to `EngifySampleData.articles` if the key is still the placeholder.
**When it shows:** Called by `NewsViewModel` when the News tab loads.

---

## Data

### 34. [EngifyModels.swift](Engify/Engify/Models/EngifyModels.swift) — Data Models
Defines all core domain types:
- `EngifyTab` — enum for the 5 tab identifiers
- `User` — user account model
- `Word` — vocabulary flashcard word model
- `DictionaryEntry` — dictionary result model
- `DictionarySuggestion` — autocomplete suggestion model
- `QuizQuestion` — multiple-choice question model
- `Article` — news article model with quiz questions

---

### 35. [EngifySampleData.swift](Engify/Engify/Data/EngifySampleData.swift) — Fallback Sample Content
**What it does:** Provides hardcoded fallback content so the app is usable offline or without API keys:
- 4 vocabulary words
- 3 dictionary fallback words
- 3 sample articles with comprehension quizzes
- 1 speaking practice sentence
- 2 grammar topics (Present Simple, There is/There are)
- 3 practice quiz questions

**When it shows:** Used automatically when `NewsService.apiKey` is the placeholder, and as the vocabulary source in `VocabularyView`.
