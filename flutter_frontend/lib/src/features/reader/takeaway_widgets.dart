import 'package:flutter/material.dart';

class TakeawayComposer extends StatefulWidget {
  final String defaultTitle;
  final String prompt;
  final ValueChanged<(String title, String note)> onSubmit;

  const TakeawayComposer({
    super.key,
    required this.defaultTitle,
    required this.prompt,
    required this.onSubmit,
  });

  @override
  State<TakeawayComposer> createState() => _TakeawayComposerState();
}

class _TakeawayComposerState extends State<TakeawayComposer> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _title.text = widget.defaultTitle;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        // Avoid being hidden by keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.edit_note, color: scheme.secondary),
              const SizedBox(width: 10),
              Text('Save a takeaway', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.prompt, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Your note',
              hintText: 'Write it like a future-you instruction…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final String title = _title.text.trim();
                final String note = _note.text.trim();
                widget.onSubmit((title, note));
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Save takeaway'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: keep it tiny and actionable. One sentence is enough.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(160),
                ),
          ),
        ],
      ),
    );
  }
}
