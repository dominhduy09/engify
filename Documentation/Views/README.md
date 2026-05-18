# Views

## Overview
SwiftUI views representing major screens and user flows in the Engify app. Each view is a primary screen that users navigate to via the tab bar or navigation flow.

## Files & Purpose

### Navigation & Core
- **ContentView.swift** - App gate/root view that shows IntroView first, then MainTabView
- **MainTabView.swift** - Tab bar navigation with 5 tabs: Home, Vocabulary, Dictionary, News, Practice
- **SettingsView.swift** - Settings and preferences screen accessible from Home toolbar

### Authentication & Onboarding
- **IntroView.swift** - First-run introduction with logo, features, and CTA to continue as guest
- **LoginView.swift** - Modern login/sign-up screen with email, password, and guest option

### Core Feature Views
- **HomeView.swift** - Main dashboard with recommended lessons and recent activity
- **VocabularyView.swift** - Vocabulary learning with flashcard-style interface and progress tracking
- **DictionaryView.swift** - Word search with real-time suggestions, definitions, examples, and pronunciation
- **NewsReadingView.swift** - English learning news articles and reading comprehension
- **PracticeView.swift** - Practice exercises and quizzes

## When to Update

### Adding New Screens
1. Create new `.swift` file in this folder
2. Implement as primary screen (not a detail view)
3. Add navigation entry in `MainTabView.swift` if top-level
4. Include preview in `#Preview` block

### Modifying Existing Views
1. **HomeView**: Update recommended card and recent activity sections
2. **DictionaryView**: Maintain debounce logic and suggestion handling
3. **VocabularyView**: Keep progress ring and card flip animations
4. **IntroView**: Preserve intro-first flow logic
5. **LoginView**: Maintain guest and authentication flows

### State Management
- Use `@StateObject` for view state
- Inject environment objects (ThemeManager, AuthenticationManager, SavedWordsManager) via `.environmentObject()`
- Keep view models separate (see ViewModels/)

### Navigation Updates
- Update `MainTabView.swift` for tab bar changes
- Update `ContentView.swift` for intro/app gate logic
- Use sheets for modal presentations (LoginView, SettingsView)
