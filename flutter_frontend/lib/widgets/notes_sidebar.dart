import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/state/book_state.dart';
import 'package:flutter_frontend/state/annotation_state.dart';
import 'package:flutter_frontend/models/annotation.dart';

/// Right-hand sidebar (or endDrawer content) displaying annotations/notes for the current chapter.
/// - Tap to focus/highlight selection in the ReadingPane (simple snackbar feedback for now)
/// - Edit and delete notes via a sheet
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
                          // For now show feedback; the _HighlightedSectionText renders it already.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Focused note ${a.id ?? '-'} (${a.startOffset}-${a.endOffset})')),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showEditSheet(context, a);
                            } else if (value == 'delete') {
                              final ok = await context.read<AnnotationState>().delete(a.id!, chapterId: chapterId);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Delete failed')),
                                );
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, Annotation a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final TextEditingController ctrl = TextEditingController(text: a.noteText);
        Color color = a.color;
        final cs = Theme.of(ctx).colorScheme;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Annotation',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Color',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ColorDot(
                    selected: color.toARGB32() == const Color(0x66BBDEFB).toARGB32(),
                    color: const Color(0x66BBDEFB),
                    onTap: () {
                      color = const Color(0x66BBDEFB);
                    },
                  ),
                  const SizedBox(width: 12),
                  _ColorDot(
                    selected: color.toARGB32() == const Color(0x66FFF59E).toARGB32(),
                    color: const Color(0x66FFF59E),
                    onTap: () {
                      color = const Color(0x66FFF59E);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final anns = context.read<AnnotationState>();
                      await anns.update(a.copyWith(noteText: ctrl.text.trim(), color: color));
                      if (context.mounted) Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
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
