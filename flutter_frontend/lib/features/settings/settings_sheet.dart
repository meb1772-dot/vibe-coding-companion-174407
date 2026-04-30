import 'package:flutter/material.dart';

import '../../models/settings_models.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.initialSettings,
    required this.onChanged,
  });

  final AppSettings initialSettings;

  /// Called whenever a setting is changed (synchronously from UI).
  final ValueChanged<AppSettings> onChanged;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppSettings _settings = widget.initialSettings;

  void _update(AppSettings next) {
    setState(() {
      _settings = next;
    });
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 6,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            title: 'Text size',
            subtitle: '${(_settings.fontScale * 100).round()}%',
            child: Slider(
              value: _settings.fontScale,
              min: 0.85,
              max: 1.25,
              divisions: 8,
              label: '${(_settings.fontScale * 100).round()}%',
              onChanged: (v) => _update(_settings.copyWith(fontScale: v)),
            ),
          ),
          const SizedBox(height: 10),
          _SettingCard(
            title: 'Line height',
            subtitle: _settings.lineHeight.toStringAsFixed(2),
            child: Slider(
              value: _settings.lineHeight,
              min: 1.35,
              max: 2.0,
              divisions: 13,
              label: _settings.lineHeight.toStringAsFixed(2),
              onChanged: (v) => _update(_settings.copyWith(lineHeight: v)),
            ),
          ),
          const SizedBox(height: 10),
          _SettingCard(
            title: 'Wide layout',
            subtitle: 'Notes pane on the right',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _settings.showNotesPaneOnWide,
              onChanged: (v) => _update(_settings.copyWith(showNotesPaneOnWide: v)),
              title: const Text('Show notes pane'),
              subtitle: const Text('When the screen is wide enough, keep notes visible.'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(160),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
