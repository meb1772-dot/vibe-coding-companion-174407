import 'package:flutter/material.dart';

enum BookBlockType {
  paragraph,
  heading,
  callout,
  checklist,
  prompt,
  code,
  quiz,
}

class BookBlock {
  final String id;
  final BookBlockType type;
  final String? title;
  final String? text;
  final String? code;
  final String? language;
  final List<String>? items;

  /// For quiz blocks.
  final List<QuizOption>? options;

  /// Index of the correct option in [options].
  final int? correctIndex;

  /// Explanation shown after answering.
  final String? explanation;

  const BookBlock({
    required this.id,
    required this.type,
    this.title,
    this.text,
    this.code,
    this.language,
    this.items,
    this.options,
    this.correctIndex,
    this.explanation,
  });
}

class QuizOption {
  final String id;
  final String text;
  const QuizOption({required this.id, required this.text});
}

class BookSection {
  final String id;
  final String title;
  final List<BookBlock> blocks;

  const BookSection({
    required this.id,
    required this.title,
    required this.blocks,
  });
}

class BookChapter {
  final String id;
  final String title;
  final String subtitle;
  final int minutes;
  final List<BookSection> sections;

  const BookChapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.sections,
  });
}

@immutable
class Bookmark {
  final String blockId;
  final int createdAtMs;

  const Bookmark({required this.blockId, required this.createdAtMs});
}

@immutable
class Highlight {
  final String blockId;
  final Color color;
  final int createdAtMs;

  const Highlight({
    required this.blockId,
    required this.color,
    required this.createdAtMs,
  });
}
