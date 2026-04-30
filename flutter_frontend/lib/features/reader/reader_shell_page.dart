import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';

import '../../data/sample_book.dart';
import '../../models/book_models.dart';
import '../../models/note_models.dart';
import '../../models/search_models.dart';
import '../../models/settings_models.dart';
import '../../services/local_persistence_service.dart';
import '../settings/settings_sheet.dart';

class ReaderShellPage extends StatefulWidget {
  const ReaderShellPage({super.key});

  @override
  State<ReaderShellPage> createState() => _ReaderShellPageState();
}

class _ReaderShellPageState extends State<ReaderShellPage> {
  final SampleBookRepository _bookRepository = const SampleBookRepository();
  final LocalPersistenceService _persistence = LocalPersistenceService();
  final Uuid _uuid = const Uuid();

  Book? _book;
  List<Note> _notes = const <Note>[];

  int _chapterIndex = 0;
  int _sectionIndex = 0;

  bool _loading = true;
  String? _errorMessage;

  int _bottomTabIndex = 0; // 0 = Reader, 1 = Notes, 2 = Bookmarks, 3 = All notes

  AppSettings _settings = const AppSettings(
    fontScale: 1.0,
    lineHeight: 1.6,
    showNotesPaneOnWide: true,
    bookmarkedSectionIds: <String>[],
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // CRITICAL: no BuildContext usage across awaits.
    // Only update primitive state after awaits.
    try {
      final Book loadedBook = await _bookRepository.loadBook();
      final List<Note> loadedNotes = await _persistence.loadNotes();
      final ReadingProgress? progress = await _persistence.loadProgress();
      final AppSettings? loadedSettings = await _persistence.loadSettings();

      final int chapterIndex = progress?.chapterIndex ?? 0;
      final int sectionIndex = progress?.sectionIndex ?? 0;

      setState(() {
        _book = loadedBook;
        _notes = loadedNotes;
        _settings = loadedSettings ?? _settings;

        _chapterIndex = chapterIndex.clamp(0, loadedBook.chapters.length - 1);
        _sectionIndex = sectionIndex.clamp(
          0,
          loadedBook.chapters[_chapterIndex].sections.length - 1,
        );
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load book content: $e';
      });
    }
  }

  Chapter? get _currentChapter {
    final Book? b = _book;
    if (b == null) return null;
    if (_chapterIndex < 0 || _chapterIndex >= b.chapters.length) return null;
    return b.chapters[_chapterIndex];
  }

  Section? get _currentSection {
    final Chapter? ch = _currentChapter;
    if (ch == null) return null;
    if (_sectionIndex < 0 || _sectionIndex >= ch.sections.length) return null;
    return ch.sections[_sectionIndex];
  }

  String _currentSectionIdOrEmpty() => _currentSection?.id ?? '';

  bool _isBookmarked(String sectionId) => _settings.bookmarkedSectionIds.contains(sectionId);

  List<Note> _notesForSection(String sectionId) {
    return _notes
        .where((n) => n.sectionId == sectionId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAtEpochMs.compareTo(a.createdAtEpochMs));
  }

  Future<void> _persistProgress() async {
    final ReadingProgress progress = ReadingProgress(
      chapterIndex: _chapterIndex,
      sectionIndex: _sectionIndex,
    );
    await _persistence.saveProgress(progress);
  }

  Future<void> _persistNotes() async {
    await _persistence.saveNotes(_notes);
  }

  Future<void> _persistSettings() async {
    await _persistence.saveSettings(_settings);
  }

  void _selectChapterSection({required int chapterIndex, required int sectionIndex}) {
    final Book? b = _book;
    if (b == null) return;

    final int safeChapter = chapterIndex.clamp(0, b.chapters.length - 1);
    final int safeSection = sectionIndex.clamp(
      0,
      b.chapters[safeChapter].sections.length - 1,
    );

    setState(() {
      _chapterIndex = safeChapter;
      _sectionIndex = safeSection;
      _bottomTabIndex = 0;
    });

    // Persist asynchronously; no context usage here.
    _persistProgress();
  }

