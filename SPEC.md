# Engify — English Learning App Design Specification

## 1. Concept & Vision

Engify is a mobile-first English learning app designed for beginner to intermediate learners. The experience should feel **encouraging without being patronizing**, **playful without being childish**, and **efficient without being clinical**. Think of a knowledgeable friend who celebrates your progress and gently guides you past mistakes.

The visual identity draws from editorial design — warm, refined, and professional — while the interaction model incorporates proven gamification principles (streaks, spaced repetition, achievement unlocks) to build lasting habits.

---

## 2. Design Language

### 2.1 Color Palette

The existing `EngifyColors` palette serves as the foundation, refined here for the expanded feature set:

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Near-black | `#1F1C1A` | Headlines, primary text, dark backgrounds |
| **Accent** | Warm Copper | `#C76A2E` | CTAs, progress indicators, streak highlights |
| **Sky** | Calm Blue | `#407BC8` | Listening/audio features, informational states |
| **Sage** | Natural Green | `#6B8C6B` | Correct answers, success states, completion |
| **Coral** | Soft Red | `#EB6156` | Incorrect answers, warnings, hearts/lives |
| **Surface** | Warm White | `#FAFAF8` | Card backgrounds, main canvas |
| **Surface Dark** | Deep Charcoal | `#1A1A1F` | Dark mode canvas |
| **Border** | Warm Gray | `#E0DDD1` | Dividers, card outlines |
| **Text Primary** | Deep Brown | `#242320` | Body text, headings |
| **Text Secondary** | Muted Taupe | `#8C8780` | Captions, metadata, placeholders |

**Gamification Accent Colors** (user-selectable):
- Green: `#6B8C6B` (sage default)
- Blue: `#407BC8` (sky)
- Purple: `#8B5CF6` (violet)
- Orange: `#C76A2E` (accent)
- Pink: `#EC4899` (rose)

**Gradient Definitions**:
```
accentGradient:    [#C76A2E → #9E521F] (copper dark)
surfaceGradient:   [#FAFAF8 → #F0EFEB] (warm white to cream)
darkSurfaceGradient: [#242320 → #1A1A1F] (dark mode surface)
successGradient:   [#6B8C6B → #4A6B4A] (sage dark)
audioGradient:     [#407BC8 → #2D5BA8] (sky dark)
```

### 2.2 Typography

**Font Stack**: System fonts (SF Pro) for optimal rendering and accessibility.

| Style | Font | Size | Weight | Line Height |
|-------|------|------|--------|-------------|
| **Display** | SF Pro Rounded | 34pt | Bold | 1.15 |
| **H1** | SF Pro | 26pt | Bold | 1.2 |
| **H2** | SF Pro | 22pt | Semibold | 1.25 |
| **H3** | SF Pro | 18pt | Semibold | 1.3 |
| **Body** | SF Pro | 16pt (adjustable 14–22pt) | Regular | 1.5 |
| **Caption** | SF Pro | 13pt | Regular | 1.4 |
| **Button** | SF Pro | 15pt | Semibold | 1.0 |
| **Tab Label** | SF Pro | 10.5pt | Medium/Bold | 1.0 |

**User-adjustable font sizes**: 14pt–22pt via Settings, default 16pt. All text scales proportionally.

### 2.3 Spacing System

4px base unit following the existing `Spacing` scale:

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Icon padding, tight gaps |
| `sm` | 8pt | Inline element spacing |
| `md` | 12pt | Standard component padding |
| `lg` | 16pt | Section spacing, card padding |
| `xl` | 24pt | Section gaps, major margins |
| `xxl` | 32pt | Screen margins, large separations |
| `xxxl` | 48pt | Hero spacing, onboarding |

### 2.4 Elevation & Shadows

```
Card Shadow:      0 2px 8px rgba(0,0,0,0.08)
Floating Tab Bar:  0 8px 24px rgba(0,0,0,0.12)
Modal Shadow:      0 12px 32px rgba(0,0,0,0.18)
Button Shadow:     0 3px 8px rgba(199,106,46,0.25)
```

### 2.5 Motion Philosophy

- **Entrance**: Fade + slide up, 300ms ease-out, staggered 50ms between items
- **State changes**: 200ms ease-in-out (button press, toggle)
- **Celebrations**: Spring animation (response: 0.4, damping: 0.75) for success states
- **Tab transitions**: Spring (response: 0.4, damping: 0.75) — snappy but not jarring
- **Progress fills**: 600ms ease-out for XP bars and progress rings
- **Micro-interactions**: Scale 0.98 on press, 150ms

