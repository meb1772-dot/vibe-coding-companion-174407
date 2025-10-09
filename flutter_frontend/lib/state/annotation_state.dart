import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/models/annotation.dart';
import 'package:flutter_frontend/services/annotation_service.dart';

/// AnnotationState provides a simple in-memory cache of annotations
/// keyed by chapterId, delegating persistence to AnnotationService.
class AnnotationState extends ChangeNotifier {
  AnnotationState({AnnotationService? service})
      : _service = service ?? AnnotationService.instance;

  final AnnotationService _service;

  // Cache: chapterId -> list of annotations
  final Map<String, List<Annotation>> _byChapter = <String, List<Annotation>>{};

  bool _isLoading = false;
  Object? _lastError;

  /// PUBLIC_INTERFACE
  /// Whether an operation is currently loading data.
  bool get isLoading => _isLoading;

  /// PUBLIC_INTERFACE
  /// Last operation error, if any.
  Object? get lastError => _lastError;

  /// PUBLIC_INTERFACE
  /// Returns cached annotations for a chapter (empty list if none loaded).
  List<Annotation> getForChapter(String chapterId) =>
      _byChapter[chapterId] ?? const <Annotation>[];

  /// PUBLIC_INTERFACE
  /// Load annotations by chapter from the service into the cache.
  Future<void> loadByChapter(String chapterId) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final list = await _service.getByChapter(chapterId);
      _byChapter[chapterId] = List<Annotation>.unmodifiable(list);
    } catch (e) {
      _lastError = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// PUBLIC_INTERFACE
  /// Add a new annotation via service and update cache.
  Future<Annotation> add(Annotation a) async {
    final saved = await _service.add(a);
    final chapterId = saved.chapterId;
    final list = List<Annotation>.from(_byChapter[chapterId] ?? const <Annotation>[]);
    list.add(saved);
    list.sort((x, y) {
      final cmpStart = x.startOffset.compareTo(y.startOffset);
      if (cmpStart != 0) return cmpStart;
      return x.createdAt.compareTo(y.createdAt);
    });
    _byChapter[chapterId] = List<Annotation>.unmodifiable(list);
    notifyListeners();
    return saved;
  }

  /// PUBLIC_INTERFACE
  /// Update an annotation via service and update cache entry.
  Future<Annotation> update(Annotation a) async {
    final updated = await _service.update(a);
    final chapterId = updated.chapterId;
    final list = List<Annotation>.from(_byChapter[chapterId] ?? const <Annotation>[]);
    final idx = list.indexWhere((x) => x.id == updated.id);
    if (idx >= 0) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    list.sort((x, y) {
      final cmpStart = x.startOffset.compareTo(y.startOffset);
      if (cmpStart != 0) return cmpStart;
      return x.createdAt.compareTo(y.createdAt);
    });
    _byChapter[chapterId] = List<Annotation>.unmodifiable(list);
    notifyListeners();
    return updated;
  }

  /// PUBLIC_INTERFACE
  /// Delete an annotation by id, updating the cached chapter list.
  Future<bool> delete(int id, {required String chapterId}) async {
    final ok = await _service.delete(id);
    if (!ok) return false;
    final list = List<Annotation>.from(_byChapter[chapterId] ?? const <Annotation>[]);
    list.removeWhere((x) => x.id == id);
    _byChapter[chapterId] = List<Annotation>.unmodifiable(list);
    notifyListeners();
    return true;
  }

  /// PUBLIC_INTERFACE
  /// Clear all annotations for a chapter both in persistence and cache.
  Future<int> clearForChapter(String chapterId) async {
    final count = await _service.clearForChapter(chapterId);
    _byChapter.remove(chapterId);
    notifyListeners();
    return count;
  }
}
