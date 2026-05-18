# Engify Settings System Audit & Improvements

**Date**: May 14, 2026  
**Scope**: Toggle functionality, state persistence, UX, production readiness

---

## 1. CURRENT PROBLEMS

### 1.1 State Management Issues

| Problem | Severity | Impact |
|---------|----------|--------|
| **No rollback on write failure** | HIGH | User changes setting, write fails silently, UI shows change but setting not persisted |
| **Missing validation on load** | HIGH | Corrupted UserDefaults value crashes app on read or creates invalid state |
| **No permission checks** | HIGH | Notification/microphone toggles work in UI but fail at runtime without user feedback |
| **Settings scattered across views** | MEDIUM | @AppStorage in SettingsView + @Published in managers = inconsistent patterns |
| **No error boundaries** | MEDIUM | Settings crash if encoding/decoding fails; no recovery mechanism |
| **No loading states** | MEDIUM | Toggles that affect backend are instant in UI but may fail async |
| **Notification settings without system check** | HIGH | User enables reminders but system notifications are globally disabled |
| **Microphone access without permission request** | HIGH | Speaking toggles work but speech fails at runtime |
| **No defaults for first launch** | MEDIUM | Missing keys in UserDefaults = app uses hardcoded defaults instead of user intent |

### 1.2 Broken or Weak Toggles

#### **Dark Mode Toggle**
- **Current**: ThemeManager stores in UserDefaults
- **Problem**: No validation; if corrupted, defaults to system but user doesn't know their preference was lost
- **Fix**: Add try-catch wrapper, fallback to `.system`

#### **Notifications Toggle** (NEW in SettingsView)
- **Current**: @AppStorage stores locally
- **Problem**: No check if user granted system notification permission; toggle succeeds but notifications never arrive
- **Missing**: Permission check + request flow + informative UX when denied
- **Fix**: Wrap in permission check; show "Open Settings" button if denied

#### **Daily Reminder Toggle** (NEW)
- **Current**: @AppStorage only
- **Problem**: No connection to UNUserNotificationCenter; just a setting, not a scheduler
- **Missing**: Actual scheduled notification registration
- **Fix**: Tie to notification manager that schedules/cancels notifications

#### **Microphone / Voice Toggles** (NEW)
- **Current**: @AppStorage only
- **Problem**: No AVAudioSession request; no AVCaptureDevice permission check
- **Missing**: Permission request flow + feedback when denied
- **Fix**: Request permission on first toggle; show status badge

#### **Voice History Toggle** (NEW)
- **Current**: @AppStorage only
- **Problem**: If disabled, no mechanism to delete existing recordings
- **Missing**: Cleanup of stored voice files
- **Fix**: Add cleanup handler; show confirmation + space freed

#### **AI Tutor Customization** (NEW)
- **Current**: @AppStorage stores strings
- **Problem**: No validation that tutor actually respects these settings (no backend integration yet)
- **Missing**: Verification that settings affect tutor behavior
- **Fix**: Add enum validation + comment linking to backend integration

#### **Review Limits Sliders** (NEW)
- **Current**: @AppStorage stores Int directly
- **Problem**: No validation of range; if corrupted value is loaded, slider range is wrong
- **Missing**: Bounds checking on read
- **Fix**: Validate against expected range; reset to default if out of bounds

### 1.3 Missing Toggles (Common in Top Learning Apps)

| Toggle | Purpose | Users Affected |
|--------|---------|-----------------|
| **Speak Slower** | Reduce playback speed | Beginners, slow processors |
| **Show Grammar Corrections** | Inline grammar hints | Grammar-focused learners |
| **Repeat Pronunciation** | Auto-replay word audio | Auditory learners |
| **Daily Streak Reminders** | Protect streak habitPower users |
| **Translation Mode** | Toggle English ↔ Native | Intermediate learners |
| **Exam Mode** | Stricter scoring, timer | Test preppers (IELTS/TOEFL) |
| **Offline Mode** | Download content locally | Travelers, unreliable internet |
| **AI Chat History** | Save conversations | Learners reviewing progress |
| **Correction Intensity** | How much feedback | Varies by proficiency |
| **Sound Effects** | Toggle UI feedback sounds | Quiet learners, accessibility |
| **Haptic Feedback** | Device vibration | Accessibility, battery saving |
| **Text-to-Speech Voice** | Choose TTS accent/gender | Preference, pronunciation model |
| **Reading Speed** | Adjust narration tempo | Varies by proficiency |
| **Show Definitions By Default** | Pre-expand word details | Advanced learners |
| **Difficulty Lock** | Prevent level jumping | Structured learners |

