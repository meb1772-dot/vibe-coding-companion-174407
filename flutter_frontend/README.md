# Vibe Coding Companion — Flutter Frontend

An interactive book application that teaches vibe coding. Built with Flutter for mobile and web, featuring local-first annotations and an Ocean Professional theme.

## Project Overview

- Purpose: Provide an engaging, structured reading experience with tools to capture insights.
- Layout: Chapter drawer (left), reading pane (center), notes sidebar (right), bottom quick actions.
- Theme: Ocean Professional (blue and amber accents, subtle shadows, rounded corners).

## Features

- Chapter navigation and automatic section selection.
- Annotations & highlights:
  - Long-press text to create a highlight.
  - Optional note text and color.
  - View/edit/delete via the Notes sidebar.
- Local-first persistence:
  - Mobile/Desktop: SQLite (sqflite).
  - Web: In-memory fallback for annotations; preferences via shared_preferences.
- Notes sidebar: Persistent on wide screens; endDrawer on small screens.
- Adjustable font size (A+/A-), persisted as a preference.
- Bookmarks: Quick feedback via snack bar (non-persistent demo behavior).

## Tech Stack

- Flutter, Material 3
- Provider for state management
- Persistence:
  - sqflite for mobile/desktop annotations
  - shared_preferences for reader settings (all platforms)
  - in-memory fallback for annotations on web
- Theming: Custom ThemeData (lib/theme/ocean_theme.dart)

## Getting Started

From this directory:
1) Install dependencies:
   flutter pub get

2) Run on a device/emulator (mobile/desktop):
   flutter run

3) Web preview on port 3000:
   flutter run -d chrome --web-port 3000

Ensure Flutter SDK is installed and the environment is set up for your target platforms.

## Project Structure

- lib/
  - main.dart: App entry and provider wiring
  - theme/
    - ocean_theme.dart: Ocean Professional theme
  - screens/
    - reader_screen.dart: Main screen with layout and responsiveness
  - state/
    - book_state.dart: Chapters, navigation, prefs (font size, notes sidebar)
    - annotation_state.dart: Annotations cache and actions
  - services/
    - content_service.dart: Loads chapters/index from assets
    - annotation_service.dart: SQLite + web fallback + preferences
  - models/
    - chapter.dart
    - annotation.dart
  - widgets/
    - chapter_drawer.dart
    - reading_pane.dart
    - notes_sidebar.dart
    - bottom_actions_nav.dart
- assets/content/chapters/
  - index.json: Chapter index
  - ch1.json, ch2.json, ch3.json: Chapter content

## Theme: Ocean Professional

- Primary: #2563EB (Blue 600)
- Secondary: #F59E0B (Amber 500)
- Error: #EF4444
- Background: #F9FAFB
- Surface: #FFFFFF
- Text: #111827

Defined in lib/theme/ocean_theme.dart and applied app-wide.

## Local-first and Web-safe Notes

- Mobile/Desktop:
  - Annotations persist in SQLite (sqflite).
  - Preferences (font size, notes sidebar) persist via shared_preferences.
- Web:
  - Annotations stored in an in-memory list for the session.
  - Preferences stored via shared_preferences_web.
  - No additional configuration required; behavior is automatically detected.

## Development Notes

- Follow Effective Dart and the included flutter_lints.
- Async safety: The app avoids using BuildContext across async gaps by updating state first and persisting later.
- No new dependencies are introduced beyond pubspec.yaml.

## Building APK and exporting to repository root

To produce an Android APK and copy it to the repository root with versioned filename:

1) Build the APK:
   - Release: `flutter build apk --release`
   - Debug: `flutter build apk --debug`

2) Copy the latest APK to the repository root:
   - `dart run tool/copy_apk.dart`

The script:
- Prefers a release APK if present, otherwise falls back to debug.
- Searches standard Gradle output folders like:
  - `build/app/outputs/apk/release/` and `build/app/outputs/apk/debug/`
  - ABI split variants (e.g., `app-armeabi-v7a-release.apk`, `app-armeabi-v7a-debug.apk`)
- Reads app version from `pubspec.yaml` (e.g., `version: 1.2.3+45`) and names the copied file:
  - `vibe_coding_companion-v1.2.3-c45.apk`

Notes:
- The script prints the final output path on success.

Convenience Makefile targets are also available:
- `make build-release-apk`
- `make build-debug-apk`
- `make copy-apk`

Happy reading and note-taking!
