import 'package:flutter/material.dart';
import 'package:vibe_coding_companion/src/book/book_models.dart';

@immutable
class ReaderState {
  final int chapterIndex;
  final int sectionIndex;

  final Set<String> bookmarkedBlockIds;
  final Map<String, Color> highlightsByBlockId;

  /// quiz answers: blockId -> selectedIndex
  final Map<String, int> quizAnswers;

  /// blocks completed (e.g., daily challenge prompt marked done)
  final Set<String> completedBlockIds;

  const ReaderState({
    required this.chapterIndex,
    required this.sectionIndex,
    required this.bookmarkedBlockIds,
    required this.highlightsByBlockId,
    required this.quizAnswers,
    required this.completedBlockIds,
  });

  ReaderState copyWith({
    int? chapterIndex,
    int? sectionIndex,
    Set<String>? bookmarkedBlockIds,
    Map<String, Color>? highlightsByBlockId,
    Map<String, int>? quizAnswers,
    Set<String>? completedBlockIds,
  }) {
    return ReaderState(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      bookmarkedBlockIds: bookmarkedBlockIds ?? this.bookmarkedBlockIds,
      highlightsByBlockId: highlightsByBlockId ?? this.highlightsByBlockId,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      completedBlockIds: completedBlockIds ?? this.completedBlockIds,
    );
  }

  static ReaderState initial() {
    return const ReaderState(
      chapterIndex: 0,
      sectionIndex: 0,
      bookmarkedBlockIds: <String>{},
      highlightsByBlockId: <String, Color>{},
      quizAnswers: <String, int>{},
      completedBlockIds: <String>{},
    );
  }
}

extension ReaderStateX on ReaderState {
  bool isBookmarked(String blockId) => bookmarkedBlockIds.contains(blockId);

  Color? highlightFor(String blockId) => highlightsByBlockId[blockId];

  int? quizAnswerFor(String blockId) => quizAnswers[blockId];
}
