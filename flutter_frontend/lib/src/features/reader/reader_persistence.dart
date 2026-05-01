import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderPersistence {
  static const String _kBookmarks = 'reader.bookmarks';
  static const String _kHighlights = 'reader.highlights';

  static String _colorToHex(Color c) {
    return c.value.toRadixString(16).padLeft(8, '0');
  }

  static Color _hexToColor(String s) {
    final int v = int.parse(s, radix: 16);
    return Color(v);
  }

  // PUBLIC_INTERFACE
  static Future<(Set<String> bookmarks, Map<String, Color> highlights)> load()
      async {
    /// Loads bookmarks and highlights.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String> b = prefs.getStringList(_kBookmarks) ?? <String>[];
    final Set<String> bookmarks = b.toSet();

    final String? hStr = prefs.getString(_kHighlights);
    final Map<String, dynamic> hJson =
        hStr == null ? <String, dynamic>{} : jsonDecode(hStr) as Map<String, dynamic>;

    final Map<String, Color> highlights = <String, Color>{};
    for (final MapEntry<String, dynamic> e in hJson.entries) {
      final String key = e.key;
      final String val = (e.value as String?) ?? '';
      if (val.isEmpty) continue;
      highlights[key] = _hexToColor(val);
    }

    return (bookmarks, highlights);
  }

  // PUBLIC_INTERFACE
  static Future<void> saveBookmarks(Set<String> bookmarks) async {
    /// Persists bookmarks.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kBookmarks, bookmarks.toList(growable: false));
  }

  // PUBLIC_INTERFACE
  static Future<void> saveHighlights(Map<String, Color> highlights) async {
    /// Persists highlights.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final Map<String, String> enc = <String, String>{
      for (final MapEntry<String, Color> e in highlights.entries)
        e.key: _colorToHex(e.value),
    };
    await prefs.setString(_kHighlights, jsonEncode(enc));
  }
}
