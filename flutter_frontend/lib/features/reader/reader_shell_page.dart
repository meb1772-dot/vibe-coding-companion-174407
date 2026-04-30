import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';

import '../../data/sample_book.dart';
import '../../models/book_models.dart';
import '../../models/note_models.dart';
import '../../services/local_persistence_service.dart';

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

  int _bottomTabIndex = 0; // 0 = Reader, 1 = Notes

  double _fontScale = 1.0;

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

      final int chapterIndex = progress?.chapterIndex ?? 0;
      final int sectionIndex = progress?.sectionIndex ?? 0;

      setState(() {
        _book = loadedBook;
        _notes = loadedNotes;
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

  void _addNote({required String sectionId, String? quote, required String body}) {
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

  void _deleteNote(String noteId) {
    setState(() {
      _notes = _notes.where((n) => n.id != noteId).toList(growable: false);
    });
    _persistNotes();
  }

  bool _isWideLayout(BoxConstraints constraints) => constraints.maxWidth >= 1000;

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
          fontScale: _fontScale,
          onFontScaleChanged: (v) {
            setState(() {
              _fontScale = v;
            });
          },
          onPrev: _goPrev,
          onNext: _goNext,
          onAddNotePressed: () async {
            // UI operation done synchronously from build event handlers.
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return _AddNoteSheet(
                  sectionTitle: section.title,
                  onSubmit: (body) => _addNote(sectionId: section.id, body: body),
                );
              },
            );
          },
        );

        final Widget notesPane = _NotesPane(
          sectionTitle: section.title,
          notes: sectionNotes,
          onAdd: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return _AddNoteSheet(
                  sectionTitle: section.title,
                  onSubmit: (body) => _addNote(sectionId: section.id, body: body),
                );
              },
            );
          },
          onDelete: _deleteNote,
        );

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
                      VerticalDivider(width: 1, color: theme.dividerColor),
                      SizedBox(width: 360, child: notesPane),
                    ],
                  )
                : IndexedStack(
                    index: _bottomTabIndex,
                    children: [
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
                    ],
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
                        return _AddNoteSheet(
                          sectionTitle: section.title,
                          onSubmit: (body) => _addNote(sectionId: section.id, body: body),
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
    required this.onFontScaleChanged,
    required this.onPrev,
    required this.onNext,
    required this.onAddNotePressed,
  });

  final String bookTitle;
  final String chapterTitle;
  final String sectionTitle;
  final String markdown;

  final double fontScale;
  final ValueChanged<double> onFontScaleChanged;

  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onAddNotePressed;

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
                tooltip: 'Add note',
                onPressed: onAddNotePressed,
                icon: const Icon(Icons.add_comment),
              ),
              PopupMenuButton<double>(
                tooltip: 'Text size',
                onSelected: onFontScaleChanged,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 0.9, child: Text('Small')),
                  PopupMenuItem(value: 1.0, child: Text('Default')),
                  PopupMenuItem(value: 1.1, child: Text('Large')),
                  PopupMenuItem(value: 1.2, child: Text('Extra large')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.text_fields, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${(fontScale * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
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
                    height: 1.6,
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
    required this.sectionTitle,
    required this.notes,
    required this.onAdd,
    required this.onDelete,
  });

  final String sectionTitle;
  final List<Note> notes;
  final VoidCallback onAdd;
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
                  'Notes',
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
                        'No notes for “$sectionTitle” yet.\n\nAdd a note to capture insights, questions, or TODOs.',
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
                    final DateTime dt =
                        DateTime.fromMillisecondsSinceEpoch(n.createdAtEpochMs);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sticky_note_2,
                                    color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface.withAlpha(160),
                                    ),
                                  ),
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

class _AddNoteSheet extends StatefulWidget {
  const _AddNoteSheet({
    required this.sectionTitle,
    required this.onSubmit,
  });

  final String sectionTitle;
  final ValueChanged<String> onSubmit;

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String body = _controller.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _submitting = true;
    });

    // Synchronous UI operations only; no await.
    widget.onSubmit(body);
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
            'Add note',
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
          TextField(
            controller: _controller,
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
