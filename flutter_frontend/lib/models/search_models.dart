import 'book_models.dart';

/// A single search hit within the book.
class SearchResult {
  const SearchResult({
    required this.chapterIndex,
    required this.sectionIndex,
    required this.chapter,
    required this.section,
    required this.matchContext,
  });

  final int chapterIndex;
  final int sectionIndex;
  final Chapter chapter;
  final Section section;

  /// Short snippet to display in search UI.
  final String matchContext;
}
