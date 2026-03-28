# Bookend - iOS Journaling App

## Project Overview
A SwiftUI iOS journaling app with morning/evening "bookend" journaling, AI-generated prompts, mood tracking, daily priorities, and streak tracking.

## Architecture
- **Platform**: iOS 17.0+, SwiftUI
- **Data**: Core Data for persistence
- **Structure**: MVVM pattern
  - Models: `DailyEntry`, `Priority`, `Mood`, `Activity`, `TimeOfDay`
  - Services: `DailyEntryManager`, `CoreDataManager`, `StreakManager`, `GeminiService`
  - Views: `DailyView`, `HistoryView`, `JourneyView`, `PromptsLibraryView`, `SettingsView`

## Time-of-Day Split
- **Morning Mode** (5am–5pm): Set intentions, add priorities, capture morning mood/thoughts
- **Evening Mode** (5pm–5am): Review priorities, reflect on the day, track activities and evening mood

## Current Features

### Daily View (Main Tab)
**Morning Content:**
1. Morning mood selection
2. Priorities section with add input (text field + "+" button)
3. Morning thoughts (free-text editor)

**Evening Content:**
1. Priorities review (toggle, edit, delete - NO adding)
2. Evening mood selection
3. Activities tracking (what shaped your day)
4. Evening reflection with AI prompt suggestions

### Priorities Management
- **Add**: Only in morning mode via text field + "+" button or Enter key
- **Toggle**: Tap checkbox to mark complete/incomplete (both modes)
- **Edit**: Tap priority text for inline editing, press Enter or tap checkmark to save
- **Delete**: Long-press for context menu with Edit/Delete options
- Progress counter shows "X/Y" completed

### History View
- Grouped by month, newest first
- Each entry shows: mood journey (morning → evening), priority completion, date, text preview
- Swipe to delete entries
- Tap to view read-only detail view with morning/priorities/evening sections

### Other Features
- Streak tracking (current, longest, total entries)
- Rollover incomplete priorities from previous day (morning prompt)
- AI-generated reflection prompts via Gemini API
- Offline fallback prompts

## UI Guidelines

### DO NOT Remove Features
- Never remove existing UI elements or features unless explicitly requested
- Preserve current functionality when making changes
- Only add/modify what was specifically asked for

### SwiftUI Best Practices
- Avoid mixing `HierarchicalShapeStyle` with `Color` in ternary expressions - use explicit `Color` types
- Always verify Xcode project files are valid
- Use proper type annotations to avoid inference issues

### Color Theme
Uses warm color palette defined in `AppColors.swift`:
- `Color.warmAccent` - primary accent (buttons, highlights)
- `Color.warmCardBackground` - card/input backgrounds
- `Color.warmSecondary` - secondary elements

### Keyboard Handling
- ScrollView uses `.scrollDismissesKeyboard(.interactively)` for native iOS dismissal behavior
- No toolbar "Done" buttons needed - users dismiss by scrolling

## Streak Logic
- Day is marked complete when: `totalCount > 0 && eveningReflection != ""`
- Streak counted once per day when evening reflection is saved
- Only counts if `entry.isCompleted && !entry.streakCounted`

## External Dependencies
- Gemini API for AI prompt generation (model: `gemini-2.5-flash`)
- Core Data for local storage
- No third-party UI frameworks

## Development Guidelines

### When Making Changes
1. Read relevant files first before proposing modifications
2. Test that changes compile and don't break existing functionality
3. Preserve time-of-day logic (morning vs evening behavior)
4. Maintain Core Data relationships and persistence

### Debugging Approach
- After 3 failed attempts at the same fix, STOP and propose alternatives
- Don't guess at API model names or configurations - verify first
- For connectivity issues, check app-level configuration before server settings

## Planned Features (from backlog)
- Paper journaling support (toggle for users who journal offline)
- "Finish Day" button for meaningful completion
- More engaging History page with insights and visualizations
- Priority reordering (drag and drop)
- Weekly/monthly review summaries
- Export/backup functionality
