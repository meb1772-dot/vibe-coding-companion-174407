import 'dart:convert';

class Note {
  const Note({
    required this.id,
    required this.sectionId,
    required this.createdAtEpochMs,
    required this.body,
    this.quote,
  });

  final String id;
  final String sectionId;
  final int createdAtEpochMs;
  final String body;
  final String? quote;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'sectionId': sectionId,
        'createdAtEpochMs': createdAtEpochMs,
        'body': body,
        'quote': quote,
      };

  static Note fromJson(Map<String, Object?> json) {
    return Note(
      id: (json['id'] as String?) ?? '',
      sectionId: (json['sectionId'] as String?) ?? '',
      createdAtEpochMs: (json['createdAtEpochMs'] as int?) ?? 0,
      body: (json['body'] as String?) ?? '',
      quote: json['quote'] as String?,
    );
  }

  static String encodeList(List<Note> notes) {
    final List<Map<String, Object?>> jsonList =
        notes.map((n) => n.toJson()).toList(growable: false);
    return jsonEncode(jsonList);
  }

  static List<Note> decodeList(String raw) {
    final Object decoded = jsonDecode(raw);
    if (decoded is! List) return <Note>[];
    return decoded
        .whereType<Map>()
        .map((m) => Note.fromJson(m.cast<String, Object?>()))
        .toList(growable: false);
  }
}

class ReadingProgress {
  const ReadingProgress({
    required this.chapterIndex,
    required this.sectionIndex,
  });

  final int chapterIndex;
  final int sectionIndex;

  Map<String, Object?> toJson() => <String, Object?>{
        'chapterIndex': chapterIndex,
        'sectionIndex': sectionIndex,
      };

  static ReadingProgress fromJson(Map<String, Object?> json) {
    return ReadingProgress(
      chapterIndex: (json['chapterIndex'] as int?) ?? 0,
      sectionIndex: (json['sectionIndex'] as int?) ?? 0,
    );
  }

  static String encode(ReadingProgress progress) => jsonEncode(progress.toJson());

  static ReadingProgress decode(String raw) {
    final Object decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const ReadingProgress(chapterIndex: 0, sectionIndex: 0);
    }
    return ReadingProgress.fromJson(decoded.cast<String, Object?>());
  }
}