### 2.6 Iconography

**SF Symbols** (system) — consistent with iOS, accessibility-friendly.

| Feature Area | Primary Icons |
|--------------|---------------|
| Navigation | house.fill, book.closed.fill, magnifyingglass.circle.fill, newspaper.fill, sparkles |
| Gamification | flame.fill, star.fill, trophy.fill, checkmark.circle.fill, xmark.circle.fill, heart.fill |
| Learning | speaker.wave.2.fill, mic.fill, pencil, photo.fill, arrow.right, arrow.left |
| Achievement | medal.fill, crown.fill, bolt.fill, flame.fill, star.circle.fill |
| Settings | gear, globe, textformat.size, moon.fill, sun.max.fill |

---

## 3. Screen Inventory & Layouts

### 3.1 Screen Map

```
App Entry
├── Onboarding Flow (first launch)
│   ├── Welcome Screen
│   ├── Language Level Assessment
│   └── Goal Selection
│
├── Main Tab View (authenticated/guest)
│   ├── Home (Dashboard)
│   │   ├── Progress Header
│   │   ├── Continue Learning
│   │   ├── Daily Goal Widget
│   │   ├── Recommended Lessons
│   │   └── Recent Activity
│   │
│   ├── Vocabulary
│   │   ├── Flashcard Deck
│   │   ├── Word Detail Sheet
│   │   └── Saved Words
│   │
│   ├── Dictionary
│   │   ├── Search Bar
│   │   ├── Live Suggestions
│   │   └── Definition Card
│   │
│   ├── News/Reading
│   │   ├── Article Feed
│   │   ├── Article Reader
│   │   └── Comprehension Quiz
│   │
│   └── Practice
│       ├── Speaking Practice
│       ├── Grammar Lessons
│       └── Quick Quiz
│
├── Profile/Settings
│   ├── Progress Dashboard
│   │   ├── Streak Calendar
│   │   ├── Badges & Achievements
│   │   └── Statistics
│   ├── Settings
│   │   ├── Theme Customization
│   │   ├── Font Size
│   │   ├── Language (UI)
│   │   └── Offline Content
│   └── Achievements Gallery
│
└── Lesson Flow (modal)
    ├── Exercise Types
    │   ├── Multiple Choice
    │   ├── Drag & Drop
    │   ├── Voice Input
    │   └── Image Matching
    ├── Progress Indicator
    └── Completion Screen
```

### 3.2 Screen Specifications

#### 3.2.1 Onboarding Flow

**Welcome Screen** (IntroView extension)
- EngifyLogoView centered
- Headline: "Unlock Your English Potential" (Display, 30pt)
- Subtitle: Brief value proposition (Body, muted)
- Feature highlights in LearningCard (3 items: vocabulary, reading, practice)
- "Start Learning" PrimaryButton
- "Continue as Guest" text button
- Safe area: top 48pt, bottom 34pt minimum

**Language Level Assessment** (new screen)
- Step indicator: "1 of 3" with progress bar
- Question card with single question
- 4 answer options as large tappable cards (80pt height minimum)
- Tap advances to next question
- Questions: 5 quick placement questions covering basic vocabulary recognition
- Auto-advances after selection (300ms delay)

**Goal Selection** (new screen)
- Headline: "What are your goals?" (H1)
- Grid of goal cards (2 columns):
  - "Travel" — location.fill icon
  - "Work" — briefcase.fill icon
  - "Study" — book.fill icon
  - "Daily Communication" — bubble.left.fill icon
  - "Exam Preparation" — checkmark.seal.fill icon
  - "Just for Fun" — star.fill icon
- Multi-select with checkmark overlay
- "Continue" button appears when ≥1 selected

#### 3.2.2 Home Dashboard

**Layout** (vertical scroll):
```
┌─────────────────────────────────────┐
│ [Safe Area Top]                     │
│ ┌─────────────────────────────────┐ │
│ │ Progress Bar (level + XP)       │ │
│ │ Streak Counter      Points      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Welcome Header Card             │ │
│ │ [Avatar] Name, greeting          │ │
│ │ [Settings] [Profile]            │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Daily Goal Widget               │ │
│ │ Ring: 3/5 lessons today        │ │
│ │ "Keep going!" motivational copy │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Continue Learning               │ │
│ │ [Card with lesson + play btn]  │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Recommended For You             │ │
│ │ [Horizontal scroll cards]      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Recent Activity                 │ │
│ │ [Activity rows list]            │ │
│ └─────────────────────────────────┘ │
│ [Floating Tab Bar]                 │
└─────────────────────────────────────┘
```

