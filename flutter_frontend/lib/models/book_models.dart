/// Data models for the interactive book.
///
/// These are intentionally simple and serializable to support local persistence
/// and stable identifiers for notes and reading state.

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.chapters,
  });

  final String id;
  final String title;
  final List<Chapter> chapters;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.sections,
  });

  final String id;
  final String title;
  final List<Section> sections;
}

class Section {
  const Section({
    required this.id,
    required this.title,
    required this.markdown,
  });

  final String id;
  final String title;
  final String markdown;
}