---

## 2. TECHNICAL FIXES (Implementation Plan)

### 2.1 Create a Robust Settings Manager

Replace scattered @AppStorage and manual UserDefaults with a single, validated manager:

```swift
@MainActor
final class LearningSettingsManager: ObservableObject {
    @Published var learningGoal: String { didSet { save() } }
    @Published var explanationDepth: String { didSet { save() } }
    @Published var notificationsEnabled: Bool { didSet { save(); updateNotifications() } }
    @Published var dailyReminderTime: Date { didSet { save(); scheduleNotifications() } }
    @Published var microphoneEnabled: Bool { didSet { save(); checkMicPermission() } }
    
    init() {
        // Load with validation and fallbacks
        self.learningGoal = Self.load("goal", default: "daily") ?? "daily"
        self.explanationDepth = Self.load("depth", default: "balanced") ?? "balanced"
        // ...
    }
    
    private func save() {
        // Try encode and write; log failure
        // Validate on read; reset to default if invalid
    }
}
```

### 2.2 Add Permission Helpers

```swift
enum PermissionStatus {
    case notRequested
    case granted
    case denied
    case restricted
}

extension AVCaptureDevice {
    static func checkMicrophonePermission() async -> PermissionStatus
    static func requestMicrophonePermission() async -> PermissionStatus
}

extension UNUserNotificationCenter {
    static func checkNotificationPermission() async -> PermissionStatus
    static func requestNotificationPermission() async -> PermissionStatus
}
```

### 2.3 Validate Settings on Load

```swift
private func validateLearningGoal(_ value: String) -> String {
    let valid = ["daily", "travel", "work", "study", "exam"]
    return valid.contains(value) ? value : "daily"
}

private func validateReviewLimit(_ value: Int) -> Int {
    let clamped = max(5, min(40, value))
    return clamped
}
```

### 2.4 Add Error Recovery & Logging

```swift
private func save() {
    do {
        let data = try JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: "engify.settings")
    } catch {
        // Log to analytics + show non-blocking toast
        Analytics.logError("Settings save failed: \(error)")
    }
}
```

### 2.5 Tie Toggles to Actual Feature Gates

- **notificationsEnabled** → Actually cancel scheduled notifications via UNUserNotificationCenter
- **dailyReminderTime** → Schedule a repeating notification
- **microphoneEnabled** → Request AVAudioSession category
- **voiceHistoryEnabled** → Clean up stored recordings if toggled off
- **showDefinitions** → Pass to DictionaryView rendering logic

---

## 3. UX IMPROVEMENTS

### 3.1 Better Labels & Descriptions

**Before**: "Generate extra examples"  
**After**: "Show example sentences when I tap a word (helps understand context)"

**Before**: "Reduce motion"  
**After**: "Minimize animations and transitions (uses less battery, easier on eyes)"

### 3.2 Confirmation for Destructive Actions

```swift
if voiceHistoryEnabled == false {
    // Show alert: "Delete all recorded voice history?"
    // Confirm: "This cannot be undone"
    // Action: Delete files + show "Freed X GB"
}
```

### 3.3 Permission Status Badges

```
🎤 Microphone   [Granted] [✓]
🔔 Notifications [Denied] [Request] 
📱 Camera       [Not Requested] [Ask]
```

### 3.4 Smart Defaults

- **New user**: Max 8 new words/day, 15 reviews, gentle correction, balanced explanations
- **Power user** (>100 days): Suggest increasing to 12 new words, strict correction
- **Returning user**: Offer to resume last settings or reset

### 3.5 Settings Presets

```
[ Quick Setup ]
- Beginner: 5 new/day, gentle, simple explanations
- Intermediate: 10 new/day, balanced, balanced explanations
- Advanced: 15 new/day, strict, detailed explanations
```

### 3.6 Better Organization

