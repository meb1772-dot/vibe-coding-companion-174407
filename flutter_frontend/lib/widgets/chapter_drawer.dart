import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/state/book_state.dart';
import 'package:flutter_frontend/models/chapter.dart';

/// Drawer/Side panel listing all chapters, allowing users to select a chapter.
/// Uses BookState to read chapters and update current selection.
// PUBLIC_INTERFACE
class ChapterDrawer extends StatelessWidget {
  const ChapterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookState>();
    final chapters = book.chapters;
    final currentId = book.currentChapterId;
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Chapters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemBuilder: (context, index) {
                  final Chapter ch = chapters[index];
                  final bool selected = ch.id == currentId;
                  return ListTile(
                    selected: selected,
                    leading: Icon(
                      Icons.menu_book_outlined,
                      color: selected ? cs.primary : Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      ch.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? cs.primary : null,
                          ),
                    ),
                    onTap: () {
                      // Update current chapter immediately.
                      context.read<BookState>().setCurrentChapter(ch.id);
                      // Close if it's a modal drawer; Scaffold.maybeOf handles absence gracefully.
                      final scaffold = Scaffold.maybeOf(context);
                      if (scaffold?.isDrawerOpen == true) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: chapters.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
