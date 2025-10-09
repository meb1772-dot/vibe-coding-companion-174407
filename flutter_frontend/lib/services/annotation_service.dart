import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_frontend/models/annotation.dart';

/// Service that manages user annotations and reader UI preferences.
/// - On mobile/desktop: persists annotations in SQLite (`sqflite`).
/// - On web: uses an in-memory list for annotations (sqflite is not supported),
///           while still persisting UI preferences using SharedPreferences.
/// - Offers lazy initialization for the database and caches a singleton instance.
class AnnotationService {
  AnnotationService._internal();

  static final AnnotationService _instance = AnnotationService._internal();

  // PUBLIC_INTERFACE
  /// Singleton accessor
  static AnnotationService get instance => _instance;

  Database? _db;

  // Web fallback: in-memory annotations store
  final List<Annotation> _memory = <Annotation>[];

  // Preferences keys
  static const _prefFontSizeKey = 'reader.font_size';
  static const _prefShowNotesSidebarKey = 'reader.show_notes_sidebar';

  // Database metadata
  static const _dbName = 'annotations.db';
  static const _dbVersion = 1;
  static const _table = 'annotations';

  // Column names (snake_case for SQL)
  static const _colId = 'id';
  static const _colChapterId = 'chapter_id';
  static const _colSectionId = 'section_id';
  static const _colStart = 'start_offset';
  static const _colEnd = 'end_offset';
  static const _colNote = 'note_text';
  static const _colColor = 'color_argb';
  static const _colCreatedAt = 'created_at';
  static const _colUpdatedAt = 'updated_at';

