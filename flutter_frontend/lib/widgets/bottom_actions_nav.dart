import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/state/book_state.dart';

/// Bottom actions navigation bar with Previous/Next, Toggle Notes, Bookmark, Font size controls.
/// Uses Material 3 NavigationBar styling from theme.
// PUBLIC_INTERFACE
class BottomActionsNav extends StatelessWidget {
  const BottomActionsNav({super.key, this.onToggleNotes});

  /// Callback to toggle the notes sidebar endDrawer on small screens.
  final VoidCallback? onToggleNotes;

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookState>();
    final canPrev = _hasPrev(book);
    final canNext = _hasNext(book);

    return SafeArea(
      top: false,
      child: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: canPrev ? null : Theme.of(context).disabledColor),
            label: 'Previous',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_add_outlined),
            label: 'Bookmark',
          ),
          const NavigationDestination(
            icon: Icon(Icons.text_increase),
            label: 'A+',
          ),
          const NavigationDestination(
            icon: Icon(Icons.text_decrease),
            label: 'A-',
          ),
          NavigationDestination(
            icon: const Icon(Icons.sticky_note_2_outlined),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_forward_ios_rounded, color: canNext ? null : Theme.of(context).disabledColor),
            label: 'Next',
          ),
        ],
        onDestinationSelected: (index) async {
          switch (index) {
            case 0:
              book.previousChapter();
              break;
            case 1:
              // Simple bookmark toggle feedback. Persisting bookmarks list is out of scope.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark saved')),
              );
              break;
            case 2:
              await book.setFontSize(book.fontSize + 1);
              break;
            case 3:
              await book.setFontSize(book.fontSize - 1);
              break;
            case 4:
              // Toggle notes: on small screens open/close endDrawer via callback; on wide toggle preference.
              if (onToggleNotes != null) {
                onToggleNotes!();
              } else {
                await book.setShowNotesSidebar(!book.showNotesSidebar);
              }
              break;
            case 5:
              book.nextChapter();
              break;
          }
        },
        selectedIndex: 2, // neutral; used as action bar
      ),
    );
  }

  bool _hasPrev(BookState book) {
    final id = book.currentChapterId;
    if (id == null || book.chapters.isEmpty) return false;
    final idx = book.chapters.indexWhere((c) => c.id == id);
    return idx > 0;
  }

  bool _hasNext(BookState book) {
    final id = book.currentChapterId;
    if (id == null || book.chapters.isEmpty) return false;
    final idx = book.chapters.indexWhere((c) => c.id == id);
    return idx >= 0 && idx + 1 < book.chapters.length;
  }
}
