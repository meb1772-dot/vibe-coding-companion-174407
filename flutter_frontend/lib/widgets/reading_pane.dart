import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/state/book_state.dart';
import 'package:flutter_frontend/state/annotation_state.dart';
import 'package:flutter_frontend/models/annotation.dart';
import 'package:flutter_frontend/models/chapter.dart';

/// Central reading pane that shows the current chapter title and its sections.
/// - Renders inline highlights from AnnotationState for current chapter
/// - Supports selection-to-annotation via bottom sheet with color choice and note text
/// - Respects font size from BookState.
// PUBLIC_INTERFACE
class ReadingPane extends StatefulWidget {
  const ReadingPane({super.key});

  @override
  State<ReadingPane> createState() => _ReadingPaneState();
}

class _ReadingPaneState extends State<ReadingPane> {

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookState>();
    final Chapter? ch = book.currentChapter;
    final double baseFont = book.fontSize;
    final cs = Theme.of(context).colorScheme;
    final annState = context.watch<AnnotationState>();

    if (book.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ch == null) {
      return Center(
        child: Text(
          'No chapter selected',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ch.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
              ),
              const SizedBox(height: 16),
              for (final section in ch.sections) ...[
                if (section.heading.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(
                      section.heading,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                    ),
                  ),
                // Render body with inline highlights
                _HighlightedSectionText(
                  chapterId: ch.id,
                  sectionId: section.id,
                  body: section.body,
                  baseFont: baseFont,
                  annotations: annState.getForChapter(ch.id)
                      .where((a) => a.sectionId == section.id)
                      .toList(growable: false),
                  onLongPressSelect: (start, end) {
                    _openAddAnnotationSheet(
                      chapterId: ch.id,
                      sectionId: section.id,
                      start: start,
                      end: end,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Shows bottom sheet to add or edit an annotation.
  void _openAddAnnotationSheet({
    required String chapterId,
    required String sectionId,
    required int start,
    required int end,
    Annotation? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final TextEditingController noteCtrl =
            TextEditingController(text: existing?.noteText ?? '');
        Color color = existing?.color ?? const Color(0x66BBDEFB); // default blue 200 w/ alpha

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
                existing == null ? 'Add Annotation' : 'Edit Annotation',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Optional note for this highlight',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Color',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ColorChoice(
                    isSelected: color.toARGB32() == const Color(0x66BBDEFB).toARGB32(),
                    color: const Color(0x66BBDEFB), // blue
                    onTap: () {
                      color = const Color(0x66BBDEFB);
                      Navigator.of(ctx).pop();
                      // reopen to reflect selection; simplest stateless approach
                      _openAddAnnotationSheet(
                        chapterId: chapterId,
                        sectionId: sectionId,
                        start: start,
                        end: end,
                        existing: existing?.copyWith(color: color) ??
                            Annotation.newHighlight(
                              chapterId: chapterId,
                              sectionId: sectionId,
                              startOffset: start,
                              endOffset: end,
                              color: color,
                            ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _ColorChoice(
                    isSelected: color.toARGB32() == const Color(0x66FFF59E).toARGB32(),
                    color: const Color(0x66FFF59E), // amber
                    onTap: () {
                      color = const Color(0x66FFF59E);
                      Navigator.of(ctx).pop();
                      _openAddAnnotationSheet(
                        chapterId: chapterId,
                        sectionId: sectionId,
                        start: start,
                        end: end,
                        existing: existing?.copyWith(color: color) ??
                            Annotation.newHighlight(
                              chapterId: chapterId,
                              sectionId: sectionId,
                              startOffset: start,
                              endOffset: end,
                              color: color,
                            ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (existing != null && existing.id != null)
                    TextButton.icon(
                      onPressed: () async {
                        final anns = context.read<AnnotationState>();
                        // Close before awaiting to avoid using context across async gaps.
                        Navigator.of(ctx).pop();
                        await anns.delete(existing.id!, chapterId: chapterId);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final anns = context.read<AnnotationState>();
                      final String note = noteCtrl.text.trim();
                      // Close sheet synchronously to avoid context across async gap.
                      Navigator.of(ctx).pop();
                      if (existing == null) {
                        final a = Annotation.newHighlight(
                          chapterId: chapterId,
                          sectionId: sectionId,
                          startOffset: start,
                          endOffset: end,
                          color: color,
                          noteText: note,
                        );
                        await anns.add(a);
                      } else {
                        await anns.update(existing.copyWith(
                          noteText: note,
                          color: color,
                        ));
                      }
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

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final bool isSelected;
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
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Renders text with inline highlights using TextSpans and supports long-press selection to create an annotation
class _HighlightedSectionText extends StatelessWidget {
  const _HighlightedSectionText({
    required this.chapterId,
    required this.sectionId,
    required this.body,
    required this.baseFont,
    required this.annotations,
    required this.onLongPressSelect,
  });

  final String chapterId;
  final String sectionId;
  final String body;
  final double baseFont;
  final List<Annotation> annotations;
  final void Function(int start, int end) onLongPressSelect;

  @override
  Widget build(BuildContext context) {
    // Build spans based on annotations (non-overlapping assumed; if overlaps, we render in order)
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    final sorted = [...annotations]
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    for (final a in sorted) {
      final start = a.startOffset.clamp(0, body.length);
      final end = a.endOffset.clamp(0, body.length);
      if (cursor < start) {
        spans.add(TextSpan(text: body.substring(cursor, start)));
      }
      if (start < end) {
        spans.add(TextSpan(
          text: body.substring(start, end),
          style: TextStyle(backgroundColor: a.color),
        ));
        cursor = end;
      }
    }
    if (cursor < body.length) {
      spans.add(TextSpan(text: body.substring(cursor)));
    }

    return GestureDetector(
      onLongPressStart: (details) async {
        // On web/mobile, SelectableText selection to exact offsets is non-trivial.
        // For demo: use a simple heuristic - select a word around the long press by hit-testing position if possible.
        // Fallback: select the entire sentence if word detection is not feasible.
        final RangeValues range = _approximateWordRange(body, details.localPosition, context);
        onLongPressSelect(range.start.round(), range.end.round());
      },
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: baseFont,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          children: spans.isEmpty
              ? [TextSpan(text: body)]
              : spans,
        ),
      ),
    );
  }

  // Approximate a selection range by using pixel position proportion to text length.
  RangeValues _approximateWordRange(String text, Offset localPos, BuildContext context) {
    // Compute rough index by x position proportion since we don't have TextPainter layout hitTest here.
    // This is a simplification. We pick a window around the center index.
    final width = MediaQuery.of(context).size.width;
    final ratio = (localPos.dx / (width <= 1 ? 1 : width)).clamp(0.0, 1.0);
    final idx = (ratio * text.length).round();
    // Expand to nearest spaces
    int start = idx;
    int end = idx;
    while (start > 0 && text[start - 1] != ' ') {
      start--;
    }
    while (end < text.length && text[end] != ' ') {
      end++;
    }
    // Ensure minimum selection length
    if (end - start < 3) {
      end = (start + 10).clamp(0, text.length);
    }
    return RangeValues(start.toDouble(), end.toDouble());
  }
}
