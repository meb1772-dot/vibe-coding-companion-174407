import 'package:flutter/foundation.dart';

/// Models representing the structured content for chapters and their sections.
/// These are used by ContentService to load asset-backed JSON into rich
/// in-memory objects and to serialize them back if needed.

// PUBLIC_INTERFACE
@immutable
class Chapter {
  /// Unique identifier for the chapter (stable across builds).
  final String id;

  /// Display title shown in the UI (drawer, header, etc).
  final String title;

  /// Ordered list of sections composing the chapter content.
  final List<Section> sections;

  const Chapter({
    required this.id,
    required this.title,
    required this.sections,
  });

  /// PUBLIC_INTERFACE
  /// Build a Chapter from a JSON-like map (e.g., loaded from an asset file).
  /// Expects:
  /// {
  ///   "id": "ch1",
  ///   "title": "Introduction",
  ///   "sections": [
  ///     {"id":"s1","heading":"Welcome","body":"..."},
  ///     ...
  ///   ]
  /// }
  factory Chapter.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final List<Section> parsedSections;
    if (rawSections is List) {
      parsedSections = rawSections
          .whereType<Map<String, dynamic>>()
          .map(Section.fromJson)
          .toList(growable: false);
    } else {
      parsedSections = const [];
    }

    return Chapter(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      sections: parsedSections,
    );
  }

  /// PUBLIC_INTERFACE
  /// Serialize Chapter to a JSON-like map suitable for persistence in assets.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'sections': sections.map((s) => s.toJson()).toList(growable: false),
      };

  /// Convenience to find a section by id, or null if not present.
  Section? findSectionById(String sectionId) {
    for (final s in sections) {
      if (s.id == sectionId) return s;
    }
    return null;
  }
}

// PUBLIC_INTERFACE
@immutable
class Section {
  /// Unique identifier within the chapter scope.
  final String id;

  /// Optional display heading.
  final String heading;

  /// Rich text content body; may include markdown/plain text rendered by the UI.
  final String body;

  const Section({
    required this.id,
    required this.heading,
    required this.body,
  });

  /// PUBLIC_INTERFACE
  /// Build Section from a JSON-like map.
  /// Expects: {"id":"s1","heading":"Welcome","body":"..."}
  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: (json['id'] ?? '').toString(),
      heading: (json['heading'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
    );
  }

  /// PUBLIC_INTERFACE
  /// Serialize Section to a JSON-like map suitable for asset persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'heading': heading,
        'body': body,
      };
}
