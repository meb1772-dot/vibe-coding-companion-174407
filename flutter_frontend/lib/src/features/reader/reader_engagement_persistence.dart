import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for engagement hooks that are not tied to core reader state:
/// - Key takeaways (saved insights)
/// - XP + level progression
/// - Focus sprints history + best streak
class ReaderEngagementPersistence {
  ReaderEngagementPersistence._();

  static const String _kTakeaways = 'reader.takeaways.v1';
  static const String _kXp = 'reader.xp.v1';
  static const String _kSprints = 'reader.sprints.v1';

  // ----------------------------
  // Takeaways
  // ----------------------------

  // PUBLIC_INTERFACE
  static Future<List<Takeaway>> loadTakeaways() async {
    /// Loads saved takeaways from local storage.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_kTakeaways) ?? <String>[];
    return raw
        .map((String s) => Takeaway.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList(growable: false);
  }

  // PUBLIC_INTERFACE
  static Future<void> saveTakeaways(List<Takeaway> takeaways) async {
    /// Saves the full list of takeaways to local storage.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw =
        takeaways.map((Takeaway t) => jsonEncode(t.toJson())).toList(growable: false);
    await prefs.setStringList(_kTakeaways, raw);
  }

  // ----------------------------
  // XP
  // ----------------------------

  // PUBLIC_INTERFACE
  static Future<ReaderXp> loadXp() async {
    /// Loads XP state.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kXp);
    if (raw == null) return const ReaderXp(xp: 0);
    return ReaderXp.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // PUBLIC_INTERFACE
  static Future<void> saveXp(ReaderXp xp) async {
    /// Saves XP state.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kXp, jsonEncode(xp.toJson()));
  }

  // ----------------------------
  // Focus Sprints
  // ----------------------------

  // PUBLIC_INTERFACE
  static Future<SprintHistory> loadSprintHistory() async {
    /// Loads sprint history (last N sprints) and best streak.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kSprints);
    if (raw == null) return const SprintHistory(bestStreak: 0, events: <SprintEvent>[]);
    return SprintHistory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // PUBLIC_INTERFACE
  static Future<void> saveSprintHistory(SprintHistory history) async {
    /// Saves sprint history.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSprints, jsonEncode(history.toJson()));
  }
}

class Takeaway {
  final String id;
  final String createdDayKeyUtc; // YYYY-MM-DD
  final String chapterId;
  final String sectionId;
  final String blockId;
  final String title;
  final String note;

  const Takeaway({
    required this.id,
    required this.createdDayKeyUtc,
    required this.chapterId,
    required this.sectionId,
    required this.blockId,
    required this.title,
    required this.note,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdDayKeyUtc': createdDayKeyUtc,
        'chapterId': chapterId,
        'sectionId': sectionId,
        'blockId': blockId,
        'title': title,
        'note': note,
      };

  static Takeaway fromJson(Map<String, dynamic> j) => Takeaway(
        id: (j['id'] as String?) ?? '',
        createdDayKeyUtc: (j['createdDayKeyUtc'] as String?) ?? '',
        chapterId: (j['chapterId'] as String?) ?? '',
        sectionId: (j['sectionId'] as String?) ?? '',
        blockId: (j['blockId'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
      );
}

class ReaderXp {
  final int xp;

  const ReaderXp({required this.xp});

  int get level {
    // Simple “fast start” curve:
    // L1: 0-49, L2: 50-119, L3: 120-209, ...
    // Requirement for next level increases slowly.
    int remaining = xp;
    int lvl = 1;
    int need = 50;
    while (remaining >= need) {
      remaining -= need;
      lvl += 1;
      need += 20;
    }
    return lvl;
  }

  int xpIntoLevel() {
    int remaining = xp;
    int need = 50;
    while (remaining >= need) {
      remaining -= need;
      need += 20;
    }
    return remaining;
  }

  int xpNeededForNextLevel() {
    int remaining = xp;
    int need = 50;
    while (remaining >= need) {
      remaining -= need;
      need += 20;
    }
    return need;
  }

  ReaderXp add(int delta) => ReaderXp(xp: (xp + delta).clamp(0, 1 << 30));

  Map<String, dynamic> toJson() => <String, dynamic>{'xp': xp};

  static ReaderXp fromJson(Map<String, dynamic> j) =>
      ReaderXp(xp: (j['xp'] as num?)?.toInt() ?? 0);
}

class SprintEvent {
  final int createdAtMsUtc;
  final int minutes;
  final int xpAwarded;
  final bool completed;

  const SprintEvent({
    required this.createdAtMsUtc,
    required this.minutes,
    required this.xpAwarded,
    required this.completed,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'createdAtMsUtc': createdAtMsUtc,
        'minutes': minutes,
        'xpAwarded': xpAwarded,
        'completed': completed,
      };

  static SprintEvent fromJson(Map<String, dynamic> j) => SprintEvent(
        createdAtMsUtc: (j['createdAtMsUtc'] as num?)?.toInt() ?? 0,
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
        xpAwarded: (j['xpAwarded'] as num?)?.toInt() ?? 0,
        completed: (j['completed'] as bool?) ?? false,
      );
}

class SprintHistory {
  final int bestStreak;
  final List<SprintEvent> events;

  const SprintHistory({required this.bestStreak, required this.events});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bestStreak': bestStreak,
        'events': events.map((SprintEvent e) => e.toJson()).toList(growable: false),
      };

  static SprintHistory fromJson(Map<String, dynamic> j) => SprintHistory(
        bestStreak: (j['bestStreak'] as num?)?.toInt() ?? 0,
        events: ((j['events'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => SprintEvent.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}
