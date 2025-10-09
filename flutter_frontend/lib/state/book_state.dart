import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/chapter.dart';
import 'package:flutter_frontend/services/content_service.dart';
import 'package:flutter_frontend/services/annotation_service.dart';

/// BookState manages chapter list, current navigation state, and reader prefs
/// like font size and notes sidebar visibility. It loads content via
/// ContentService and persists preferences via AnnotationService.
class BookState extends ChangeNotifier {
  BookState({
    ContentService? contentService,
    AnnotationService? annotationService,
  })  : _contentService = contentService ?? ContentService.instance,
        _annotationService = annotationService ?? AnnotationService.instance;

  final ContentService _contentService;
  final AnnotationService _annotationService;

  // Loaded chapters and quick lookup
  List<Chapter> _chapters = const <Chapter>[];
  Map<String, Chapter> _byId = <String, Chapter>{};

  // Navigation state
  String? _currentChapterId;
  String? _currentSectionId;

  // Reader preferences
  double _fontSize = 16.0;
  bool _showNotesSidebar = false;

  bool _isLoading = false;
  Object? _lastError;

  // PUBLIC_INTERFACE
  /// Chapters currently loaded.
  List<Chapter> get chapters => _chapters;

  /// PUBLIC_INTERFACE
  /// Current chapter id.
  String? get currentChapterId => _currentChapterId;

  /// PUBLIC_INTERFACE
  /// Current section id.
  String? get currentSectionId => _currentSectionId;

  /// PUBLIC_INTERFACE
  /// Whether initial content is loading.
  bool get isLoading => _isLoading;

  /// PUBLIC_INTERFACE
  /// Last loading or action error, if any.
  Object? get lastError => _lastError;

  /// PUBLIC_INTERFACE
  /// Reader font size (persisted via AnnotationService).
  double get fontSize => _fontSize;

  /// PUBLIC_INTERFACE
  /// Whether the notes sidebar is shown by default (persisted).
  bool get showNotesSidebar => _showNotesSidebar;

  /// PUBLIC_INTERFACE
  /// Initialize state: load chapters and preferences. Safe to call multiple times.
  Future<void> initialize() async {
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Load preferences first so UI can reflect them quickly.
      _fontSize = await _annotationService.getFontSize();
      _showNotesSidebar = await _annotationService.getShowNotesSidebar();

      final list = await _contentService.getChapters();
      _chapters = list;
      _byId = {for (final c in list) c.id: c};

      // Default selection to first chapter/section if not set
      if (_currentChapterId == null && list.isNotEmpty) {
        _currentChapterId = list.first.id;
      }
      if (_currentSectionId == null) {
        final ch = _currentChapterId != null ? _byId[_currentChapterId!] : null;
        _currentSectionId = ch?.sections.isNotEmpty == true ? ch!.sections.first.id : null;
      }
    } catch (e) {
      _lastError = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// PUBLIC_INTERFACE
  /// Change current chapter; optionally set a specific section.
  void setCurrentChapter(String chapterId, {String? sectionId}) {
    if (_currentChapterId == chapterId && (sectionId == null || sectionId == _currentSectionId)) {
      return;
    }
    _currentChapterId = chapterId;
    if (sectionId != null) {
      _currentSectionId = sectionId;
    } else {
      final ch = _byId[chapterId];
      _currentSectionId = ch?.sections.isNotEmpty == true ? ch!.sections.first.id : null;
    }
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  /// Change current section within the same chapter.
  void setCurrentSection(String sectionId) {
    if (_currentSectionId == sectionId) return;
    _currentSectionId = sectionId;
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  /// Go to next chapter if available. Returns true if moved.
  bool nextChapter() {
    if (_chapters.isEmpty || _currentChapterId == null) return false;
    final idx = _chapters.indexWhere((c) => c.id == _currentChapterId);
    if (idx < 0 || idx + 1 >= _chapters.length) return false;
    final next = _chapters[idx + 1];
    setCurrentChapter(next.id);
    return true;
  }

  /// PUBLIC_INTERFACE
  /// Go to previous chapter if available. Returns true if moved.
  bool previousChapter() {
    if (_chapters.isEmpty || _currentChapterId == null) return false;
    final idx = _chapters.indexWhere((c) => c.id == _currentChapterId);
    if (idx <= 0) return false;
    final prev = _chapters[idx - 1];
    setCurrentChapter(prev.id);
    return true;
  }

  /// PUBLIC_INTERFACE
  /// Update reader font size and persist preference.
  Future<void> setFontSize(double size) async {
    // Update state immediately for responsive UI
    final clamped = size.clamp(10.0, 36.0);
    if (clamped == _fontSize) return;
    _fontSize = clamped;
    notifyListeners();
    // Persist asynchronously
    try {
      await _annotationService.setFontSize(_fontSize);
    } catch (_) {
      // Ignore persistence errors but keep UI state.
    }
  }

  /// PUBLIC_INTERFACE
  /// Toggle notes sidebar visibility preference.
  Future<void> setShowNotesSidebar(bool show) async {
    if (_showNotesSidebar == show) return;
    _showNotesSidebar = show;
    notifyListeners();
    try {
      await _annotationService.setShowNotesSidebar(show);
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  /// PUBLIC_INTERFACE
  /// Returns the current Chapter object, if selected.
  Chapter? get currentChapter => _currentChapterId != null ? _byId[_currentChapterId!] : null;

  /// PUBLIC_INTERFACE
  /// Returns the current Section object, if selected.
  Section? get currentSection {
    final ch = currentChapter;
    if (ch == null || _currentSectionId == null) return null;
    return ch.findSectionById(_currentSectionId!);
  }
}
