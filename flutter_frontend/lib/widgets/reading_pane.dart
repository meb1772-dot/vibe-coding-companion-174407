import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/state/book_state.dart';
import 'package:flutter_frontend/models/chapter.dart';

/// Central reading pane that shows the current chapter title and its sections.
/// Uses SelectableText and respects font size from BookState.
// PUBLIC_INTERFACE
class ReadingPane extends StatelessWidget {
  const ReadingPane({super.key});

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookState>();
    final Chapter? ch = book.currentChapter;
    final double baseFont = book.fontSize;
    final cs = Theme.of(context).colorScheme;

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
                SelectableText(
                  section.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: baseFont,
                        height: 1.5,
                      ),
                ),
                // Placeholder for highlight regions / future inline annotations.
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
}
