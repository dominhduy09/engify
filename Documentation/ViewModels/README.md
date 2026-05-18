# ViewModels

## Overview
MVVM-pattern view models that handle business logic, state management, and API interactions. Each view model corresponds to a major view and manages its data flow.

## Files & Purpose

### Core ViewModels
- **DictionaryViewModel.swift** - Handles word search, suggestions, definitions, and pronunciation
  - Manages debounced search
  - Fetches definitions from Free Dictionary API
  - Fetches suggestions from Datamuse API
  - Tracks recent searches
  - Observes saved words

- **NewsViewModel.swift** - Manages news articles and reading content
  - Fetches news articles (currently placeholder)
  - Manages reading progress
  - Tracks read articles

## When to Update

### Adding New ViewModels
1. Create new `.swift` file in this folder
2. Inherit from `ObservableObject`
3. Use `@Published` for state that views observe
4. Include proper error handling with `@Published var errorMessage`
5. Use `@StateObject` to instantiate in views

### Modifying Existing ViewModels
1. **DictionaryViewModel**: 
   - Update debounce timing if needed (currently 0.5s)
   - Add new API endpoints by extending `DictionaryService`
   - Maintain search history limit

2. **NewsViewModel**:
   - Hook up real news API (currently placeholder)
   - Add pagination for article list
   - Cache articles for offline access

### API Integration
- Services handle raw API calls (see Services/)
- ViewModels orchestrate data flow and error handling
- Use async/await for network calls
- Include proper error messages for UI display

### State Management Best Practices
- Mark all state properties as `@Published`
- Keep view logic simple, move complexity to ViewModels
- Use `@MainActor` for UI updates
- Test ViewModels separately from Views
