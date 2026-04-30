import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_models.dart';

/// Handles local persistence using SharedPreferences.
///
/// Storage keys are versioned and intentionally simple for MVP.
class LocalPersistenceService {
  static const String _kNotesKey = 'v1.notes';
  static const String _kProgressKey = 'v1.reading_progress';

  Future<List<Note>> loadNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kNotesKey);
    if (raw == null || raw.trim().isEmpty) return <Note>[];
    return Note.decodeList(raw);
  }

  Future<void> saveNotes(List<Note> notes) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotesKey, Note.encodeList(notes));
  }

  Future<ReadingProgress?> loadProgress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kProgressKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return ReadingProgress.decode(raw);
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProgressKey, ReadingProgress.encode(progress));
  }
}
