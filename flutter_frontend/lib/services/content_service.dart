import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_frontend/models/chapter.dart';

/// Service responsible for loading book content from bundled assets.
/// Reads a simple index JSON and individual chapter files on demand.
class ContentService {
  ContentService._internal();

  static final ContentService _instance = ContentService._internal();

  // PUBLIC_INTERFACE
  /// Singleton accessor for ContentService.
  static ContentService get instance => _instance;

  List<Chapter>? _chaptersCache;
  Map<String, Chapter> _byIdCache = <String, Chapter>{};

  /// PUBLIC_INTERFACE
  /// Load the index.json which lists available chapters (id and file path).
  /// Returns a map with keys:
  /// - "chapters": list of maps (string to dynamic) with at least the keys: id, title, file
  Future<Map<String, dynamic>> loadIndex() async {
    try {
      final raw = await rootBundle.loadString('assets/content/chapters/index.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'chapters': <dynamic>[]};
    } catch (e, st) {
      if (kDebugMode) {
        // In preview/dev don't crash; log to console.
        // ignore: avoid_print
        print('ContentService.loadIndex error: $e\n$st');
      }
      return <String, dynamic>{'chapters': <dynamic>[]};
    }
  }

  /// PUBLIC_INTERFACE
  /// Load and parse all chapters listed in the index.json.
  /// Employs an in-memory cache to avoid repeated asset reads.
  Future<List<Chapter>> getChapters() async {
    if (_chaptersCache != null) return _chaptersCache!;
    final index = await loadIndex();
    final items = index['chapters'];
    if (items is! List) {
      _chaptersCache = const <Chapter>[];
      _byIdCache = <String, Chapter>{};
      return _chaptersCache!;
    }

    final List<Chapter> chapters = <Chapter>[];
    final Map<String, Chapter> byId = <String, Chapter>{};

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final id = (item['id'] ?? '').toString();
      final file = (item['file'] ?? '').toString();
      if (id.isEmpty || file.isEmpty) continue;

      final chapter = await _loadChapterFromFile(file);
      if (chapter != null) {
        chapters.add(chapter);
        byId[id] = chapter;
      }
    }

    _chaptersCache = chapters;
    _byIdCache = byId;
    return _chaptersCache!;
  }

  /// PUBLIC_INTERFACE
  /// Returns a single chapter by its id. Uses cache if available; otherwise
  /// attempts to load from the file specified in index.json.
  Future<Chapter?> getChapterById(String id) async {
    if (_byIdCache.containsKey(id)) return _byIdCache[id];

    final index = await loadIndex();
    final items = index['chapters'];
    if (items is! List) return null;

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final itemId = (item['id'] ?? '').toString();
      if (itemId != id) continue;
      final file = (item['file'] ?? '').toString();
      if (file.isEmpty) return null;

      final chapter = await _loadChapterFromFile(file);
      if (chapter != null) {
        // Update caches to keep consistent.
        _byIdCache[id] = chapter;
        _chaptersCache = null; // invalidate list cache as order may be unknown
      }
      return chapter;
    }
    return null;
  }

  /// Internal helper to load and parse a chapter JSON file into a Chapter model.
  Future<Chapter?> _loadChapterFromFile(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Chapter.fromJson(decoded);
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('ContentService._loadChapterFromFile("$assetPath") error: $e\n$st');
      }
      return null;
    }
  }

  /// Clears in-memory caches (useful for hot-reload/testing).
  void clearCache() {
    _chaptersCache = null;
    _byIdCache = <String, Chapter>{};
  }
}