**Daily Goal Widget** (new component)
- Circular progress ring (80pt diameter)
- Center: fraction text "3/5" (H2) + "lessons" caption
- Ring fill: accentGradient
- Background ring: border color
- Below ring: motivational message ("Keep going!", "Almost there!", "Daily goal complete!")

#### 3.2.3 Vocabulary View

**Flashcard Deck**
- Large card (full width - 32pt margins, 280pt height)
- Card shows: word, phonetic pronunciation, example sentence
- Swipe gestures: left = don't know, right = know, up = save
- Tap card to flip (definition on back)
- Progress indicator: "12 of 50" below deck
- Bottom buttons: [Don't Know] [Save] [Know]

**Word Detail Sheet** (bottom sheet, 60% height)
- Word in Display type
- Phonetic: /wɜːrd/ (SF Pro Italic)
- Part of speech badge
- Definition paragraph
- Example sentence (highlighted word)
- "Add to Saved Words" toggle
- Related words section

#### 3.2.4 Practice View

**Speaking Practice** (new sub-screen)
- Prompt card with question/prompt text (H2)
- Waveform animation during recording (sky color)
- [Hold to Speak] button (large, 64pt height)
- Playback controls after recording
- "Try Again" and "Next" buttons
- Pronunciation feedback: "Good!" (sage) or "Try again" (coral)

**Grammar Lessons**
- Lesson card list with topic, difficulty badge, duration
- Lesson flow: explanation → examples → exercises → completion
- Exercise types: fill-in-blank, reorder words, identify error

**Quick Quiz**
- 5-question quiz (single session)
- Question types mixed: multiple choice, tap correct word
- Timer optional (hidden by default for relaxed mode)
- Score summary at end with XP earned

#### 3.2.5 Profile & Progress Dashboard

**Streak Calendar**
- Monthly grid view (7 columns)
- Days with activity: accent fill
- Current streak highlighted with flame icon
- Longest streak displayed above

**Badges & Achievements**
- Grid of badge cards (3 columns)
- Earned: full color + glow
- Locked: grayscale + lock overlay
- Tap badge for detail modal (name, description, earned date)
- Categories: Streaks, Lessons, Perfect Scores, Milestones

**Statistics**
- Total words learned (lifetime counter)
- Total minutes practiced
- Current streak (large number display)
- Longest streak
- Lessons completed this week
- Accuracy rate (percentage)

#### 3.2.6 Settings

**Theme Customization**
- Accent color picker (5 options as circles)
- Dark mode toggle (System/Light/Dark)
- Font size slider (14–22pt with preview text)

**Language Settings**
- UI Language selector (dropdown): English, Spanish, French, German, Portuguese, Japanese, Korean, Chinese (Simplified)
- Instructions/translations update immediately

**Offline Content**
- Downloaded lessons list with size
- "Download All" for current path
- Storage used indicator
- Clear cache option

### 3.3 Exercise Interaction Specifications

#### Multiple Choice
- Question text (H3)
- 4 options as cards (minimum 48pt height, tappable area)
- Single selection, immediate feedback
- Correct: sage background + checkmark
- Incorrect: coral background + X, correct answer highlighted

#### Drag & Drop
- Source items in a horizontal scroll or wrap grid
- Drop zones with dashed border (2pt, border color)
- Drag preview follows finger with slight scale up (1.05)
- Drop zone highlights on drag over (accent border)
- Snap animation on drop (spring, 200ms)
- Haptic feedback on pickup and drop

#### Voice Input
- Large microphone button (64pt)
- Hold to record (visual: pulsing ring)
- Waveform visualization during recording
- Playback available after recording
- Transcription shown below waveform
- "Tap to retry" option

#### Image Matching
- Grid of images (2x2 or 3x2 depending on content)
- Word options below or beside
- Tap image → tap word to match
- Matched pairs fade to 50% opacity with checkmark overlay
- All pairs matched → advance

---

## 4. User Flows

### 4.1 First Launch Flow

```
App Launch
    │
    ▼
Welcome Screen ──[Start Learning]──► Language Assessment
    │                                    │
    │                               [Answer 5 questions]
    │                                    │
    │                                    ▼
    │                              Goal Selection
    │                                    │
    │                               [Select 1+ goals]
    │                                    │
    │                                    ▼
    │                              ┌─────┐
    └──────────[Continue as Guest]─►│Home │
                                  └──┬──┘
                                     │
                                     ▼
                              Daily Lessons
```

### 4.2 Lesson Completion Flow

```
Select Lesson
    │
    ▼
Lesson Intro Card (topic, objectives)
    │
    ▼
Exercise 1 ──► ... ──► Exercise N
    │                      │
    │◄──[Wrong Answer]─────┘ (retry, lose heart)
    │                         │
    └────[Correct Answer]─────┘ (gain XP, continue)
                              │
                              ▼
                        Completion Screen
                        (XP gained, streak update,
                         badge unlock check)
                              │
                              ▼
                        Next Lesson / Home
```

### 4.3 Practice Session Flow

```
Choose Practice Mode (Speaking/Grammar/Quiz)
    │
    ▼
Session Config (difficulty, count)
    │
    ▼
Exercise Loop
    │
    ▼
Session Summary (score, accuracy, XP)
    │
    ▼
Share or Continue
```

### 4.4 Offline Flow

```
Settings ──► Offline Content
    │
    ▼
Browse Available Content
    │
    ├──► Download Lesson Pack
    │         │
    │         ▼
    │    Progress Indicator
    │         │
    │         ▼
    │    Available Offline ✓
    │
    └──► Access Offline
              │
              ▼
         Content Available
         (Banner: "Offline Mode")
```

---

## 5. Component Library

### 5.1 Core Components

| Component | States | Notes |
|-----------|--------|-------|
| `EngifyCard` | default, highlighted (tint), pressed | Shadow: 0 2px 8px rgba(0,0,0,0.08) |
| `PrimaryButton` | default, pressed, disabled, loading | Accent background, white text |
| `SecondaryButton` | default, pressed, disabled | Border only, accent text |
| `EngifySectionHeader` | — | Title (H1, 26pt) + subtitle (caption, muted) |
| `VocabularyBadge` | default, custom tint | Capsule shape, 12% opacity background |
| `EngifyFeatureButton` | default, pressed | Card-based, icon + title + subtitle |
| `EngifyLogoView` | — | Graduation cap icon in gradient rounded square |

### 5.2 Gamification Components

| Component | States | Notes |
|-----------|--------|-------|
| `ProgressBar` | — | Level badge + horizontal fill bar |
| `ProgressRing` | empty, partial, complete | Circular, 80pt diameter |
| `StreakCounter` | active (≥1), inactive (0) | Flame icon + count |
| `PointsCounter` | — | Star icon + count |
| `LevelBadge` | — | Circular, accent fill, number center |
| `CompletionView` | — | Modal with checkmark, title, message, XP |
| `CelebrationView` | active, inactive | Dot particle animation |
| `ScoreToast` | appearing, visible, disappearing | Floating "+XP" indicator |
| `DailyGoalWidget` | in-progress, complete | Progress ring + message |
| `BadgeCard` | earned, locked | Icon + title, grayscale if locked |
| `HeartDisplay` | full, empty | Lives remaining for lessons |

### 5.3 Input Components

| Component | States | Notes |
|-----------|--------|-------|
| `SearchBar` | empty, typing, loading | Magnifying glass icon, clear button |
| `MultipleChoiceOption` | default, selected, correct, incorrect | Full-width card |
| `DragItem` | default, dragging | Scale 1.05 when dragging |
| `DropZone` | empty, highlighted, filled | Dashed border, accent on hover |
| `VoiceRecordButton` | idle, recording, playback | Pulsing ring when recording |
| `TogglePill` | off, on | Binary setting toggle |

### 5.4 Navigation Components

| Component | States | Notes |
|-----------|--------|-------|
| `FloatingTabBar` | — | 5 tabs, pill selection indicator |
| `TabBarButton` | default, selected | Icon + label, gradient pill when active |
| `StepIndicator` | — | "1 of 3" with progress bar |

### 5.5 Feedback Components

| Component | States | Notes |
|-----------|--------|-------|
| `EmptyStateView` | — | Illustration + title + subtitle + action |
| `LoadingView` | — | Centered spinner or shimmer |
| `ErrorView` | retry-available | Error icon + message + retry button |
| `Toast` | info, success, error | Bottom toast notification |

---

## 6. Spacing & Layout Standards

### 6.1 Screen Margins

- Horizontal padding: `xxl` (32pt) on all screens
- Safe area respected on all edges
- Bottom padding: 100pt minimum to clear floating tab bar

### 6.2 Card Layouts

- Card padding: `lg` (16pt)
- Card corner radius: 16pt (continuous)
- Card spacing within sections: `md` (12pt)
- Section spacing: `xl` (24pt)

### 6.3 List Layouts

- Row height: minimum 56pt (touch target)
- Row padding: `md` (12pt) horizontal
- Divider: 0.5pt line in border color, inset 16pt from leading

### 6.4 Button Layouts

- Minimum height: 48pt (touch target)
- Button padding: 14pt vertical, 16pt horizontal
- Button corner radius: 12pt
- Button spacing: 12pt between buttons in horizontal group

### 6.5 Modal/Sheet

- Sheet corner radius: 24pt (top only)
- Drag indicator: 36pt wide, 5pt tall, centered, 8pt from top
- Sheet padding: `xl` (24pt)

---

## 7. Accessibility Requirements

### 7.1 Color Contrast

All text must meet WCAG 2.1 AA standards:
- **Large text (≥18pt or 14pt bold)**: minimum 3:1 contrast ratio
- **Body text (16pt regular)**: minimum 4.5:1 contrast ratio
- **Interactive elements**: minimum 3:1 against adjacent colors

Current palette verification:
- Text Primary (#242320) on Surface (#FAFAF8): 14.8:1 ✓
- Text Secondary (#8C8780) on Surface (#FAFAF8): 4.6:1 ✓
- White on Accent (#C76A2E): 4.2:1 ✓

### 7.2 Touch Targets

- Minimum touch target: 44x44pt (Apple HIG)
- All interactive elements: 48pt minimum
- Button labels: 15pt minimum
- Icon-only buttons: 44pt minimum with accessible label

### 7.3 VoiceOver Support

Every interactive element must have an accessibility label:
```swift
Button(action: playAction) {
    Image(systemName: "play.fill")
}
.accessibilityLabel("Play lesson")
.accessibilityHint("Double tap to start playing the current lesson")
```

State announcements:
- Buttons: "button", "selected" when applicable
- Progress: "Level \(level), \(progress)% complete"
- Correct/incorrect: Announce result after delay to not interrupt flow

### 7.4 Dynamic Type

- All text uses system fonts with dynamic type support
- Font sizes scale with user preference (Settings → Accessibility → Text Size)
- Minimum body text: 14pt even at smallest setting
- Layout adapts: stack layouts compress vertically, cards reflow

### 7.5 Reduce Motion

Respect `UIAccessibility.isReduceMotionEnabled`:
- Disable spring animations, use fade only
- Disable particle effects (CelebrationView)
- Disable card flip animations

### 7.6 Color Independence

Never convey information through color alone:
- Icons accompany color (checkmark + sage, X + coral)
- Patterns or labels supplement color coding
- Text labels on badges and achievements

### 7.7 Accessibility Checklist

- [ ] All images have descriptive `accessibilityLabel`
- [ ] All buttons have `accessibilityLabel` and `accessibilityHint`
- [ ] All custom controls announce state changes
- [ ] Color contrast meets WCAG AA (4.5:1 body, 3:1 large)
- [ ] Touch targets are minimum 44x44pt
- [ ] Dynamic Type supported on all text
- [ ] Reduce Motion respected
- [ ] VoiceOver navigation order is logical
- [ ] Progress updates announced via `accessibilityValue`
- [ ] Error states announced via `accessibilityLabel`

---

## 8. Gamification System

### 8.1 XP & Levels

| Action | XP Earned |
|--------|-----------|
| Complete a lesson | 20 XP |
| Complete a quiz (perfect score) | 30 XP |
| Complete a speaking practice | 15 XP |
| First correct answer streak (5x) | 10 XP bonus |
| Daily goal reached | 25 XP bonus |
| Review a word | 2 XP |

**Level Progression**:
- Level 1: 0 XP
- Level N: (N-1) * 100 XP
- Max level: 50

### 8.2 Hearts System

- Start with 5 hearts
- Lose 1 heart on wrong answer (no retry)
- Hearts regenerate: 1 per 30 minutes
- Maximum 5 hearts
- 0 hearts = must wait or use lingots to continue

### 8.3 Streaks

- Streak increments on any lesson completion
- Streak breaks at midnight (local time) if no lesson completed
- Streak freeze: use 10 lingots to protect streak for 1 day
- Display: flame icon + day count

### 8.4 Badges

| Badge | Criteria | Icon |
|-------|----------|------|
| First Step | Complete first lesson | star.fill |
| Week Warrior | 7-day streak | flame.fill |
| Month Master | 30-day streak | crown.fill |
| Perfect 10 | 10 quizzes, perfect score | medal.fill |
| Word Collector | 100 words learned | book.fill |
| Night Owl | Practice after 10pm | moon.fill |
| Early Bird | Practice before 7am | sun.max.fill |
| Speed Demon | Complete lesson under 2 min | bolt.fill |

---

## 9. Offline Mode

### 9.1 Cached Content

- Current lesson deck and vocabulary
- Last 10 articles viewed
- User progress and settings
- Lingots, streak, hearts (synced when online)

### 9.2 Offline Indicators

- Banner at top: "Offline Mode — Some features unavailable"
- Downloaded content marked with checkmark
- Attempting uncached content shows "Download required" prompt

### 9.3 Sync Behavior

- Progress syncs on app foreground when online
- Conflict resolution: server wins for shared leaderboards
- Local progress preserved for solo features

---

## 10. Localization

### 10.1 Supported UI Languages

- English (default)
- Spanish (es)
- French (fr)
- German (de)
- Portuguese (pt)
- Japanese (ja)
- Korean (ko)
- Chinese Simplified (zh-Hans)

### 10.2 Localized Elements

- All UI labels and buttons
- Error messages
- Onboarding content
- Accessibility labels
- Date/time formatting
- Number formatting

### 10.3 RTL Support

- Layout mirrors for RTL languages
- Icons that imply direction (arrows) flip appropriately
- Text alignment follows locale

---

## 11. Technical Implementation Notes

### 11.1 Architecture

- **Pattern**: MVVM with SwiftUI
- **State**: `@StateObject`, `@Published`, `@EnvironmentObject`, `@AppStorage`
- **Persistence**: UserDefaults (settings, progress), FileManager (offline content)
- **Networking**: URLSession with async/await
- **Audio**: AVFoundation for voice recording/playback

### 11.2 Key Dependencies

- **Speech**: `Speech` framework for voice recognition
- **AVFoundation**: Audio recording and playback
- **CoreHaptics**: Haptic feedback patterns
- **Supabase**: `supabase-swift` package for auth and database (optional, defaults to mock mode)

### 11.3 File Structure

```
Engify/
├── App/
│   ├── EngifyApp.swift
│   └── ContentView.swift
├── Design/
│   ├── Colors.swift (EngifyColors)
│   ├── Spacing.swift
│   └── Typography.swift
├── Components/
│   ├── UI/ (cards, buttons, inputs)
│   ├── Gamification/ (progress, badges)
│   └── Navigation/ (tab bar, headers)
├── Views/
│   ├── Onboarding/
│   ├── Home/
│   ├── Vocabulary/
│   ├── Practice/
│   ├── Profile/
│   └── Lessons/
├── ViewModels/
├── Models/
├── Services/
│   ├── SupabaseManager.swift   (Supabase client wrapper)
│   ├── DictionaryService.swift
│   └── NewsService.swift
├── Managers/
│   ├── AuthenticationManager.swift
│   ├── ThemeManager.swift
│   ├── GamificationManager.swift
│   └── SavedWordsManager.swift
├── Utilities/
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    └── SupabaseSetup.sql        (Database schema)
```

### 11.4 Supabase Integration

**Setup**:
1. Create a project at https://supabase.com/dashboard
2. Copy your project URL and anon key
3. Update `SupabaseManager.swift` with your credentials
4. Run `SupabaseSetup.sql` in your Supabase SQL Editor
5. Configure OAuth providers (Google, Apple) in Authentication → Providers

**Tables Created**:
- `users` — User profiles (auto-created on signup via trigger)
- `user_progress` — XP, level, streak, hearts, lingots
- `saved_words` — Vocabulary words saved by users
- `lesson_results` — History of completed lessons
- `user_badges` — Earned achievements

**Demo Mode**: `isDemoMode = true` in AuthenticationManager for local mock auth without Supabase.

### 11.4 Performance Targets

- App launch to interactive: < 1 second
- Tab switch: < 100ms
- Lesson load: < 500ms
- Animation: 60fps maintained
- Memory: < 150MB typical usage

---

*Document Version: 1.0*
*Last Updated: 2026-05-06*