  /// PUBLIC_INTERFACE
  /// Initializes the underlying store (no-op for web aside from ensuring prefs are usable).
  /// Safe to call multiple times; subsequent calls are fast.
  Future<void> init() async {
    if (kIsWeb) {
      // No SQLite on web, nothing to init for DB. Preferences are lazy via SharedPreferences.getInstance().
      return;
    }
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            $_colId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_colChapterId TEXT NOT NULL,
            $_colSectionId TEXT NOT NULL,
            $_colStart INTEGER NOT NULL,
            $_colEnd INTEGER NOT NULL,
            $_colNote TEXT NOT NULL,
            $_colColor INTEGER NOT NULL,
            $_colCreatedAt INTEGER NOT NULL,
            $_colUpdatedAt INTEGER NOT NULL
          )
        ''');
        // Future migrations can be handled via onUpgrade when version increases.
      },
    );
  }

  /// Ensures DB is available; on web returns null.
  Future<Database?> _ensureDb() async {
    if (kIsWeb) return null;
    if (_db == null) {
      await init();
    }
    return _db;
  }

  /// PUBLIC_INTERFACE
  /// Returns all annotations for the given chapter, sorted by createdAt ascending.
  Future<List<Annotation>> getByChapter(String chapterId) async {
    if (kIsWeb) {
      return _memory
          .where((a) => a.chapterId == chapterId)
          .toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final db = await _ensureDb();
    if (db == null) return const <Annotation>[];

    final rows = await db.query(
      _table,
      where: '$_colChapterId = ?',
      whereArgs: [chapterId],
      orderBy: '$_colCreatedAt ASC',
    );
    return rows.map((m) => Annotation.fromMap(m)).toList(growable: false);
  }

  /// PUBLIC_INTERFACE
  /// Returns all annotations for the given chapter and optional section,
  /// sorted by start offset then createdAt for stability.
  Future<List<Annotation>> getByChapterSection(String chapterId, String? sectionId) async {
    if (kIsWeb) {
      final list = _memory.where((a) {
        if (a.chapterId != chapterId) return false;
        if (sectionId == null) return true;
        return a.sectionId == sectionId;
      }).toList(growable: false)
        ..sort((a, b) {
          final cmpStart = a.startOffset.compareTo(b.startOffset);
          if (cmpStart != 0) return cmpStart;
          return a.createdAt.compareTo(b.createdAt);
        });
      return list;
    }

    final db = await _ensureDb();
    if (db == null) return const <Annotation>[];

    final String whereClause;
    final List<Object?> whereArgs;
    if (sectionId == null) {
      whereClause = '$_colChapterId = ?';
      whereArgs = [chapterId];
    } else {
      whereClause = '$_colChapterId = ? AND $_colSectionId = ?';
      whereArgs = [chapterId, sectionId];
    }

    final rows = await db.query(
      _table,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '$_colStart ASC, $_colCreatedAt ASC',
    );
    return rows.map((m) => Annotation.fromMap(m)).toList(growable: false);
  }

  /// PUBLIC_INTERFACE
  /// Inserts a new annotation. Returns the inserted Annotation with its id populated.
  Future<Annotation> add(Annotation a) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final toInsert = a.copyWith(
      createdAt: a.createdAt == 0 ? now : a.createdAt,
      updatedAt: now,
    );

    if (kIsWeb) {
      // Simulate auto-increment id in memory
      final newId = (_memory.isEmpty ? 1 : (_memory.map((e) => e.id ?? 0).fold<int>(0, (p, c) => c > p ? c : p) + 1));
      final saved = toInsert.copyWith(id: newId);
      _memory.add(saved);
      return saved;
    }

    final db = await _ensureDb();
    if (db == null) return toInsert; // Should not happen; return without id.

    final id = await db.insert(_table, toInsert.toMap()..remove(_colId));
    return toInsert.copyWith(id: id);
  }

  /// PUBLIC_INTERFACE
  /// Updates an existing annotation by its id. Returns the updated object.
  Future<Annotation> update(Annotation a) async {
    if (a.id == null) {
      // For robustness, if no id present treat as insert.
      return add(a);
    }

    final updated = a.copyWith(updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch);

    if (kIsWeb) {
      final idx = _memory.indexWhere((x) => x.id == a.id);
      if (idx >= 0) {
        _memory[idx] = updated;
      }
      return updated;
    }

    final db = await _ensureDb();
    if (db == null) return updated;

    await db.update(
      _table,
      updated.toMap()..remove(_colId),
      where: '$_colId = ?',
      whereArgs: [a.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return updated;
    }

  /// PUBLIC_INTERFACE
  /// Deletes an annotation by id. Returns true if a row was removed.
  Future<bool> delete(int id) async {
    if (kIsWeb) {
      final before = _memory.length;
      _memory.removeWhere((a) => a.id == id);
      return _memory.length != before;
    }

    final db = await _ensureDb();
    if (db == null) return false;

    final count = await db.delete(
      _table,
      where: '$_colId = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// PUBLIC_INTERFACE
  /// Removes all annotations for a specific chapter. Returns number of rows deleted.
  Future<int> clearForChapter(String chapterId) async {
    if (kIsWeb) {
      final toRemove = _memory.where((a) => a.chapterId == chapterId).toList(growable: false);
      _memory.removeWhere((a) => a.chapterId == chapterId);
      return toRemove.length;
    }

    final db = await _ensureDb();
    if (db == null) return 0;

    final count = await db.delete(
      _table,
      where: '$_colChapterId = ?',
      whereArgs: [chapterId],
    );
    return count;
  }

  // =======================
  // Preferences
  // =======================

  /// PUBLIC_INTERFACE
  /// Reader font size preference (default 16.0).
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefFontSizeKey) ?? 16.0;
  }

  /// PUBLIC_INTERFACE
  /// Sets reader font size.
  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    // Clamp to a reasonable range to avoid UI issues.
    final clamped = size.clamp(10.0, 36.0);
    await prefs.setDouble(_prefFontSizeKey, clamped);
  }

  /// PUBLIC_INTERFACE
  /// Whether the notes sidebar is visible by default (default false).
  Future<bool> getShowNotesSidebar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefShowNotesSidebarKey) ?? false;
  }

  /// PUBLIC_INTERFACE
  /// Sets the visibility of the notes sidebar.
  Future<void> setShowNotesSidebar(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShowNotesSidebarKey, value);
  }

  // =======================
  // Testing helpers
  // =======================

  /// Clears all annotations (testing/dev helper). Web: clears memory; Native: deletes from table.
  @visibleForTesting
  Future<void> debugClearAll() async {
    if (kIsWeb) {
      _memory.clear();
      return;
    }
    final db = await _ensureDb();
    if (db == null) return;
    await db.delete(_table);
  }

  /// Close database (testing/dev helper). No-op on web.
  @visibleForTesting
  Future<void> debugClose() async {
    if (kIsWeb) return;
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
  }
}


