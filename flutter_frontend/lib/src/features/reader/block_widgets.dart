import 'package:flutter/material.dart';
import 'package:vibe_coding_companion/src/book/book_models.dart';

typedef BlockActionCallback = void Function(String blockId);

class BlockCard extends StatelessWidget {
  final Widget child;
  final Color? highlightColor;
  final bool bookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onCycleHighlight;

  const BlockCard({
    super.key,
    required this.child,
    required this.highlightColor,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onCycleHighlight,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color? hl = highlightColor;

    return Card(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hl == null
              ? null
              : LinearGradient(
                  colors: <Color>[
                    hl.withAlpha(34),
                    scheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
                    onPressed: onToggleBookmark,
                    icon: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: bookmarked ? scheme.secondary : null,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Highlight',
                    onPressed: onCycleHighlight,
                    icon: const Icon(Icons.format_color_fill),
                  ),
                  const Spacer(),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class HeadingBlock extends StatelessWidget {
  final String title;
  final String? text;

  const HeadingBlock({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (text != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(text!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class ParagraphBlock extends StatelessWidget {
  final String text;
  const ParagraphBlock({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class CalloutBlock extends StatelessWidget {
  final String title;
  final String text;

  const CalloutBlock({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }
}

class ChecklistBlock extends StatelessWidget {
  final String title;
  final List<String> items;

  const ChecklistBlock({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        ...items.map(
          (String it) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.check_circle_outline, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(it)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PromptBlock extends StatelessWidget {
  final String title;
  final String text;

  const PromptBlock({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.edit_note, color: scheme.secondary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Text(text),
      ],
    );
  }
}

class CodeBlock extends StatelessWidget {
  final String title;
  final String language;
  final String code;

  const CodeBlock({
    super.key,
    required this.title,
    required this.language,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '$language',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code.trimRight(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizBlock extends StatelessWidget {
  final BookBlock block;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const QuizBlock({
    super.key,
    required this.block,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<QuizOption> opts = block.options ?? <QuizOption>[];
    final int? correct = block.correctIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if ((block.title ?? '').isNotEmpty)
          Text(block.title!, style: Theme.of(context).textTheme.titleSmall),
        if ((block.text ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(block.text!),
        ],
        const SizedBox(height: 12),
        ...List<Widget>.generate(opts.length, (int i) {
          final QuizOption opt = opts[i];
          final bool selected = selectedIndex == i;

          final bool showResult = selectedIndex != null;
          final bool isCorrect = correct != null && i == correct;

          Color? border;
          if (showResult) {
            border = isCorrect ? scheme.secondary : scheme.error;
            if (!selected) border = border.withAlpha(50);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: selectedIndex == null ? () => onSelect(i) : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: border ?? Colors.black.withAlpha(18),
                  ),
                  color: selected
                      ? scheme.primary.withAlpha(10)
                      : scheme.surface,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(opt.text)),
                    if (showResult && selected)
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? scheme.secondary : scheme.error,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (selectedIndex != null && (block.explanation ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondary.withAlpha(14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.secondary.withAlpha(30)),
            ),
            child: Text(block.explanation!),
          ),
        ],
      ],
    );
  }
}