**Current**: Vertical list of all settings  
**Better**:
```
┌─────────────────────────┐
│ Your Learning Profile   │
│ Goal: Daily Comm. ◆     │
│ Level: Beginner ◆       │
└─────────────────────────┘

┌─────────────────────────┐
│ AI Tutor                │
│ Explanation Depth ◆     │
│ Correction Style ◆      │
│ Extra Examples [Toggle] │
└─────────────────────────┘

┌─────────────────────────┐
│ Learning Habits         │
│ New Words/Day [Slider]  │
│ Reviews/Day [Slider]    │
│ Daily Reminder [Toggle] │
└─────────────────────────┘

┌─────────────────────────┐
│ Features                │
│ Microphone [Status]     │
│ Notifications [Status]  │
│ Voice History [Toggle]  │
└─────────────────────────┘
```

### 3.7 Accessibility Improvements

- Add `@AccessibilityLabel` and `@AccessibilityValue` to every toggle
- Make sliders announce current value when adjusted
- Increase minimum tap target to 44x44 pts
- Add `.reduceTransparency` support
- Ensure 4.5:1 contrast on all text

### 3.8 Loading & Feedback States

```swift
@State var isSaving = false

Toggle(isOn: Binding(
    get: { notificationsEnabled },
    set: { newValue in
        isSaving = true
        Task {
            await requestNotificationPermission()
            withAnimation { isSaving = false }
        }
    }
))
.disabled(isSaving)
.overlay(alignment: .trailing) {
    if isSaving {
        ProgressView().scaleEffect(0.8)
    }
}
```

---

## 4. SUGGESTED NEW TOGGLES

### Critical (Phase 1)
- **[Toggle] Notifications Enabled** with permission check
- **[Toggle] Daily Reminder** with time picker
- **[Toggle] Microphone Access** with permission check
- **[Dropdown] Speaking Speed** (normal, slow, very slow)
- **[Toggle] Show Definitions By Default** (Dictionary tab)
- **[Dropdown] Pronunciation Model** (US English, UK English, etc.)

### High-Value (Phase 2)
- **[Toggle] Save Chat History** (for AI tutor conversations)
- **[Toggle] Sound Effects** (UI feedback sounds)
- **[Toggle] Haptic Feedback** (device vibration)
- **[Toggle] Show Grammar Corrections** (inline hints)
- **[Slider] AI Correction Intensity** (how strict)
- **[Toggle] Repeat Pronunciation** (auto-replay)
- **[Toggle] Difficulty Lock** (prevent jumping levels)
- **[Dropdown] Text-to-Speech Voice** (choose accent)

### Nice-to-Have (Phase 3)
- **[Toggle] Translation Mode** (show native alongside)
- **[Toggle] Exam Mode** (stricter, timed)
- **[Toggle] Offline Mode** (download content)
- **[Toggle] Dark Mode** (already have, but could improve)
- **[Slider] Reading Speed** (narration tempo)
- **[Toggle] Show Vocabulary Frequency** (word usage stats)

---

## 5. PRODUCTION-LEVEL ARCHITECTURE

### 5.1 Single Source of Truth

```swift
// In EngifyApp
@StateObject private var settings = LearningSettingsManager()
.environmentObject(settings)

// Every view accesses settings via environment object
@EnvironmentObject var settings: LearningSettingsManager
```

### 5.2 Feature Flags

```swift
struct FeatureFlags {
    var notificationsSupported: Bool { 
        UIDevice.current.systemVersion >= "10.0" 
    }
    var microphoneSupported: Bool { 
        AVCaptureDevice.authorizationStatus(for: .audio) != .denied 
    }
    var offlineSupported: Bool { 
        #available(iOS 13, *) 
    }
}
```

### 5.3 Analytics Integration

```swift
func logSettingChange(key: String, oldValue: Any, newValue: Any) {
    Analytics.logEvent("setting_changed", parameters: [
        "setting": key,
        "new_value": String(describing: newValue),
        "user_level": settings.learningGoal
    ])
}
```

### 5.4 Migration Strategy (For Future Updates)

```swift
// If you rename a setting:
private func migrateSettings() {
    if let oldValue = UserDefaults.standard.value(forKey: "old_key") {
        UserDefaults.standard.set(oldValue, forKey: "new_key")
        UserDefaults.standard.removeObject(forKey: "old_key")
    }
}
```

### 5.5 Testing Strategy

