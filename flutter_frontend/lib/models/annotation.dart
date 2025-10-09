import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Annotation model used by AnnotationService and SQLite persistence.
///
/// Represents a user-created note/highlight anchored to a specific
/// chapter section with character offsets. Supports color tagging and timestamps.

// PUBLIC_INTERFACE
@immutable
class Annotation {
  /// Database primary key; can be null for not-yet-persisted entries.
  final int? id;

  /// Foreign key reference to the Chapter.id (string-based id from content).
  final String chapterId;

  /// Foreign key reference to the Section.id (string-based id within a chapter).
  final String sectionId;

  /// Inclusive start character offset in the section body.
  final int startOffset;

  /// Exclusive end character offset in the section body.
  final int endOffset;

  /// User-entered note text (optional, can be empty for highlight-only).
  final String noteText;

  /// Highlight or tag color; stored as ARGB int in SQLite via [colorToInt].
  final Color color;

  /// Milliseconds since epoch (UTC) for creation time.
  final int createdAt;

  /// Milliseconds since epoch (UTC) for last update time.
  final int updatedAt;

  const Annotation({
    this.id,
    required this.chapterId,
    required this.sectionId,
    required this.startOffset,
    required this.endOffset,
    required this.noteText,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(startOffset >= 0),
       assert(endOffset >= startOffset);

  /// PUBLIC_INTERFACE
  /// Create a copy with updated fields.
  Annotation copyWith({
    int? id,
    String? chapterId,
    String? sectionId,
    int? startOffset,
    int? endOffset,
    String? noteText,
    Color? color,
    int? createdAt,
    int? updatedAt,
  }) {
    return Annotation(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      sectionId: sectionId ?? this.sectionId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      noteText: noteText ?? this.noteText,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// PUBLIC_INTERFACE
  /// Convert to a map suitable for SQLite insertion/update.
  /// Column names are snake_case for clarity and conventional SQL style.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'chapter_id': chapterId,
        'section_id': sectionId,
        'start_offset': startOffset,
        'end_offset': endOffset,
        'note_text': noteText,
        'color_argb': colorToInt(color),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// PUBLIC_INTERFACE
  /// Build an Annotation from a SQLite row map.
  factory Annotation.fromMap(Map<String, dynamic> map) {
    return Annotation(
      id: _readNullableInt(map['id']),
      chapterId: (map['chapter_id'] ?? '').toString(),
      sectionId: (map['section_id'] ?? '').toString(),
      startOffset: _readInt(map['start_offset']),
      endOffset: _readInt(map['end_offset']),
      noteText: (map['note_text'] ?? '').toString(),
      color: intToColor(_readInt(map['color_argb'])),
      createdAt: _readInt(map['created_at']),
      updatedAt: _readInt(map['updated_at']),
    );
  }

  /// PUBLIC_INTERFACE
  /// Convert a [Color] to a persisted ARGB int.
  static int colorToInt(Color color) => color.toARGB32();

  /// PUBLIC_INTERFACE
  /// Convert an ARGB int back to a [Color].
  static Color intToColor(int argb) => Color(argb);

  /// Convenience utility to create an "empty" highlight with defaults.
  /// Useful for quick user interactions before editing note text.
  // PUBLIC_INTERFACE
  static Annotation newHighlight({
    required String chapterId,
    required String sectionId,
    required int startOffset,
    required int endOffset,
    Color color = const Color(0x66FFF59E), // semi-transparent amber
    String noteText = '',
    int? nowUtcMs,
  }) {
    final now = nowUtcMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    return Annotation(
      id: null,
      chapterId: chapterId,
      sectionId: sectionId,
      startOffset: startOffset,
      endOffset: endOffset,
      noteText: noteText,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Safe integer read from dynamic value (e.g., SQLite may return int or num).
int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  return _readInt(value);
}
