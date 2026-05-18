# Engify - iOS English Learning App

A modern, learner-friendly iOS app for English vocabulary and language learning with Duolingo/Quizlet-inspired UI/UX.

## Project Structure

```
Engify/
├── Engify/                          # Main app source code
│   ├── README.md                    # Detailed app architecture guide
│   ├── Components/                  # Reusable UI components
│   ├── Data/                        # Sample and test data
│   ├── Design/                      # Design system tokens
│   ├── Managers/                    # App-wide managers
│   ├── Models/                      # Data structures
│   ├── Resources/                   # Static assets
│   ├── Services/                    # Network services
│   ├── ViewModels/                  # MVVM business logic
│   ├── Views/                       # SwiftUI screens
│   ├── ContentView.swift            # Root navigation
│   ├── EngifyApp.swift              # App entry point
│   └── Assets.xcassets/             # Xcode asset catalog
├── Engify.xcodeproj/                # Xcode project configuration
└── README.md                        # This file

```

## Getting Started

### Prerequisites
- Xcode 17.0+
- iOS 26.1 SDK
- Swift 5.x

### Building & Running

```bash
# Build for iOS Simulator
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project /Users/dominhduy/Desktop/Engify/Engify/Engify.xcodeproj \
-scheme Engify -destination 'generic/platform=iOS Simulator' build
```

## Key Features

✨ **Modern UI/UX**
- Duolingo/Quizlet-inspired design
- Smooth animations and haptic feedback
- Dark mode support
- Accessible for one-handed use

📚 **Vocabulary Learning**
- Flashcard-style vocabulary practice
- Progress tracking with visual indicators
- Saved words for quick access

🔍 **Dictionary Integration**
- Real-time word suggestions
- Complete word definitions from Free Dictionary API
- Pronunciation and phonetic information
- Example sentences

📰 **News & Reading**
- English language articles
- ESL learner-friendly content
- Reading comprehension practice

🎯 **Practice & Exercises**
- Interactive quizzes
- Progressive difficulty
- Gamified learning experience

## Architecture

**MVVM Pattern**
- Views: SwiftUI components
- ViewModels: Business logic and state management
- Models: Data structures
- Services: API integration

**State Management**
- `@StateObject` for view state
- `@Published` for observable properties
- Environment objects for app-wide managers
- UserDefaults for persistence

**Key Managers**
- **AuthenticationManager** - User login and sessions
- **ThemeManager** - App theming and appearance
- **SavedWordsManager** - Vocabulary persistence

## Documentation

Each folder contains a detailed README:
- [Engify/README.md](Engify/README.md) - App architecture and feature guide
- [Engify/Components/README.md](Engify/Components/README.md) - UI components
- [Engify/Views/README.md](Engify/Views/README.md) - Screen definitions
- [Engify/ViewModels/README.md](Engify/ViewModels/README.md) - Business logic
- [Engify/Managers/README.md](Engify/Managers/README.md) - App-wide state
- [Engify/Services/README.md](Engify/Services/README.md) - API integration
- [Engify/Models/README.md](Engify/Models/README.md) - Data structures
- [Engify/Design/README.md](Engify/Design/README.md) - Design system
- [Engify/Data/README.md](Engify/Data/README.md) - Test data

## Development Guide

### Adding a New Feature
1. Define data models in `Engify/Models/`
2. Create API service in `Engify/Services/`
3. Implement ViewModel in `Engify/ViewModels/`
4. Build UI components in `Engify/Components/`
5. Create main screen in `Engify/Views/`
6. Add navigation in `Engify/Views/MainTabView.swift`

### Common Tasks
- **Update UI Components**: Edit files in `Engify/Components/` and test with previews
- **Integrate New API**: Create service, model, viewmodel, then wire into views
- **Change Branding**: Update `Engify/Resources/Logo/`, `Engify/Managers/ThemeManager.swift`
- **Add New Screen**: Create View + ViewModel, add tab to MainTabView

## Build & Deployment

### Build Status
- ✅ Latest build: **SUCCEEDED**
- Platform: iOS Simulator 26.1
- Architecture: arm64, x86_64

### Known Issues
- ⚠️ LoginView deprecation warning (trailing closure) - non-blocking
- 📝 NewsService API integration needed

## Testing

### Manual Testing Checklist
- [ ] Intro screen appears on first launch
- [ ] All 5 tabs navigate correctly
- [ ] Dictionary search and suggestions work
- [ ] Vocabulary progress saves
- [ ] Saved words persist
- [ ] Theme toggle works (light/dark)
- [ ] App renders correctly on all device sizes

### Device Testing
- iPhone 12/13/14/15 (standard & Pro)
- iPad (if supporting larger screens)
- Light and dark modes

## APIs & Services

### Dictionary API
- **Service**: Free Dictionary API
- **Endpoint**: https://api.dictionaryapi.dev/api/v2/entries/en/{word}
- **Features**: Definitions, pronunciations, examples

### Suggestions API  
- **Service**: Datamuse API
- **Endpoint**: https://www.datamuse.com/api/sug
- **Features**: Word autocomplete suggestions

### News API (TODO)
- Current status: Placeholder
- Suggested: NewsAPI, GNews, or Guardian API
- Requirements: ESL-friendly content

## Contributing

### Code Style
- Use Swift naming conventions (camelCase)
- Follow SwiftUI patterns (View protocol)
- Include documentation comments
- Write accessible code (WCAG AA standards)

### Before Committing
- Build succeeds without errors
- Previews render correctly
- Light and dark modes work
- Accessibility features functional
- No new warnings introduced

## Troubleshooting

**Build fails**
- Clear derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/Engify*`
- Update Xcode to latest version

**Preview not loading**
- Check #Preview block syntax
- Verify sample data exists
- Ensure environment objects injected

**API not working**
- Check network connectivity
- Verify API endpoints
- Review error messages in console
- Check for rate limiting

## Future Enhancements

- [ ] Backend authentication
- [ ] Cloud sync across devices
- [ ] Spaced repetition for vocabulary
- [ ] AI-powered pronunciation feedback
- [ ] Real-time multiplayer challenges
- [ ] Offline content support
- [ ] Apple Watch companion app

## License

Proprietary - All rights reserved

## Contact

For questions or issues, see the README files in each folder for detailed documentation on specific areas.