  void _goPrev() {
    final Book? b = _book;
    if (b == null) return;

    int c = _chapterIndex;
    int s = _sectionIndex - 1;
    if (s < 0) {
      c = c - 1;
      if (c < 0) return;
      s = b.chapters[c].sections.length - 1;
    }
    _selectChapterSection(chapterIndex: c, sectionIndex: s);
  }

  void _goNext() {
    final Book? b = _book;
    if (b == null) return;

    int c = _chapterIndex;
    int s = _sectionIndex + 1;
    if (s >= b.chapters[c].sections.length) {
      c = c + 1;
      if (c >= b.chapters.length) return;
      s = 0;
    }
    _selectChapterSection(chapterIndex: c, sectionIndex: s);
  }

  void _addNote({
    required String sectionId,
    String? quote,
    required String body,
  }) {
    final Note note = Note(
      id: _uuid.v4(),
      sectionId: sectionId,
      createdAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      body: body.trim(),
      quote: (quote == null || quote.trim().isEmpty) ? null : quote.trim(),
    );

    setState(() {
      _notes = <Note>[note, ..._notes];
      _bottomTabIndex = 1; // switch to Notes tab
    });

    _persistNotes();
  }

  void _editNote({
    required String noteId,
    required String body,
    String? quote,
  }) {
    setState(() {
      _notes = _notes
          .map(
            (n) => n.id == noteId
                ? Note(
                    id: n.id,
                    sectionId: n.sectionId,
                    createdAtEpochMs: n.createdAtEpochMs,
                    body: body.trim(),
                    quote: (quote == null || quote.trim().isEmpty) ? null : quote.trim(),
                  )
                : n,
          )
          .toList(growable: false);
    });
    _persistNotes();
  }

  void _deleteNote(String noteId) {
    setState(() {
      _notes = _notes.where((n) => n.id != noteId).toList(growable: false);
    });
    _persistNotes();
  }

  void _toggleBookmarkForCurrentSection() {
    final String sectionId = _currentSectionIdOrEmpty();
    if (sectionId.isEmpty) return;

    final List<String> next = List<String>.from(_settings.bookmarkedSectionIds);
    if (next.contains(sectionId)) {
      next.remove(sectionId);
    } else {
      next.insert(0, sectionId);
    }

    setState(() {
      _settings = _settings.copyWith(bookmarkedSectionIds: next);
    });
    _persistSettings();
  }

  bool _isWideLayout(BoxConstraints constraints) => constraints.maxWidth >= 1000;

  List<SearchResult> _search(String query) {
    final Book? b = _book;
    if (b == null) return const <SearchResult>[];
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return const <SearchResult>[];

    final List<SearchResult> results = <SearchResult>[];
    for (final (cIdx, ch) in b.chapters.indexed) {
      for (final (sIdx, sec) in ch.sections.indexed) {
        final String haystack =
            '${ch.title}\n${sec.title}\n${sec.markdown}'.toLowerCase();
        if (!haystack.contains(q)) continue;

        // Create a small preview snippet around the first occurrence.
        final int at = haystack.indexOf(q);
        final String raw = '${ch.title} — ${sec.title}';
        final int ctxStart = (at - 30).clamp(0, haystack.length);
        final int ctxEnd = (at + q.length + 60).clamp(0, haystack.length);
        final String ctx = sec.markdown
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final String preview = ctx.isEmpty
            ? raw
            : ctx.substring(
                0,
                ctx.length.clamp(0, 140),
              );

        results.add(
          SearchResult(
            chapterIndex: cIdx,
            sectionIndex: sIdx,
            chapter: ch,
            section: sec,
            matchContext: preview,
          ),
        );
      }
    }

    return results.take(50).toList(growable: false);
  }

