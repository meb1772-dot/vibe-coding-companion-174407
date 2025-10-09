import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/state/book_state.dart';
import 'package:flutter_frontend/state/annotation_state.dart';
import 'package:flutter_frontend/widgets/chapter_drawer.dart';
import 'package:flutter_frontend/widgets/reading_pane.dart';
import 'package:flutter_frontend/widgets/notes_sidebar.dart';
import 'package:flutter_frontend/widgets/bottom_actions_nav.dart';

/// ReaderScreen is the main reading experience screen.
/// Layout:
/// - Left: ChapterDrawer (as a drawer on small screens, persistent on large screens as Scaffold.drawer)
/// - Center: ReadingPane displaying current chapter and sections
/// - Right: NotesSidebar (persistent on wide screens, endDrawer on small)
/// - Bottom: BottomActionsNav with quick actions
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load annotations for current chapter when book state changes selection.
    // We listen in build to avoid async with context after await; use provider watchers.
  }

  void _openEndDrawer() {
    // Open end drawer if present
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookState>();
    final annotations = context.watch<AnnotationState>();
    final cs = Theme.of(context).colorScheme;

    // Ensure annotations for current chapter are loaded.
    final chapterId = book.currentChapterId;
    if (chapterId != null && !annotations.isLoading) {
      // Fire-and-forget to load annotations when chapter changes.
      // No context usage after await inside AnnotationState.
      annotations.loadByChapter(chapterId);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024; // wide threshold
        final showRightPersistent = isWide && book.showNotesSidebar;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Vibe Coding Companion'),
            actions: [
              IconButton(
                tooltip: 'Search',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search coming soon')),
                  );
                },
                icon: const Icon(Icons.search),
                color: cs.primary,
              ),
              const SizedBox(width: 4),
            ],
          ),
          // Left drawer is always available on narrow screens
          drawer: const ChapterDrawer(),
          // Right endDrawer is only used on narrow screens for notes
          endDrawer: isWide ? null : SafeArea(child: const NotesSidebar()),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Optional permanent chapter drawer space for extra wide layouts (>=1280)
                if (constraints.maxWidth >= 1280)
                  SizedBox(
                    width: 300,
                    child: const ChapterDrawer(),
                  ),
                // Center Reading Pane
                Expanded(
                  flex: 3,
                  child: const ReadingPane(),
                ),
                // Right persistent notes sidebar for wide screens (when enabled)
                if (showRightPersistent)
                  Expanded(
                    flex: 2,
                    child: const NotesSidebar(),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: BottomActionsNav(
            onToggleNotes: () async {
              if (isWide) {
                await book.setShowNotesSidebar(!book.showNotesSidebar);
              } else {
                // On small screens open/close the endDrawer
                _openEndDrawer();
              }
            },
          ),
        );
      },
    );
  }
}
