# Managers

## Overview
Singleton managers that handle app-wide concerns like authentication, theme management, and persistence. These are environment objects injected throughout the app.

## Files & Purpose

### Authentication & Users
- **AuthenticationManager.swift** - Manages login/sign-up and user sessions
  - Handles guest login via `continueAsGuest()`
  - Tracks current user state
  - Mock implementation for development

### Theming & UI
- **ThemeManager.swift** - Manages app theme, colors, and appearance
  - Stores theme preference in UserDefaults
  - Provides accent colors with WCAG AA compliant contrast
  - Supports light and dark modes
  - Observable via `@EnvironmentObject`

### Data Persistence
- **SavedWordsManager.swift** - Manages saved vocabulary words and bookmarks
  - Persists saved words to UserDefaults
  - Provides add/remove/toggle operations
  - Tracks favorite words for quick access

## When to Update

### Adding New Managers
1. Create new `.swift` file in this folder
2. Inherit from `ObservableObject`
3. Use `@Published` for observable state
4. Implement persistence logic if needed
5. Inject in `EngifyApp.swift` as `.environmentObject()`

### Modifying Existing Managers
1. **AuthenticationManager**:
   - Add real backend authentication endpoint
   - Store auth tokens securely in Keychain
   - Add logout functionality
   - Handle token refresh

2. **ThemeManager**:
   - Add new color schemes by extending accent color palette
   - Update color values if branding changes
   - Test all colors in light/dark modes for WCAG compliance

3. **SavedWordsManager**:
   - Add database migration if changing storage format
   - Implement sync with backend
   - Add export/import functionality

### Environment Object Best Practices
- Inject in `EngifyApp.swift` so all views can access
- Access in views via `@EnvironmentObject private var manager: ManagerType`
- Test managers separately from Views
- Keep managers lightweight and focused on single responsibility
