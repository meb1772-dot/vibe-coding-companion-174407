import 'dart:convert';

/// Reader preferences and app-level settings.
///
/// Stored via [LocalPersistenceService] using SharedPreferences.
/// Designed to be forward-compatible with versioned storage keys.
class AppSettings {
  const AppSettings({
    required this.fontScale,
    required this.lineHeight,
    required this.showNotesPaneOnWide,
    required this.bookmarkedSectionIds,
  });

  final double fontScale;
  final double lineHeight;
  final bool showNotesPaneOnWide;

  /// Section IDs bookmarked by the user.
  final List<String> bookmarkedSectionIds;

  AppSettings copyWith({
    double? fontScale,
    double? lineHeight,
    bool? showNotesPaneOnWide,
    List<String>? bookmarkedSectionIds,
  }) {
    return AppSettings(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      showNotesPaneOnWide: showNotesPaneOnWide ?? this.showNotesPaneOnWide,
      bookmarkedSectionIds: bookmarkedSectionIds ?? this.bookmarkedSectionIds,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'fontScale': fontScale,
        'lineHeight': lineHeight,
        'showNotesPaneOnWide': showNotesPaneOnWide,
        'bookmarkedSectionIds': bookmarkedSectionIds,
      };

  static AppSettings fromJson(Map<String, Object?> json) {
    final Object? rawBookmarks = json['bookmarkedSectionIds'];
    final List<String> bookmarks = rawBookmarks is List
        ? rawBookmarks.whereType<String>().toList(growable: false)
        : const <String>[];

    return AppSettings(
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
      showNotesPaneOnWide: (json['showNotesPaneOnWide'] as bool?) ?? true,
      bookmarkedSectionIds: bookmarks,
    );
  }

  static String encode(AppSettings settings) => jsonEncode(settings.toJson());

  static AppSettings decode(String raw) {
    final Object decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const AppSettings(
        fontScale: 1.0,
        lineHeight: 1.6,
        showNotesPaneOnWide: true,
        bookmarkedSectionIds: <String>[],
      );
    }
    return AppSettings.fromJson(decoded.cast<String, Object?>());
  }
}