  String _exportNotesPlainText() {
    final Book? b = _book;
    if (b == null) return '';
    final StringBuffer sb = StringBuffer();
    sb.writeln(b.title);
    sb.writeln('Exported notes');
    sb.writeln('');

    final List<Note> sorted = _notes.toList(growable: false)
      ..sort((a, b) => b.createdAtEpochMs.compareTo(a.createdAtEpochMs));

    for (final note in sorted) {
      final _SectionLocator? loc = _locateSection(b, note.sectionId);
      final String sectionLabel = loc == null
          ? '(Unknown section)'
          : '${loc.chapter.title} / ${loc.section.title}';
      final DateTime dt = DateTime.fromMillisecondsSinceEpoch(note.createdAtEpochMs);

      sb.writeln(sectionLabel);
      sb.writeln(
        '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}',
      );
      if (note.quote != null && note.quote!.trim().isNotEmpty) {
        sb.writeln('Quote: “${note.quote}”');
      }
      sb.writeln(note.body);
      sb.writeln('\n---\n');
    }

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vibe Coding Companion')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_errorMessage!, style: theme.textTheme.bodyLarge),
            ),
          ),
        ),
      );
    }

    final Book book = _book!;
    final Chapter chapter = _currentChapter!;
    final Section section = _currentSection!;
    final List<Note> sectionNotes = _notesForSection(section.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = _isWideLayout(constraints);
        final bool showNotesPane = wide && _settings.showNotesPaneOnWide;

        final Widget chapterNav = _ChapterNavigation(
          book: book,
          selectedChapterIndex: _chapterIndex,
          selectedSectionIndex: _sectionIndex,
          onSelect: _selectChapterSection,
        );

        final Widget readerPane = _ReaderPane(
          bookTitle: book.title,
          chapterTitle: chapter.title,
          sectionTitle: section.title,
          markdown: section.markdown,
          fontScale: _settings.fontScale,
          lineHeight: _settings.lineHeight,
          bookmarked: _isBookmarked(section.id),
          onToggleBookmark: _toggleBookmarkForCurrentSection,
          onPrev: _goPrev,
          onNext: _goNext,
          onAddNotePressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return _AddOrEditNoteSheet(
                  title: 'Add note',
                  sectionTitle: section.title,
                  initialBody: '',
                  initialQuote: '',
                  showQuoteField: true,
                  onSubmit: (body, quote) => _addNote(
                    sectionId: section.id,
                    body: body,
                    quote: quote,
                  ),
                );
              },
            );
          },
          onSearchPressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return _SearchSheet(
                  onSearch: _search,
                  onJumpTo: (cIdx, sIdx) => _selectChapterSection(
                    chapterIndex: cIdx,
                    sectionIndex: sIdx,
                  ),
                );
              },
            );
          },
          onSettingsPressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return SettingsSheet(
                  initialSettings: _settings,
                  onChanged: (next) {
                    setState(() {
                      _settings = next;
                    });
                    _persistSettings();
                  },
                );
              },
            );
          },
        );

        final Widget notesPane = _NotesPane(
          title: 'Notes for this section',
          emptyMessage:
              'No notes for “${section.title}” yet.\n\nAdd a note to capture insights, questions, or TODOs.',
          notes: sectionNotes,
          locateSectionTitle: (sectionId) => section.title,
          onAdd: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return _AddOrEditNoteSheet(
                  title: 'Add note',
                  sectionTitle: section.title,
                  initialBody: '',
                  initialQuote: '',
                  showQuoteField: true,
                  onSubmit: (body, quote) => _addNote(
                    sectionId: section.id,
                    body: body,
                    quote: quote,
                  ),
                );
              },
            );
          },
          onEdit: (note) async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return _AddOrEditNoteSheet(
                  title: 'Edit note',
                  sectionTitle: section.title,
                  initialBody: note.body,
                  initialQuote: note.quote ?? '',
                  showQuoteField: true,
                  onSubmit: (body, quote) => _editNote(
                    noteId: note.id,
                    body: body,
                    quote: quote,
                  ),
                );
              },
            );
          },
          onDelete: _deleteNote,
        );

        final Widget bookmarksPane = _BookmarksPane(
          book: book,
          bookmarkedSectionIds: _settings.bookmarkedSectionIds,
          onJumpTo: _selectChapterSection,
        );

        final Widget allNotesPane = _AllNotesPane(
          book: book,
          notes: _notes,
          onJumpToSectionId: (sectionId) {
            final _SectionLocator? loc = _locateSection(book, sectionId);
            if (loc == null) return;
            _selectChapterSection(chapterIndex: loc.chapterIndex, sectionIndex: loc.sectionIndex);
          },
          onExport: () async {
            final String exported = _exportNotesPlainText();
            await showDialog<void>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Export notes'),
                  content: SizedBox(
                    width: 560,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        exported.isEmpty ? 'No notes yet.' : exported,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );

        final List<Widget> narrowTabs = <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withAlpha(18),
                  theme.scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: readerPane,
          ),
          notesPane,
          bookmarksPane,
          allNotesPane,
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(book.title),
            actions: [
              IconButton(
                tooltip: 'Chapters',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_book),
              ),
            ],
          ),
          drawer: wide ? null : Drawer(child: chapterNav),
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 320, child: chapterNav),
                      VerticalDivider(width: 1, color: theme.dividerColor),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withAlpha(18),
                                theme.scaffoldBackgroundColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: readerPane,
                        ),
                      ),
                      if (showNotesPane) ...[
                        VerticalDivider(width: 1, color: theme.dividerColor),
                        SizedBox(width: 360, child: notesPane),
                      ],
                    ],
                  )
                : IndexedStack(
                    index: _bottomTabIndex,
                    children: narrowTabs,
                  ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _bottomTabIndex,
                  onDestinationSelected: (idx) {
                    setState(() {
                      _bottomTabIndex = idx;
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.chrome_reader_mode_outlined),
                      selectedIcon: Icon(Icons.chrome_reader_mode),
                      label: 'Read',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.sticky_note_2_outlined),
                      selectedIcon: Icon(Icons.sticky_note_2),
                      label: 'Notes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bookmark_border),
                      selectedIcon: Icon(Icons.bookmark),
                      label: 'Bookmarks',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: 'All notes',
                    ),
                  ],
                ),
          floatingActionButton: wide
              ? null
              : FloatingActionButton.extended(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (context) {
                        return _AddOrEditNoteSheet(
                          title: 'Add note',
                          sectionTitle: section.title,
                          initialBody: '',
                          initialQuote: '',
                          showQuoteField: true,
                          onSubmit: (body, quote) => _addNote(
                            sectionId: section.id,
                            body: body,
                            quote: quote,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_comment),
                  label: const Text('Add note'),
                ),
        );
      },
    );
  }
}

