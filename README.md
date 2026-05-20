# Engify

Engify is a SwiftUI-based iOS English learning app focused on vocabulary, dictionary lookup, reading practice, lightweight gamification, and beginner-friendly daily study flows.

The project combines a polished mobile UI with practical language-learning features:
- onboarding and guest access
- email/password authentication with Supabase
- vocabulary study and saved words
- dictionary lookup with live suggestions and pronunciation
- news-based reading lessons with fallback content
- practice flows for speaking, grammar, and quizzes
- theme, accessibility, and learning preference settings

## Table Of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Tree](#project-tree)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Build And Run](#build-and-run)
- [Key Flows](#key-flows)
- [Documentation](#documentation)
- [Known Gaps](#known-gaps)

## Overview

Engify is structured around MVVM with app-wide managers injected through SwiftUI environment objects. The codebase is organized to keep UI, business logic, services, and persistent state separated and easy to extend.

The app currently supports:
- a first-launch onboarding flow
- guest mode with usage limits for protected features
- authenticated flows backed by Supabase
- local persistence for saved words, progress, theme, and learning settings
- real dictionary and suggestion APIs
- RSS-driven news lessons with local fallback content

## Features

### Learning Experience
- Vocabulary flashcards with saved-word support
- Dictionary search with definition, phonetic, example, and audio playback
- Reading practice using news articles and learner-friendly summaries
- Practice sections for speaking, grammar, and quiz-style review
- Learning settings for goals, reminders, accessibility, and preferences

### User Experience
- SwiftUI-first interface with custom reusable components
- Light/dark appearance support and customizable accent color
- Haptics and synthesized feedback sounds
- Guest mode with locked-feature prompts
- App icon and in-app branding assets managed in `Assets.xcassets`

### Persistence And Progress
- Saved words stored locally with `UserDefaults`
- Gamification state for XP, streaks, hearts, and lesson completion
- Theme and settings persistence
- Notification and microphone permission management

## Tech Stack

### Core
- Swift 5
- SwiftUI
- Combine
- Foundation

### Apple Frameworks
- `AVFoundation` for audio and microphone-related flows
- `UserNotifications` for reminder scheduling
- `UIKit` where needed for haptics and interaction polish

### Backend And External Services
- Supabase for authentication and profile-backed user flows
- Free Dictionary API for dictionary definitions
- Datamuse API for live word suggestions
- Public RSS feeds for news ingestion
- Optional Hugging Face inference for transforming article text into lesson-friendly content

### Local Data And Assets
- `UserDefaults` for local persistence
- `Assets.xcassets` for app icon, accent color, avatars, and brand logo
- JSON fallback content for offline-safe news rendering

## Architecture

The app follows a practical MVVM structure:

- `Views/` contains user-facing screens and feature UI.
- `ViewModels/` holds feature-specific state and orchestration logic.
- `Services/` handles networking, API integration, and backend access.
- `Models/` defines the app’s data structures.
- `Managers/` owns app-wide state such as authentication, theme, saved words, gamification, and settings.
- `Components/` contains reusable UI building blocks and shared interaction helpers.

### App-Level State

`EngifyApp.swift` creates and injects these environment objects:
- `AuthenticationManager`
- `SavedWordsManager`
- `ThemeManager`
- `GamificationManager`
- `LearningSettingsManager`

### High-Level Flow

1. `EngifyApp` bootstraps managers.
2. `ContentView` decides whether to show onboarding or the authenticated shell.
3. `AuthGateView` routes between loading, login, guest mode, and the main tab experience.
4. `MainTabView` hosts the core learning tabs.

## Project Tree

This tree focuses on the folders and files that matter most for development:

```text
Engify/
├── README.md
├── Documentation/
│   ├── APP-ARCHITECTURE.md
│   ├── Components/
│   ├── Data/
│   ├── Design/
│   ├── Managers/
│   ├── Models/
│   ├── Resources/
│   ├── Services/
│   ├── ViewModels/
│   └── Views/
├── Engify/
│   ├── Engify.xcodeproj/
│   └── Engify/
│       ├── App/
│       │   └── AuthGateView.swift
│       ├── Assets.xcassets/
│       │   ├── AppIcon.appiconset/
│       │   ├── AccentColor.colorset/
│       │   ├── EngifyBrandLogo.imageset/
│       │   └── ProfileAvatar.imageset/
│       ├── Auth/
│       │   ├── AuthService.swift
│       │   └── AuthValidation.swift
│       ├── Components/
│       ├── Config/
│       │   └── SupabaseConfiguration.swift
│       ├── Data/
│       │   ├── EngifySampleData.swift
│       │   └── free_news_fallback.json
│       ├── Design/
│       │   └── Spacing.swift
│       ├── Managers/
│       ├── Models/
│       ├── Resources/
│       ├── Services/
│       ├── Support/
│       │   ├── SupabaseEnvironment.example.xcconfig
│       │   └── SupabaseEnvironment.local.xcconfig
│       ├── ViewModels/
│       ├── Views/
│       ├── ContentView.swift
│       └── EngifyApp.swift
└── .deriveddata/                    # Local build artifacts
```

## Getting Started

### Requirements
- macOS with Xcode installed
- Swift toolchain included with Xcode
- iOS deployment target: `15.6`

### Recommended
- A recent Xcode version with iOS Simulator support
- Supabase project credentials if you want authenticated flows
- Optional Hugging Face token if you want AI-transformed news lesson output

## Configuration

### Supabase

The app reads Supabase configuration from environment variables or Info.plist-backed values:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Relevant files:
- [SupabaseConfiguration.swift](Engify/Engify/Config/SupabaseConfiguration.swift)
- [SupabaseEnvironment.example.xcconfig](Engify/Engify/Support/SupabaseEnvironment.example.xcconfig)

You can configure the app using:
- Xcode scheme environment variables
- an `.xcconfig` setup based on the example file
- Info.plist values if your local workflow prefers that

### Optional News Enrichment

`NewsService` can also read:
- `HUGGING_FACE_TOKEN`

Without that token, the app still works by using RSS content plus local heuristics and fallback lesson data.

## Build And Run

### Open In Xcode

Open:

```text
Engify/Engify.xcodeproj
```

Then select the `Engify` scheme and run on an iPhone simulator.

### Command Line Build

```bash
xcodebuild \
  -project ./Engify/Engify.xcodeproj \
  -scheme Engify \
  -destination 'generic/platform=iOS Simulator' \
  build
```

If your machine uses multiple Xcode installations, set `DEVELOPER_DIR` explicitly before building.

## Key Flows

### Authentication
- Managed by `AuthenticationManager`
- Supports authenticated and guest-mode flows
- Uses `SupabaseAuthService` and `SupabaseManager`

### Vocabulary And Saved Words
- `VocabularyView` presents flashcard-style study
- `SavedWordsManager` persists bookmarked vocabulary and dictionary results

### Dictionary
- `DictionaryViewModel` calls `DictionaryService`
- `DictionaryService` integrates with:
  - `dictionaryapi.dev`
  - `api.datamuse.com`

### News
- `NewsViewModel` loads articles through `NewsService`
- `NewsService` uses:
  - RSS feed parsing
  - optional Hugging Face transformation
  - bundled `free_news_fallback.json` as fallback content

### Practice And Gamification
- `PracticeView` hosts speaking, grammar, and quiz routes
- `GamificationManager` tracks XP, streaks, hearts, and lesson completion overlays

### Settings And Theme
- `SettingsView` edits learning preferences, reminder settings, accessibility options, and appearance
- `ThemeManager` applies accent color, appearance mode, and font size app-wide
- `LearningSettingsManager` persists and validates learning-related preferences

## Documentation

The repo already includes more focused documentation under `Documentation/`:

- [APP-ARCHITECTURE.md](Documentation/APP-ARCHITECTURE.md)
- [Components](Documentation/Components/README.md)
- [Data](Documentation/Data/README.md)
- [Design](Documentation/Design/README.md)
- [Managers](Documentation/Managers/README.md)
- [Models](Documentation/Models/README.md)
- [Resources](Documentation/Resources/README.md)
- [Services](Documentation/Services/README.md)
- [ViewModels](Documentation/ViewModels/README.md)
- [Views](Documentation/Views/README.md)

Use this root README for project orientation, and the `Documentation/` folder for area-specific detail.

## Known Gaps

These are the notable areas that still look incomplete or partially implemented:

- Some Settings options are intentionally marked `Beta` because they persist correctly but are not fully wired into every learning flow yet.
- Social login buttons are present in the UI, but Google and Apple sign-in are not fully enabled.
- News enrichment quality depends on feed content and optional external token setup.
- The repo currently appears to rely mostly on manual testing; dedicated unit/UI test targets are not yet present.

## Notes For Contributors

- Prefer keeping shared UI in `Components/` and feature-specific orchestration in `ViewModels/`.
- Keep persistence logic inside managers/services instead of scattering it through views.
- If you add a new top-level user flow, document it in both this README and the relevant file under `Documentation/`.
- If you update branding, app icon, or logo assets, prefer `Assets.xcassets` over loose resource files.
