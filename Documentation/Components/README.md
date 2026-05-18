# Components

## Overview
Reusable UI components used across the Engify app. All components are SwiftUI views designed to be modular, accessible, and consistent with the Engify design system.

## Files & Purpose

### Core Components
- **PrimaryButton.swift** - Primary CTA button with press animation, haptics, and disabled state support
- **EngifyLogoView.swift** - Programmatic branded logo component used in IntroView and LoginView
- **EngifyUIComponents.swift** - Collection of reusable UI elements (SearchBar, CardView, EngifySectionHeader, etc.)

### Feedback & Loading
- **ShimmerModifier.swift** - Skeleton loader / shimmer animation for loading states
- **LoadingView.swift** - Full-screen loading indicator
- **ErrorView.swift** - Error state display component

### Cards & Display
- **LearningCard.swift** - Card component for displaying learning content
- **ProgressRing.swift** - Circular progress indicator for vocabulary progress

### Feature-Specific
- **ToggleSaveButton.swift** - Save/unsave bookmark button with animation and haptics
- **EmptyStateView.swift** - Empty state placeholder when no data is available
- **ThemePickerView.swift** - Theme selection UI component

## When to Update

### Adding New Components
1. Create new `.swift` file in this folder
2. Implement `View` protocol with proper SwiftUI structure
3. Add proper accessibility labels
4. Include preview in `#Preview` block
5. Document the component's purpose in this README

### Modifying Existing Components
1. Ensure changes maintain backward compatibility
2. Test all states (normal, disabled, loading, error)
3. Verify animations and haptics work smoothly
4. Check accessibility with VoiceOver

### Design Changes
- If updating colors, fonts, or spacing, check `Design/Spacing.swift` and `Managers/ThemeManager.swift`
- Ensure contrast ratios meet WCAG AA standards
- Test in both light and dark modes