class _ChapterNavigation extends StatefulWidget {
  const _ChapterNavigation({
    required this.book,
    required this.selectedChapterIndex,
    required this.selectedSectionIndex,
    required this.onSelect,
  });

  final Book book;
  final int selectedChapterIndex;
  final int selectedSectionIndex;
  final void Function({required int chapterIndex, required int sectionIndex}) onSelect;

  @override
  State<_ChapterNavigation> createState() => _ChapterNavigationState();
}

class _ChapterNavigationState extends State<_ChapterNavigation> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = _filter.trim().toLowerCase();

    final List<(int, Chapter)> chapters = widget.book.chapters.indexed
        .map((e) => (e.$1, e.$2))
        .where((pair) => q.isEmpty || pair.$2.title.toLowerCase().contains(q))
        .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() => _filter = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Filter chapters…',
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
            itemBuilder: (context, idx) {
              final int chapterIndex = chapters[idx].$1;
              final Chapter chapter = chapters[idx].$2;
              final bool selected = chapterIndex == widget.selectedChapterIndex;

              return Card(
                child: ExpansionTile(
                  initiallyExpanded: selected,
                  leading: Icon(
                    Icons.bookmark,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withAlpha(120),
                  ),
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  children: [
                    for (final (sIdx, sec) in chapter.sections.indexed)
                      ListTile(
                        title: Text(sec.title),
                        leading: Icon(
                          Icons.article_outlined,
                          size: 18,
                          color: selected && sIdx == widget.selectedSectionIndex
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface.withAlpha(140),
                        ),
                        trailing: selected && sIdx == widget.selectedSectionIndex
                            ? Icon(Icons.chevron_right, color: theme.colorScheme.secondary)
                            : null,
                        onTap: () => widget.onSelect(
                          chapterIndex: chapterIndex,
                          sectionIndex: sIdx,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReaderPane extends StatelessWidget {
  const _ReaderPane({
    required this.bookTitle,
    required this.chapterTitle,
    required this.sectionTitle,
    required this.markdown,
    required this.fontScale,
    required this.lineHeight,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onPrev,
    required this.onNext,
    required this.onAddNotePressed,
    required this.onSearchPressed,
    required this.onSettingsPressed,
  });

  final String bookTitle;
  final String chapterTitle;
  final String sectionTitle;
  final String markdown;

  final double fontScale;
  final double lineHeight;

  final bool bookmarked;
  final VoidCallback onToggleBookmark;

  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onAddNotePressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _ReaderHeader(
                  chapterTitle: chapterTitle,
                  sectionTitle: sectionTitle,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Search',
                onPressed: onSearchPressed,
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark section',
                onPressed: onToggleBookmark,
                icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              ),
              IconButton(
                tooltip: 'Add note',
                onPressed: onAddNotePressed,
                icon: const Icon(Icons.add_comment),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: onSettingsPressed,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Markdown(
                data: markdown,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * fontScale,
                    height: lineHeight,
                  ),
                  h1: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24 * fontScale,
                    fontWeight: FontWeight.w900,
                  ),
                  h2: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.w900,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: theme.colorScheme.primary, width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Prev'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.chapterTitle,
    required this.sectionTitle,
  });

  final String chapterTitle;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chapterTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withAlpha(160),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sectionTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _NotesPane extends StatelessWidget {
  const _NotesPane({
    required this.title,
    required this.emptyMessage,
    required this.notes,
    required this.locateSectionTitle,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String emptyMessage;
  final List<Note> notes;

  /// Used by All-notes experiences; here kept for consistency.
  final String Function(String sectionId) locateSectionTitle;

  final VoidCallback onAdd;
  final ValueChanged<Note> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        emptyMessage,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
                  itemBuilder: (context, i) {
                    final Note n = notes[i];
                    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(n.createdAtEpochMs);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sticky_note_2, color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${dt.year.toString().padLeft(4, '0')}-'
                                    '${dt.month.toString().padLeft(2, '0')}-'
                                    '${dt.day.toString().padLeft(2, '0')} '
                                    '${dt.hour.toString().padLeft(2, '0')}:'
                                    '${dt.minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface.withAlpha(160),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit note',
                                  onPressed: () => onEdit(n),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete note',
                                  onPressed: () => onDelete(n.id),
                                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                            if (n.quote != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha(18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '“${n.quote}”',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              n.body,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AddOrEditNoteSheet extends StatefulWidget {
  const _AddOrEditNoteSheet({
    required this.title,
    required this.sectionTitle,
    required this.initialBody,
    required this.initialQuote,
    required this.showQuoteField,
    required this.onSubmit,
  });

  final String title;
  final String sectionTitle;
  final String initialBody;
  final String initialQuote;
  final bool showQuoteField;

  final void Function(String body, String quote) onSubmit;

  @override
  State<_AddOrEditNoteSheet> createState() => _AddOrEditNoteSheetState();
}

class _AddOrEditNoteSheetState extends State<_AddOrEditNoteSheet> {
  late final TextEditingController _bodyController = TextEditingController(text: widget.initialBody);
  late final TextEditingController _quoteController =
      TextEditingController(text: widget.initialQuote);

  bool _submitting = false;

  @override
  void dispose() {
    _bodyController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  void _submit() {
    final String body = _bodyController.text.trim();
    final String quote = _quoteController.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _submitting = true;
    });

    // Synchronous UI operations only; no await.
    widget.onSubmit(body, quote);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 6,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            widget.sectionTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.showQuoteField) ...[
            TextField(
              controller: _quoteController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Optional quote (paste a snippet)…',
                prefixIcon: Icon(Icons.format_quote),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _bodyController,
            minLines: 4,
            maxLines: 10,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Write your note…',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.onSearch,
    required this.onJumpTo,
  });

  final List<SearchResult> Function(String query) onSearch;
  final void Function(int chapterIndex, int sectionIndex) onJumpTo;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = const <SearchResult>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    setState(() {
      _results = widget.onSearch(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 6,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _runSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search chapters and content…',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 420,
            child: _results.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Type to search the book.\n\nTip: Try “guardrails”, “notes”, or “loop”.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
                    itemBuilder: (context, i) {
                      final SearchResult r = _results[i];
                      return ListTile(
                        leading: Icon(Icons.find_in_page, color: theme.colorScheme.primary),
                        title: Text('${r.chapter.title} • ${r.section.title}'),
                        subtitle: Text(
                          r.matchContext,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          widget.onJumpTo(r.chapterIndex, r.sectionIndex);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookmarksPane extends StatelessWidget {
  const _BookmarksPane({
    required this.book,
    required this.bookmarkedSectionIds,
    required this.onJumpTo,
  });

  final Book book;
  final List<String> bookmarkedSectionIds;

  final void Function({required int chapterIndex, required int sectionIndex}) onJumpTo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<_SectionLocator> items = <_SectionLocator>[
      for (final id in bookmarkedSectionIds)
        if (_locateSection(book, id) != null) _locateSection(book, id)!,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Bookmarks',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No bookmarks yet.\n\nTap the bookmark icon in the reader to save a section.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
                  itemBuilder: (context, i) {
                    final _SectionLocator loc = items[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.bookmark, color: theme.colorScheme.secondary),
                        title: Text(loc.section.title),
                        subtitle: Text(loc.chapter.title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onJumpTo(
                          chapterIndex: loc.chapterIndex,
                          sectionIndex: loc.sectionIndex,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AllNotesPane extends StatefulWidget {
  const _AllNotesPane({
    required this.book,
    required this.notes,
    required this.onJumpToSectionId,
    required this.onExport,
  });

  final Book book;
  final List<Note> notes;

  final ValueChanged<String> onJumpToSectionId;
  final VoidCallback onExport;

  @override
  State<_AllNotesPane> createState() => _AllNotesPaneState();
}

class _AllNotesPaneState extends State<_AllNotesPane> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = _filter.trim().toLowerCase();

    final List<Note> sorted = widget.notes.toList(growable: false)
      ..sort((a, b) => b.createdAtEpochMs.compareTo(a.createdAtEpochMs));

    final List<Note> filtered = q.isEmpty
        ? sorted
        : sorted
            .where(
              (n) =>
                  n.body.toLowerCase().contains(q) ||
                  (n.quote?.toLowerCase().contains(q) ?? false),
            )
            .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'All notes',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Export',
                onPressed: widget.onExport,
                icon: const Icon(Icons.ios_share),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            onChanged: (v) => setState(() => _filter = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.filter_list),
              hintText: 'Filter notes…',
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.notes.isEmpty
                            ? 'No notes yet.\n\nAdd notes while reading to build your personal index.'
                            : 'No results for “$_filter”.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
                  itemBuilder: (context, i) {
                    final Note n = filtered[i];
                    final _SectionLocator? loc = _locateSection(widget.book, n.sectionId);
                    final String sectionLabel = loc == null
                        ? '(Unknown section)'
                        : '${loc.chapter.title} • ${loc.section.title}';

                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.sticky_note_2, color: theme.colorScheme.secondary),
                        title: Text(sectionLabel),
                        subtitle: Text(
                          n.quote != null && n.quote!.trim().isNotEmpty
                              ? '“${n.quote}”\n${n.body}'
                              : n.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          widget.onJumpToSectionId(n.sectionId);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SectionLocator {
  const _SectionLocator({
    required this.chapterIndex,
    required this.sectionIndex,
    required this.chapter,
    required this.section,
  });

  final int chapterIndex;
  final int sectionIndex;
  final Chapter chapter;
  final Section section;
}

_SectionLocator? _locateSection(Book book, String sectionId) {
  for (final (cIdx, ch) in book.chapters.indexed) {
    for (final (sIdx, sec) in ch.sections.indexed) {
      if (sec.id == sectionId) {
        return _SectionLocator(
          chapterIndex: cIdx,
          sectionIndex: sIdx,
          chapter: ch,
          section: sec,
        );
      }
    }
  }
  return null;
}
