# Vibe Coding Companion

A comprehensive and engaging full book application built with Flutter, explaining vibe coding in detail. The app provides an interactive reading experience with chapters, annotations, a notes sidebar, adjustable font sizes, and bookmarks, all wrapped in the Ocean Professional theme.

This repository contains:
- flutter_frontend: The Flutter application for mobile and web.

## Project Overview

Vibe Coding Companion is designed to teach and explore vibe coding concepts for beginners and advanced users alike. It provides a book-style layout for immersive reading and note-taking:
- Left: Chapter navigation drawer
- Center: Reading pane
- Right: Notes/Annotations sidebar
- Bottom: Quick actions navigation

## Features

- Chapter navigation: Browse and switch between chapters, with automatic section selection.
- Annotations and highlights: Long-press text to create highlights with optional note text and color tags.
- Local-first persistence:
  - Mobile/Desktop: Annotations saved in SQLite via sqflite.
  - Web: In-memory fallback for annotations with UI preferences stored in shared_preferences.
- Notes sidebar: View, edit, and delete annotations for the current chapter.
- Adjustable font size: A+/A- quick actions to tune reading comfort; saved as a preference.
- Bookmarks: Simple bookmark UX feedback (non-persistent) via the bottom action bar.
- Ocean Professional theme: Modern, clean design using blue (#2563EB) and amber (#F59E0B) accents, subtle shadows, and rounded corners.

## Tech Stack

- Flutter (mobile and web)
- State management: Provider
- Persistence:
  - sqflite (mobile/desktop) for annotation storage
  - shared_preferences for reader preferences (font size, notes sidebar)
  - In-memory fallback for annotations on web
- Theming: Ocean Professional theme with custom ColorScheme and Material 3 components

## Run Instructions

Navigate to the Flutter app folder:
cd flutter_frontend

Install dependencies:
flutter pub get

Run on mobile or desktop:
flutter run

Run on web (Chrome) with preview on port 3000:
flutter run -d chrome --web-port 3000

Note: Ensure you have Flutter installed and set up for your target platforms.

## Project Structure (high-level)

- flutter_frontend/
  - lib/
    - main.dart: App entry, providers wiring, and route setup
    - theme/ocean_theme.dart: Ocean Professional ThemeData
    - screens/reader_screen.dart: Main layout (drawer, reading pane, notes, bottom actions)
    - state/: App and annotation state (Provider)
      - book_state.dart
      - annotation_state.dart
    - services/: Data and persistence services
      - content_service.dart (loads chapters from assets)
      - annotation_service.dart (annotations store + preferences)
    - models/:
      - chapter.dart
      - annotation.dart
    - widgets/:
      - chapter_drawer.dart
      - reading_pane.dart
      - notes_sidebar.dart
      - bottom_actions_nav.dart
  - assets/content/chapters/: JSON content for chapters and index

## Local-first and Web Behavior

- Mobile/Desktop:
  - Annotations persist in a local SQLite database (sqflite).
  - Reader preferences (font size, notes sidebar visibility) persist via shared_preferences.

- Web:
  - sqflite is not available; annotations are stored in memory for the session.
  - Reader preferences persist via shared_preferences_web.
  - No additional configuration is required; the app automatically uses web-safe fallbacks.

## Theming: Ocean Professional

- Primary color: #2563EB (Blue 600)
- Secondary/Accent: #F59E0B (Amber 500)
- Error: #EF4444 (Red 500)
- Background: #F9FAFB (Gray-50)
- Surface: #FFFFFF
- Text: #111827
- Design: Modern, minimalist, rounded corners, subtle shadows, Material 3 components.

## Repository Notes

- No new dependencies have been introduced beyond those already listed in flutter_frontend/pubspec.yaml.
- Minor analyzer warnings are addressed in code with comments and safe async patterns to avoid using context across async gaps.

For more details, see flutter_frontend/README.md inside the app directory.