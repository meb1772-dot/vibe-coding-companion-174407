import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_coding_companion/src/engagement/engagement_models.dart';

class EngagementService {
  static const String _kStats = 'engagement.stats';
  static const String _kAchievements = 'engagement.achievements';
  static const String _kGoal = 'engagement.goal';

  static const int _defaultGoalMinutes = 12;

  // PUBLIC_INTERFACE
  static String todayKeyUtc() {
    /// Returns an ISO-like day key in UTC: YYYY-MM-DD.
    final DateTime now = DateTime.now().toUtc();
    final String mm = now.month.toString().padLeft(2, '0');
    final String dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  static int _dayEpochUtc(DateTime dt) {
    final DateTime d = DateTime.utc(dt.year, dt.month, dt.day);
    return d.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  static ReadingStats _defaultStats() {
    return const ReadingStats(
      streakDays: 0,
      lastReadDayEpoch: 0,
      totalSessions: 0,
      totalMinutesRead: 0,
    );
  }

  static Map<String, dynamic> _statsToJson(ReadingStats s) => <String, dynamic>{
        'streakDays': s.streakDays,
        'lastReadDayEpoch': s.lastReadDayEpoch,
        'totalSessions': s.totalSessions,
        'totalMinutesRead': s.totalMinutesRead,
      };

  static ReadingStats _statsFromJson(Map<String, dynamic> j) => ReadingStats(
        streakDays: (j['streakDays'] as num?)?.toInt() ?? 0,
        lastReadDayEpoch: (j['lastReadDayEpoch'] as num?)?.toInt() ?? 0,
        totalSessions: (j['totalSessions'] as num?)?.toInt() ?? 0,
        totalMinutesRead: (j['totalMinutesRead'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> _achievementToJson(Achievement a) =>
      <String, dynamic>{
        'id': a.id.name,
        'title': a.title,
        'description': a.description,
        'unlockedAtMs': a.unlockedAtMs,
      };

  static Achievement _achievementFromJson(Map<String, dynamic> j) => Achievement(
        id: AchievementId.values.firstWhere(
          (AchievementId e) => e.name == (j['id'] as String? ?? ''),
          orElse: () => AchievementId.firstSession,
        ),
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        unlockedAtMs: (j['unlockedAtMs'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> _goalToJson(ReadingGoal g) => <String, dynamic>{
        'minutesPerDay': g.minutesPerDay,
        'minutesToday': g.minutesToday,
        'dayKey': g.dayKey,
      };

  static ReadingGoal _goalFromJson(Map<String, dynamic> j) => ReadingGoal(
        minutesPerDay: (j['minutesPerDay'] as num?)?.toInt() ??
            _defaultGoalMinutes,
        minutesToday: (j['minutesToday'] as num?)?.toInt() ?? 0,
        dayKey: (j['dayKey'] as String?) ?? todayKeyUtc(),
      );

  // PUBLIC_INTERFACE
  static Future<(ReadingStats stats, ReadingGoal goal, List<Achievement> achievements)>
      load() async {
    /// Loads engagement state from local storage.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? statsStr = prefs.getString(_kStats);
    final ReadingStats stats = statsStr == null
        ? _defaultStats()
        : _statsFromJson(jsonDecode(statsStr) as Map<String, dynamic>);

    final String? goalStr = prefs.getString(_kGoal);
    final ReadingGoal goal = goalStr == null
        ? ReadingGoal(
            minutesPerDay: _defaultGoalMinutes,
            minutesToday: 0,
            dayKey: todayKeyUtc(),
          )
        : _goalFromJson(jsonDecode(goalStr) as Map<String, dynamic>);

    final List<String> achStrs = prefs.getStringList(_kAchievements) ?? <String>[];
    final List<Achievement> achievements = achStrs
        .map((String s) => _achievementFromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList(growable: false);

    return (stats, _normalizeGoalForToday(goal), achievements);
  }

  static ReadingGoal _normalizeGoalForToday(ReadingGoal goal) {
    final String today = todayKeyUtc();
    if (goal.dayKey == today) return goal;
    return ReadingGoal(
      minutesPerDay: goal.minutesPerDay,
      minutesToday: 0,
      dayKey: today,
    );
  }

  // PUBLIC_INTERFACE
  static Future<(ReadingStats stats, ReadingGoal goal)> recordReadingSession({
    required int minutesRead,
  }) async {
    /// Records a reading session, updating streak, totals, and daily goal progress.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final (ReadingStats current, ReadingGoal g0, List<Achievement> _) =
        await load();

    final int today = _dayEpochUtc(DateTime.now().toUtc());
    final int yesterday = today - 1;

    int newStreak = current.streakDays;
    if (current.lastReadDayEpoch == today) {
      // same day: streak unchanged
    } else if (current.lastReadDayEpoch == yesterday) {
      newStreak = current.streakDays + 1;
    } else {
      newStreak = 1;
    }

    final ReadingStats updated = ReadingStats(
      streakDays: newStreak,
      lastReadDayEpoch: today,
      totalSessions: current.totalSessions + 1,
      totalMinutesRead: current.totalMinutesRead + minutesRead,
    );

    final ReadingGoal normalized = _normalizeGoalForToday(g0);
    final ReadingGoal updatedGoal = ReadingGoal(
      minutesPerDay: normalized.minutesPerDay,
      minutesToday: (normalized.minutesToday + minutesRead).clamp(0, 10000),
      dayKey: normalized.dayKey,
    );

    await prefs.setString(_kStats, jsonEncode(_statsToJson(updated)));
    await prefs.setString(_kGoal, jsonEncode(_goalToJson(updatedGoal)));

    return (updated, updatedGoal);
  }

  // PUBLIC_INTERFACE
  static Future<void> setDailyGoalMinutes(int minutesPerDay) async {
    /// Sets the daily reading goal in minutes.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final (ReadingStats _, ReadingGoal g0, List<Achievement> __) = await load();
    final ReadingGoal normalized = _normalizeGoalForToday(g0);

    final ReadingGoal updated = ReadingGoal(
      minutesPerDay: minutesPerDay.clamp(5, 120),
      minutesToday: normalized.minutesToday,
      dayKey: normalized.dayKey,
    );
    await prefs.setString(_kGoal, jsonEncode(_goalToJson(updated)));
  }

  // PUBLIC_INTERFACE
  static DailyChallenge todaysChallenge() {
    /// Returns a deterministic daily challenge based on the day key.
    final String day = todayKeyUtc();
    final int hash = day.codeUnits.fold<int>(0, (int a, int b) => a + b);

    final List<DailyChallenge> challenges = <DailyChallenge>[
      DailyChallenge(
        id: 'c1',
        dayKey: day,
        title: '2-minute friction audit',
        description:
            'Find the first annoying step between you and running your app. Improve it in one tiny way.',
      ),
      DailyChallenge(
        id: 'c2',
        dayKey: day,
        title: 'One tiny refactor',
        description:
            'Pick a confusing name in your code and rename it to something obvious. Ship it.',
      ),
      DailyChallenge(
        id: 'c3',
        dayKey: day,
        title: 'Write a breadcrumb',
        description:
            'Before you stop coding, leave yourself a note: “Next I will…” (one sentence).',
      ),
      DailyChallenge(
        id: 'c4',
        dayKey: day,
        title: 'Test the smallest thing',
        description:
            'Add the smallest possible test or manual check for what you’re working on.',
      ),
    ];

    return challenges[hash % challenges.length];
  }

  // PUBLIC_INTERFACE
  static Future<List<Achievement>> unlockIfNeeded(
    AchievementId id, {
    required String title,
    required String description,
  }) async {
    /// Unlocks an achievement if it is not already unlocked.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final (ReadingStats _, ReadingGoal __, List<Achievement> current) =
        await load();

    final bool already = current.any((Achievement a) => a.id == id);
    if (already) return current;

    final List<Achievement> updated = <Achievement>[
      ...current,
      Achievement(
        id: id,
        title: title,
        description: description,
        unlockedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    ];

    final List<String> encoded =
        updated.map((Achievement a) => jsonEncode(_achievementToJson(a))).toList();
    await prefs.setStringList(_kAchievements, encoded);
    return updated;
  }
}
