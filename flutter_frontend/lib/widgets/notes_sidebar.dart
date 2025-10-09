import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/state/book_state.dart';
import 'package:flutter_frontend/state/annotation_state.dart';
import 'package:flutter_frontend/models/annotation.dart';

/// Right-hand sidebar (or endDrawer content) displaying annotations/notes for the current chapter.
/// Allows selecting an item (placeholder tap behaviour).
// PUBLIC_INTERFACE
class NotesSidebar extends StatelessWidget {
  const NotesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookState>();
    final annotations = context.watch<AnnotationState>();
    final chapterId = book.currentChapterId;
    final cs = Theme.of(context).colorScheme;

    if (chapterId == null) {
      return _decoratedContainer(
        context: context,
        child: const Center(child: Text('Open a chapter to see notes')),
      );
    }

    final list = annotations.getForChapter(chapterId);

    return _decoratedContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  )),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'No annotations yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final Annotation a = list[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 10,
                          backgroundColor: a.color,
                        ),
                        title: Text(
                          a.noteText.isNotEmpty ? a.noteText : 'Highlight (${a.startOffset}-${a.endOffset})',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Section: ${a.sectionId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () {
                          // Placeholder: future step will handle jump/edit/delete.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected note ${a.id ?? '-'}')),
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                // Placeholder for adding notes
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add note coming soon')),
                );
              },
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add Note'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decoratedContainer({required BuildContext context, required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16, left: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