```swift
// Unit test: settings persist across app restart
func testSettingPersistence() {
    settings.learningGoal = "exam"
    // Simulate app terminate and launch
    let newSettings = LearningSettingsManager()
    XCTAssertEqual(newSettings.learningGoal, "exam")
}

// Unit test: invalid values are rejected
func testValidation() {
    let invalid = LearningSettingsManager(learningGoal: "invalid")
    XCTAssertEqual(invalid.learningGoal, "daily")  // Falls back to default
}

// Unit test: permissions are checked
func testMicPermissionCheck() {
    settings.microphoneEnabled = true
    let status = await AVCaptureDevice.checkMicrophonePermission()
    XCTAssertEqual(status, .granted)
}
```

### 5.6 Cloud Sync (Future)

```swift
@MainActor
final class CloudSyncManager {
    func syncSettingsToCloud() async throws {
        let settings = try JSONEncoder().encode(userSettings)
        try await supabaseClient
            .from("user_settings")
            .upsert(settings)
            .execute()
    }
    
    func resolveConflict(local: Settings, remote: Settings) -> Settings {
        // Remote always wins (most recent device update)
        // or user chooses manually
    }
}
```

---

## 6. EDGE CASES & HANDLING

| Scenario | Current Behavior | Fix |
|----------|------------------|-----|
| **User denies notification permission** | Toggle works, notifications never arrive | Check permission before enabling; show "Ask System" button |
| **User denies microphone permission** | Toggle works, speech fails at runtime | Check permission; disable toggle if denied |
| **Settings file corrupted** | App may crash | Try-catch on read; log error; use defaults |
| **Offline when saving setting** | Assuming it saves, but doesn't sync later | Queue change; attempt resync on next connection |
| **User has multiple devices** | Settings don't sync | Build cloud sync with conflict resolution |
| **App crashes during settings write** | Half-written settings; undefined state | Use atomic writes (write to temp, then swap) |
| **User disables notifications but forgot why** | Hard to undo | Show "Why disable this?" with explanation |
| **Settings screen is slow** | Sliders lag while user adjusts | Debounce slider changes; defer save |
| **User changes 10 settings rapidly** | Each change writes to disk immediately | Batch writes; save every 2 seconds if changed |
| **Low storage space** | Voice history takes up space silently | Show storage usage; warn when >100MB |

---

## 7. RECOMMENDED ROADMAP

### **Week 1: Stabilize**
- [ ] Create `LearningSettingsManager` with validation
- [ ] Add error recovery for corrupted settings
- [ ] Add permission checks for notifications/microphone
- [ ] Improve labels and descriptions
- [ ] Add loading states for async toggles

### **Week 2: Add Missing Toggles**
- [ ] Daily reminder with time picker
- [ ] Speaking speed selector
- [ ] Pronunciation model dropdown
- [ ] Sound effects toggle
- [ ] Haptic feedback toggle

### **Week 3: Polish UX**
- [ ] Settings presets (Beginner, Intermediate, Advanced)
- [ ] Permission status badges
- [ ] Confirmation dialogs for destructive actions
- [ ] Accessibility improvements
- [ ] Better organization into collapsible sections

### **Week 4: Monitor & Iterate**
- [ ] Add analytics logging
- [ ] Monitor crash reports
- [ ] Collect user feedback
- [ ] A/B test settings defaults
- [ ] Plan cloud sync architecture

---

## 8. SUCCESS METRICS

- **Toggle persistence**: 99.9% of settings survive app restart
- **Permission handling**: 95%+ of permission requests succeed (or user understands why denied)
- **Error recovery**: 0 app crashes from corrupted settings
- **User satisfaction**: Settings feel intuitive and powerful (Net Promoter Score > 8/10)
- **Adoption**: Users enable 5+ learning-related toggles on average
- **Retention**: Users who customize settings have 2x higher 30-day retention

---

## 9. CODE LOCATIONS TO UPDATE

| File | Current | Improve |
|------|---------|---------|
| `SettingsView.swift` | @AppStorage scattered | Centralize via manager |
| `ThemeManager.swift` | Good but could validate | Add type-safe validation |
| `EngifyApp.swift` | Injects managers | Inject LearningSettingsManager |
| **(NEW)** `LearningSettingsManager.swift` | Doesn't exist | Create robust manager |
| **(NEW)** `PermissionManager.swift` | Doesn't exist | Handle all permissions |
| **(NEW)** `SettingsPresets.swift` | Doesn't exist | Define beginner/intermediate/advanced |
| `Components/` | No settings UI | Keep using new components |

