import 'package:flutter/foundation.dart';

enum AchievementId {
  firstSession,
  firstBookmark,
 firstHighlight,
  firstQuizWin,
  threeDayStreak,
  sevenDayStreak,
  finishChapter,
}

@immutable
class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final int unlockedAtMs;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockedAtMs,
  });
}

@immutable
class DailyChallenge {
  final String id;
  final String title;
  final String description;

  /// A stable key for a particular day (e.g., "2026-05-01").
  final String dayKey;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.dayKey,
  });
}

@immutable
class ReadingStats {
  final int streakDays;
  final int lastReadDayEpoch; // days since epoch
  final int totalSessions;
  final int totalMinutesRead;

  const ReadingStats({
    required this.streakDays,
    required this.lastReadDayEpoch,
    required this.totalSessions,
    required this.totalMinutesRead,
  });
}

@immutable
class ReadingGoal {
  /// Target reading minutes per day.
  final int minutesPerDay;

  /// Minutes completed today.
  final int minutesToday;

  /// Day key for minutesToday.
  final String dayKey;

  const ReadingGoal({
    required this.minutesPerDay,
    required this.minutesToday,
    required this.dayKey,
  });
}
