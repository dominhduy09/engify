# Engify iOS App

## Project Structure Overview

```
Engify/
├── Components/          # Reusable UI components
├── Data/               # Sample and test data
├── Design/             # Design system (spacing, colors, etc.)
├── Managers/           # App-wide managers (auth, theme, persistence)
├── Models/             # Data models and structures
├── Resources/          # Static assets (logos, images)
├── Services/           # Network and API services
├── ViewModels/         # MVVM view models for business logic
└── Views/              # SwiftUI screens and view hierarchy
```

## Quick Start Guide

### Understanding the Architecture
- **MVVM Pattern**: Views → ViewModels → Services → Models
- **Environment Objects**: Managers (Theme, Auth, SavedWords) are injected app-wide
- **State Management**: Uses `@StateObject`, `@Published`, and `@AppStorage`

### Key Files
- **EngifyApp.swift** - App entry point and environment setup
- **ContentView.swift** - Root navigation (shows IntroView first, then MainTabView)
- **MainTabView.swift** - Tab bar with 5 tabs (Home, Vocabulary, Dictionary, News, Practice)

### Adding Features Checklist
1. Create data Model in `Models/`
2. Create Service for API calls in `Services/`
3. Create ViewModel in `ViewModels/`
4. Create UI Components in `Components/` if reusable
5. Create main View in `Views/`
6. Add to navigation in `MainTabView.swift` if top-level

## Development Workflow

### Building the App
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project /Users/dominhduy/Desktop/Engify/Engify/Engify.xcodeproj \
-scheme Engify -destination 'generic/platform=iOS Simulator' build
```

### Common Tasks

#### Updating UI Components
- Modify files in `Components/`
- Test with previews using sample data from `Data/`
- Ensure accessibility and dark mode support
- Reference design tokens from `Design/Spacing.swift`

#### Integrating New API
1. Add model in `Models/EngifyModels.swift`
2. Create service in `Services/`
3. Use in ViewModel in `ViewModels/`
4. Display in View in `Views/`

#### Changing Branding
- Update logo in `Resources/Logo/`
- Modify colors in `Managers/ThemeManager.swift`
- Adjust spacing if needed in `Design/Spacing.swift`
- Test in all Views

#### Adding New Screen
1. Create View in `Views/`
2. Create ViewModel if needed in `ViewModels/`
3. Add Tab in `MainTabView.swift` or navigate via sheet

## Folder Descriptions

Each folder has a dedicated README with detailed information:

| Folder | Purpose | When to Update |
|--------|---------|-----------------|
| **Components/** | Reusable UI elements | Adding/modifying buttons, cards, etc. |
| **Data/** | Sample and test data | Adding new test fixtures |
| **Design/** | Design tokens & spacing | Redesign or rebrand |
| **Managers/** | App-wide state | Auth, theme, or persistence changes |
| **Models/** | Data structures | New features or API changes |
| **Resources/** | Static assets | Logo, branding, or new assets |
| **Services/** | API integration | New APIs or network changes |
| **ViewModels/** | Business logic | New features or data flow |
| **Views/** | Screens & UI | New screens or navigation |

## Testing & QA

### Before Deploying
- [ ] All views render correctly in light and dark modes
- [ ] Navigation works smoothly (intro → main app → all tabs)
- [ ] API calls work with real endpoints
- [ ] Accessibility features work (VoiceOver, text sizing)
- [ ] Colors meet WCAG AA contrast standards
- [ ] App builds without warnings (except deprecation notice in LoginView)

### Debug Tips
- Check console for API errors in Services
- Use preview canvas for component testing
- Test on multiple device sizes
- Verify data persistence in Managers

## Current Features

### ✅ Implemented
- Intro-first onboarding flow
- 5-tab navigation (Home, Vocabulary, Dictionary, News, Practice)
- Guest login via profile button
- Settings accessible from Home toolbar
- Dictionary with real-time suggestions and API integration
- Vocabulary flashcard system with progress tracking
- Saved words/bookmarks functionality
- Modern UI with Duolingo/Quizlet-style design
- Theme management (light/dark modes)
- Responsive layout for one-handed use

### 🔄 In Progress
- News API integration (placeholder)
- Full WCAG color contrast verification

### 📋 Planned
- Real backend authentication
- User sync across devices
- Push notifications
- Unit and UI tests

## Resources

- **Design System**: See `Design/Spacing.swift` and `Managers/ThemeManager.swift`
- **API Documentation**: 
  - Dictionary: https://dictionaryapi.dev
  - Suggestions: https://www.datamuse.com/api/
- **Sample Data**: `Data/EngifySampleData.swift`

## Troubleshooting

### Build Errors
- Clear derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
- Rebuild with `xcodebuild` command above

### Preview Not Loading
- Check `#Preview` block syntax in component
- Verify sample data exists in `Data/`
- Ensure all environment objects are injected

### API Not Working
- Check network permission in app sandbox
- Verify API endpoints in Services
- Review error messages in console
