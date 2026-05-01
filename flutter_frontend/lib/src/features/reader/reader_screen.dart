import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vibe_coding_companion/src/book/book_content.dart';
import 'package:vibe_coding_companion/src/book/book_models.dart';
import 'package:vibe_coding_companion/src/engagement/engagement_models.dart';
import 'package:vibe_coding_companion/src/engagement/engagement_service.dart';
import 'package:vibe_coding_companion/src/features/engagement/engagement_widgets.dart';
import 'package:vibe_coding_companion/src/features/reader/block_widgets.dart';
import 'package:vibe_coding_companion/src/features/reader/reader_engagement_persistence.dart';
import 'package:vibe_coding_companion/src/features/reader/reader_persistence.dart';
import 'package:vibe_coding_companion/src/features/reader/reader_state.dart';
import 'package:vibe_coding_companion/src/features/reader/takeaway_widgets.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  ReaderState _state = ReaderState.initial();

  ReadingStats _stats = const ReadingStats(
    streakDays: 0,
    lastReadDayEpoch: 0,
    totalSessions: 0,
    totalMinutesRead: 0,
  );
  ReadingGoal _goal = ReadingGoal(
    minutesPerDay: 12,
    minutesToday: 0,
    dayKey: EngagementService.todayKeyUtc(),
  );
  List<Achievement> _achievements = const <Achievement>[];

  final DailyChallenge _challenge = EngagementService.todaysChallenge();
  bool _challengeCompleted = false;

  // “Addictive” loop 1: XP + Level
  ReaderXp _xp = const ReaderXp(xp: 0);

  // “Addictive” loop 2: Focus sprints
  SprintHistory _sprintHistory =
      const SprintHistory(bestStreak: 0, events: <SprintEvent>[]);
  Timer? _sprintTimer;
  int _sprintRemainingSec = 0;
  int _sprintStreak = 0; // consecutive completions in-session

  // “Addictive” loop 3: Takeaways
  List<Takeaway> _takeaways = const <Takeaway>[];

  bool _ready = false;

  Timer? _readingTimer;
  int _activeMinutesCounter = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _startMinuteTimer();
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _sprintTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final (Set<String> bookmarks, Map<String, Color> highlights) =
        await ReaderPersistence.load();
    final (ReadingStats stats, ReadingGoal goal, List<Achievement> achievements) =
        await EngagementService.load();

    final ReaderXp xp = await ReaderEngagementPersistence.loadXp();
    final List<Takeaway> takeaways =
        await ReaderEngagementPersistence.loadTakeaways();
    final SprintHistory history =
        await ReaderEngagementPersistence.loadSprintHistory();

    // No context usage after await: only update primitives/state.
    setState(() {
      _state = _state.copyWith(
        bookmarkedBlockIds: bookmarks,
        highlightsByBlockId: highlights,
      );
      _stats = stats;
      _goal = goal;
      _achievements = achievements;
      _xp = xp;
      _takeaways = takeaways;
      _sprintHistory = history;
      _ready = true;
    });
  }

  void _startMinuteTimer() {
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _activeMinutesCounter += 1;
      });
    });
  }

  BookChapter get _chapter => BookContent.chapters[_state.chapterIndex];
  BookSection get _section => _chapter.sections[_state.sectionIndex];

  Future<void> _saveBookmarks() async {
    await ReaderPersistence.saveBookmarks(_state.bookmarkedBlockIds);
  }

  Future<void> _saveHighlights() async {
    await ReaderPersistence.saveHighlights(_state.highlightsByBlockId);
  }

  Color? _nextHighlight(Color? current, ColorScheme scheme) {
    // cycle: null -> amber -> blue -> null
    final Color amber = scheme.secondary;
    final Color blue = scheme.primary;

    if (current == null) return amber;
    if (current.value == amber.value) return blue;
    return null;
  }

  Future<void> _toggleBookmark(String blockId) async {
    final Set<String> next = <String>{..._state.bookmarkedBlockIds};
    final bool wasBookmarked = next.contains(blockId);

    if (wasBookmarked) {
      next.remove(blockId);
    } else {
      next.add(blockId);
    }

    setState(() {
      _state = _state.copyWith(bookmarkedBlockIds: next);
    });

    await _saveBookmarks();

    if (!wasBookmarked) {
      final List<Achievement> updated = await EngagementService.unlockIfNeeded(
        AchievementId.firstBookmark,
        title: 'First Bookmark',
        description: 'You bookmarked your first insight.',
      );
      setState(() {
        _achievements = updated;
      });

      await _awardXp(3, reason: 'Bookmark');
    }
  }

  Future<void> _cycleHighlight(String blockId) async {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<String, Color> next = <String, Color>{..._state.highlightsByBlockId};

    final Color? current = next[blockId];
    final Color? updated = _nextHighlight(current, scheme);
    if (updated == null) {
      next.remove(blockId);
    } else {
      next[blockId] = updated;
    }

    setState(() {
      _state = _state.copyWith(highlightsByBlockId: next);
    });

    await _saveHighlights();

    if (updated != null) {
      final List<Achievement> updatedAch = await EngagementService.unlockIfNeeded(
        AchievementId.firstHighlight,
        title: 'First Highlight',
        description: 'You highlighted something worth remembering.',
      );
      setState(() {
        _achievements = updatedAch;
      });

      await _awardXp(2, reason: 'Highlight');
    }
  }

  Future<void> _answerQuiz(String blockId, int index, int? correct) async {
    final Map<String, int> next = <String, int>{..._state.quizAnswers};
    next[blockId] = index;

    setState(() {
      _state = _state.copyWith(quizAnswers: next);
    });

    if (correct != null && index == correct) {
      final List<Achievement> updated = await EngagementService.unlockIfNeeded(
        AchievementId.firstQuizWin,
        title: 'Quiz Win',
        description: 'You answered a quiz correctly.',
      );
      setState(() {
        _achievements = updated;
      });

      await _awardXp(8, reason: 'Quiz win');
    } else {
      await _awardXp(1, reason: 'Quiz attempt');
    }
  }

  Future<void> _completeDailyChallenge() async {
    setState(() {
      _challengeCompleted = true;
    });

    final List<Achievement> updated = await EngagementService.unlockIfNeeded(
      AchievementId.firstSession,
      title: 'First Session',
      description: 'You completed your first focused reading session.',
    );
    setState(() {
      _achievements = updated;
    });

    await _awardXp(10, reason: 'Daily challenge');
  }

  Future<void> _recordEngagementTick({required int minutes}) async {
    final (ReadingStats updatedStats, ReadingGoal updatedGoal) =
        await EngagementService.recordReadingSession(minutesRead: minutes);

    // Unlock streak achievements (simple thresholds).
    List<Achievement> updatedAchievements = _achievements;
    if (updatedStats.streakDays >= 3) {
      updatedAchievements = await EngagementService.unlockIfNeeded(
        AchievementId.threeDayStreak,
        title: '3-Day Streak',
        description: 'You showed up 3 days in a row.',
      );
    }
    if (updatedStats.streakDays >= 7) {
      updatedAchievements = await EngagementService.unlockIfNeeded(
        AchievementId.sevenDayStreak,
        title: '7-Day Streak',
        description: 'A full week of momentum.',
      );
    }

    setState(() {
      _stats = updatedStats;
      _goal = updatedGoal;
      _achievements = updatedAchievements;
    });

    await _awardXp((minutes * 2).clamp(1, 50), reason: 'Reading');
  }

  // PUBLIC_INTERFACE
  Future<void> _awardXp(int delta, {required String reason}) async {
    /// Awards XP and persists it. (Local-only “progress bar” hook)
    final ReaderXp updated = _xp.add(delta);
    setState(() {
      _xp = updated;
    });
    await ReaderEngagementPersistence.saveXp(updated);
  }

  void _nextSection() {
    final int s = _state.sectionIndex;
    if (s + 1 < _chapter.sections.length) {
      setState(() {
        _state = _state.copyWith(sectionIndex: s + 1);
      });
      return;
    }
    final int c = _state.chapterIndex;
    if (c + 1 < BookContent.chapters.length) {
      setState(() {
        _state = _state.copyWith(chapterIndex: c + 1, sectionIndex: 0);
      });
    }
  }

  void _prevSection() {
    final int s = _state.sectionIndex;
    if (s - 1 >= 0) {
      setState(() {
        _state = _state.copyWith(sectionIndex: s - 1);
      });
      return;
    }
    final int c = _state.chapterIndex;
    if (c - 1 >= 0) {
      final BookChapter prev = BookContent.chapters[c - 1];
      setState(() {
        _state = _state.copyWith(
          chapterIndex: c - 1,
          sectionIndex: prev.sections.length - 1,
        );
      });
    }
  }

  void _startSprint(int minutes) {
    _sprintTimer?.cancel();
    setState(() {
      _sprintRemainingSec = minutes * 60;
    });

    _sprintTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_sprintRemainingSec <= 1) {
        t.cancel();
        _finishSprint(minutes: minutes, completed: true);
        return;
      }
      setState(() {
        _sprintRemainingSec -= 1;
      });
    });
  }

  Future<void> _cancelSprint() async {
    if (_sprintRemainingSec <= 0) return;

    _sprintTimer?.cancel();
    final int minutes = (_sprintRemainingSec / 60).ceil().clamp(1, 60);
    setState(() {
      _sprintRemainingSec = 0;
      _sprintStreak = 0;
    });

    await _finishSprint(minutes: minutes, completed: false);
  }

  Future<void> _finishSprint({required int minutes, required bool completed}) async {
    // This is a local “mini-game”: short timer + reward.
    final int xpAwarded = completed ? (minutes * 6).clamp(6, 60) : 1;

    if (completed) {
      setState(() {
        _sprintRemainingSec = 0;
        _sprintStreak += 1;
      });
    }

    final int best = completed
        ? (_sprintHistory.bestStreak < _sprintStreak
            ? _sprintStreak
            : _sprintHistory.bestStreak)
        : _sprintHistory.bestStreak;

    final SprintEvent event = SprintEvent(
      createdAtMsUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
      minutes: minutes,
      xpAwarded: xpAwarded,
      completed: completed,
    );

    final List<SprintEvent> updatedEvents = <SprintEvent>[
      event,
      ..._sprintHistory.events,
    ].take(20).toList(growable: false);

    final SprintHistory updatedHistory =
        SprintHistory(bestStreak: best, events: updatedEvents);

    setState(() {
      _sprintHistory = updatedHistory;
    });

    await ReaderEngagementPersistence.saveSprintHistory(updatedHistory);
    await _awardXp(xpAwarded, reason: 'Sprint');

    if (completed) {
      // also feed the existing goal/streak system
      await _recordEngagementTick(minutes: minutes);
    }
  }

  void _openTakeawayComposer(BuildContext context, BookBlock block) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return TakeawayComposer(
          defaultTitle: (block.title ?? '').isNotEmpty ? block.title! : 'Key takeaway',
          prompt: 'What should future-you remember from this section?',
          onSubmit: ((String title, String note) payload) {
            _saveTakeawayFromBlock(block: block, title: payload.$1, note: payload.$2);
          },
        );
      },
    );
  }

  Future<void> _saveTakeawayFromBlock({
    required BookBlock block,
    required String title,
    required String note,
  }) async {
    final String t = title.trim().isEmpty ? 'Key takeaway' : title.trim();
    final String n = note.trim();
    if (n.isEmpty) return;

    final String id = 'tw_${DateTime.now().toUtc().millisecondsSinceEpoch}_${block.id}';
    final Takeaway takeaway = Takeaway(
      id: id,
      createdDayKeyUtc: EngagementService.todayKeyUtc(),
      chapterId: _chapter.id,
      sectionId: _section.id,
      blockId: block.id,
      title: t,
      note: n,
    );

    final List<Takeaway> updated = <Takeaway>[takeaway, ..._takeaways]
        .take(100)
        .toList(growable: false);

    setState(() {
      _takeaways = updated;
    });

    await ReaderEngagementPersistence.saveTakeaways(updated);
    await _awardXp(6, reason: 'Takeaway');
  }

  Future<void> _deleteTakeaway(String id) async {
    final List<Takeaway> updated =
        _takeaways.where((Takeaway t) => t.id != id).toList(growable: false);
    setState(() {
      _takeaways = updated;
    });
    await ReaderEngagementPersistence.saveTakeaways(updated);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Widget body = !_ready
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth >= 1050;

              return Row(
                children: <Widget>[
                  // Left: chapters
                  SizedBox(
                    width: wide ? 280 : 0,
                    child: wide
                        ? _ChaptersPane(
                            chapterIndex: _state.chapterIndex,
                            sectionIndex: _state.sectionIndex,
                            onSelectChapter: (int idx) {
                              setState(() {
                                _state = _state.copyWith(chapterIndex: idx, sectionIndex: 0);
                              });
                            },
                            onSelectSection: (int idx) {
                              setState(() {
                                _state = _state.copyWith(sectionIndex: idx);
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Center: reader
                  Expanded(
                    child: _ReaderPane(
                      chapter: _chapter,
                      section: _section,
                      state: _state,
                      achievements: _achievements,
                      challenge: _challenge,
                      challengeCompleted: _challengeCompleted,
                      stats: _stats,
                      goal: _goal,
                      xp: _xp,
                      sprintRemainingSec: _sprintRemainingSec,
                      sprintBestStreak: _sprintHistory.bestStreak,
                      sprintStreak: _sprintStreak,
                      takeawaysCount: _takeaways.length,
                      onCompleteChallenge: _completeDailyChallenge,
                      onToggleBookmark: (String blockId) => _toggleBookmark(blockId),
                      onCycleHighlight: (String blockId) => _cycleHighlight(blockId),
                      onAnswerQuiz: (String blockId, int selected, int? correct) =>
                          _answerQuiz(blockId, selected, correct),
                      onStartSprint: _startSprint,
                      onCancelSprint: _cancelSprint,
                      onOpenTakeaway: _openTakeawayComposer,
                    ),
                  ),

                  // Right: notes/engagement
                  SizedBox(
                    width: wide ? 340 : 0,
                    child: wide
                        ? _RightPane(
                            scheme: scheme,
                            stats: _stats,
                            goal: _goal,
                            achievements: _achievements,
                            activeMinutes: _activeMinutesCounter,
                            xp: _xp,
                            sprintHistory: _sprintHistory,
                            takeaways: _takeaways,
                            onLogMinutes: () {
                              _recordEngagementTick(minutes: 2);
                            },
                            onStartSprint5: () => _startSprint(5),
                            onSetGoal: () async {
                              await EngagementService.setDailyGoalMinutes(18);
                              final (ReadingStats stats, ReadingGoal goal, List<Achievement> a) =
                                  await EngagementService.load();
                              setState(() {
                                _stats = stats;
                                _goal = goal;
                                _achievements = a;
                              });
                            },
                            onDeleteTakeaway: _deleteTakeaway,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            },
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_chapter.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Previous section',
            onPressed: _prevSection,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next section',
            onPressed: _nextSection,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: _ChaptersDrawer(
        chapterIndex: _state.chapterIndex,
        sectionIndex: _state.sectionIndex,
        onSelectChapter: (int idx) {
          setState(() {
            _state = _state.copyWith(chapterIndex: idx, sectionIndex: 0);
          });
          Navigator.of(context).pop();
        },
        onSelectSection: (int idx) {
          setState(() {
            _state = _state.copyWith(sectionIndex: idx);
          });
          Navigator.of(context).pop();
        },
      ),
      body: body,
      bottomNavigationBar: _QuickActionsBar(
        sprintRemainingSec: _sprintRemainingSec,
        onBookmarkSection: () {
          final String firstBlockId = _section.blocks.first.id;
          _toggleBookmark(firstBlockId);
        },
        onTwoMinuteSprint: () {
          _recordEngagementTick(minutes: 2);
        },
        onGoalBoost: () {
          EngagementService.setDailyGoalMinutes((_goal.minutesPerDay + 5).clamp(5, 120));
        },
        onStartFocusSprint: () => _startSprint(5),
        onCancelFocusSprint: _cancelSprint,
      ),
    );
  }
}

class _ChaptersDrawer extends StatelessWidget {
  final int chapterIndex;
  final int sectionIndex;
  final ValueChanged<int> onSelectChapter;
  final ValueChanged<int> onSelectSection;

  const _ChaptersDrawer({
    required this.chapterIndex,
    required this.sectionIndex,
    required this.onSelectChapter,
    required this.onSelectSection,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _ChaptersPane(
          chapterIndex: chapterIndex,
          sectionIndex: sectionIndex,
          onSelectChapter: onSelectChapter,
          onSelectSection: onSelectSection,
        ),
      ),
    );
  }
}

class _ChaptersPane extends StatelessWidget {
  final int chapterIndex;
  final int sectionIndex;
  final ValueChanged<int> onSelectChapter;
  final ValueChanged<int> onSelectSection;

  const _ChaptersPane({
    required this.chapterIndex,
    required this.sectionIndex,
    required this.onSelectChapter,
    required this.onSelectSection,
  });

  @override
  Widget build(BuildContext context) {
    final List<BookChapter> chapters = BookContent.chapters;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text('Chapters', style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (BuildContext context, int idx) {
                final BookChapter ch = chapters[idx];
                final bool selected = idx == chapterIndex;

                return ExpansionTile(
                  key: ValueKey<String>('ch_${ch.id}'),
                  initiallyExpanded: selected,
                  title: Text(ch.title),
                  subtitle: Text('${ch.minutes} min • ${ch.subtitle}'),
                  children: <Widget>[
                    ...List<Widget>.generate(ch.sections.length, (int sIdx) {
                      final BookSection sec = ch.sections[sIdx];
                      final bool secSelected = selected && sIdx == sectionIndex;

                      return ListTile(
                        selected: secSelected,
                        title: Text(sec.title),
                        leading: Icon(
                          secSelected ? Icons.menu_book : Icons.book_outlined,
                          color: secSelected ? scheme.primary : null,
                        ),
                        onTap: () {
                          onSelectChapter(idx);
                          onSelectSection(sIdx);
                        },
                      );
                    }),
                  ],
                  onExpansionChanged: (bool expanded) {
                    if (expanded) onSelectChapter(idx);
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

class _ReaderPane extends StatelessWidget {
  final BookChapter chapter;
  final BookSection section;
  final ReaderState state;

  final List<Achievement> achievements;
  final DailyChallenge challenge;
  final bool challengeCompleted;
  final ReadingStats stats;
  final ReadingGoal goal;

  final ReaderXp xp;

  final int sprintRemainingSec;
  final int sprintBestStreak;
  final int sprintStreak;

  final int takeawaysCount;

  final VoidCallback onCompleteChallenge;
  final void Function(String blockId) onToggleBookmark;
  final void Function(String blockId) onCycleHighlight;
  final void Function(String blockId, int selected, int? correct) onAnswerQuiz;

  final ValueChanged<int> onStartSprint;
  final VoidCallback onCancelSprint;

  final void Function(BuildContext context, BookBlock block) onOpenTakeaway;

  const _ReaderPane({
    required this.chapter,
    required this.section,
    required this.state,
    required this.achievements,
    required this.challenge,
    required this.challengeCompleted,
    required this.stats,
    required this.goal,
    required this.xp,
    required this.sprintRemainingSec,
    required this.sprintBestStreak,
    required this.sprintStreak,
    required this.takeawaysCount,
    required this.onCompleteChallenge,
    required this.onToggleBookmark,
    required this.onCycleHighlight,
    required this.onAnswerQuiz,
    required this.onStartSprint,
    required this.onCancelSprint,
    required this.onOpenTakeaway,
  });

  String _fmtTime(int sec) {
    final int m = sec ~/ 60;
    final int s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double levelProgress = xp.xpNeededForNextLevel() <= 0
        ? 0
        : (xp.xpIntoLevel() / xp.xpNeededForNextLevel()).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Text(chapter.subtitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(section.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),

        // Progress hooks at the top (fast feedback)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.auto_graph, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('Momentum', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: scheme.primary.withAlpha(30)),
                      ),
                      child: Text(
                        'Lv ${xp.level} • ${xp.xp} XP',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: levelProgress,
                    backgroundColor: scheme.primary.withAlpha(30),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Next level: ${xp.xpIntoLevel()}/${xp.xpNeededForNextLevel()} XP • Takeaways saved: $takeawaysCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        StreakGoalHeader(stats: stats, goal: goal),
        const SizedBox(height: 12),

        // Focus sprint mini-game
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.timer, color: scheme.secondary),
                    const SizedBox(width: 8),
                    Text('Focus sprint', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    if (sprintBestStreak > 0)
                      Text(
                        'Best: $sprintBestStreak',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface.withAlpha(170),
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (sprintRemainingSec > 0) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.secondary.withAlpha(14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: scheme.secondary.withAlpha(30)),
                        ),
                        child: Text(
                          _fmtTime(sprintRemainingSec),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (sprintStreak > 0)
                        Text('Streak: $sprintStreak',
                            style: Theme.of(context).textTheme.labelLarge),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: onCancelSprint,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Don’t multitask. Read one section and save one takeaway.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...<Widget>[
                  Text(
                    'Start a short timer to create urgency + reward.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => onStartSprint(5),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start 5 min'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onStartSprint(10),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Start 10'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        DailyChallengeCard(
          challenge: challenge,
          completed: challengeCompleted,
          onComplete: onCompleteChallenge,
        ),
        const SizedBox(height: 12),

        if (achievements.isNotEmpty) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.emoji_events, color: scheme.secondary),
                      const SizedBox(width: 8),
                      Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: achievements
                        .take(6)
                        .map((Achievement a) => AchievementChip(text: a.title))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        ...section.blocks.map((BookBlock b) {
          final bool bookmarked = state.isBookmarked(b.id);
          final Color? highlight = state.highlightFor(b.id);

          Widget inner;
          switch (b.type) {
            case BookBlockType.heading:
              inner = HeadingBlock(title: b.title ?? '', text: b.text);
              break;
            case BookBlockType.paragraph:
              inner = ParagraphBlock(text: b.text ?? '');
              break;
            case BookBlockType.callout:
              inner = CalloutBlock(title: b.title ?? 'Note', text: b.text ?? '');
              break;
            case BookBlockType.checklist:
              inner = ChecklistBlock(
                title: b.title ?? 'Checklist',
                items: b.items ?? <String>[],
              );
              break;
            case BookBlockType.prompt:
              inner = PromptBlock(title: b.title ?? 'Prompt', text: b.text ?? '');
              break;
            case BookBlockType.code:
              inner = CodeBlock(
                title: b.title ?? 'Code',
                language: b.language ?? 'text',
                code: b.code ?? '',
              );
              break;
            case BookBlockType.quiz:
              inner = QuizBlock(
                block: b,
                selectedIndex: state.quizAnswerFor(b.id),
                onSelect: (int idx) => onAnswerQuiz(b.id, idx, b.correctIndex),
              );
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: <Widget>[
                BlockCard(
                  highlightColor: highlight,
                  bookmarked: bookmarked,
                  onToggleBookmark: () => onToggleBookmark(b.id),
                  onCycleHighlight: () => onCycleHighlight(b.id),
                  child: inner,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => onOpenTakeaway(context, b),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save takeaway'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RightPane extends StatelessWidget {
  final ColorScheme scheme;
  final ReadingStats stats;
  final ReadingGoal goal;
  final List<Achievement> achievements;
  final int activeMinutes;
  final ReaderXp xp;
  final SprintHistory sprintHistory;
  final List<Takeaway> takeaways;

  final VoidCallback onLogMinutes;
  final VoidCallback onStartSprint5;
  final VoidCallback onSetGoal;
  final ValueChanged<String> onDeleteTakeaway;

  const _RightPane({
    required this.scheme,
    required this.stats,
    required this.goal,
    required this.achievements,
    required this.activeMinutes,
    required this.xp,
    required this.sprintHistory,
    required this.takeaways,
    required this.onLogMinutes,
    required this.onStartSprint5,
    required this.onSetGoal,
    required this.onDeleteTakeaway,
  });

  @override
  Widget build(BuildContext context) {
    final String lastReadLabel = stats.lastReadDayEpoch <= 0
        ? 'Never'
        : timeago.format(
            DateTime.fromMillisecondsSinceEpoch(
              stats.lastReadDayEpoch * Duration.millisecondsPerDay,
              isUtc: true,
            ),
            allowFromNow: true,
          );

    final List<Takeaway> recent = takeaways.take(8).toList(growable: false);
    final List<SprintEvent> sprints = sprintHistory.events.take(6).toList(growable: false);

    return Material(
      color: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text('Notes & Momentum', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.insights, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('Today', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Active minutes (this screen): $activeMinutes'),
                  const SizedBox(height: 6),
                  Text('Last read: $lastReadLabel'),
                  const SizedBox(height: 6),
                  Text('Level: ${xp.level} • XP: ${xp.xp}'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onLogMinutes,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Log a 2-minute sprint'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onStartSprint5,
                      icon: const Icon(Icons.timer),
                      label: const Text('Start a 5-min focus sprint'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSetGoal,
                      icon: const Icon(Icons.tune),
                      label: Text('Set goal to 18 min/day (quick) • now ${goal.minutesPerDay}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.bookmarks, color: scheme.secondary),
                      const SizedBox(width: 8),
                      Text('Key takeaways', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        '${takeaways.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurface.withAlpha(160),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (recent.isEmpty)
                    Text(
                      'Save 1 takeaway per section. This builds a “return later” loop.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ...recent.map((Takeaway t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primary.withAlpha(8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.primary.withAlpha(20)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      style: Theme.of(context).textTheme.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete takeaway',
                                    onPressed: () => onDeleteTakeaway(t.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              Text(
                                t.note,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${t.createdDayKeyUtc} • ${t.chapterId} • ${t.sectionId}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.bolt, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('Sprint history', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (sprints.isEmpty)
                    Text(
                      'Start a focus sprint to create urgency + reward.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ...sprints.map((SprintEvent e) {
                      final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                        e.createdAtMsUtc,
                        isUtc: true,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              e.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 18,
                              color: e.completed ? scheme.secondary : scheme.onSurface.withAlpha(120),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${e.minutes} min • +${e.xpAwarded} XP',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(' ${timeago.format(dt)}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 4),
                  Text(
                    'Best streak: ${sprintHistory.bestStreak}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.auto_awesome, color: scheme.secondary),
                      const SizedBox(width: 8),
                      Text('Why this works', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hooks in this app are intentionally lightweight:\n'
                    '• Focus sprints create urgency + a finish line\n'
                    '• XP makes progress visible immediately\n'
                    '• Takeaways create future value (you come back)\n\n'
                    'Rule: 1 section → 1 takeaway → done.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (achievements.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.collections_bookmark, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text('Unlocked', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...achievements.map((Achievement a) {
                      final DateTime dt = DateTime.fromMillisecondsSinceEpoch(a.unlockedAtMs,
                          isUtc: true);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(Icons.check_circle, size: 18, color: scheme.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(a.title, style: Theme.of(context).textTheme.titleSmall),
                                  Text(a.description),
                                  Text(
                                    'Unlocked ${timeago.format(dt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  final int sprintRemainingSec;
  final VoidCallback onBookmarkSection;
  final VoidCallback onTwoMinuteSprint;
  final VoidCallback onGoalBoost;
  final VoidCallback onStartFocusSprint;
  final VoidCallback onCancelFocusSprint;

  const _QuickActionsBar({
    required this.sprintRemainingSec,
    required this.onBookmarkSection,
    required this.onTwoMinuteSprint,
    required this.onGoalBoost,
    required this.onStartFocusSprint,
    required this.onCancelFocusSprint,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: Colors.black.withAlpha(12))),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: onTwoMinuteSprint,
                icon: const Icon(Icons.flash_on),
                label: const Text('2-min'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBookmarkSection,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Boost goal (+5)',
              onPressed: onGoalBoost,
              icon: Icon(Icons.add_circle, color: scheme.secondary),
            ),
            const SizedBox(width: 4),
            if (sprintRemainingSec <= 0)
              IconButton(
                tooltip: 'Start focus sprint (5 min)',
                onPressed: onStartFocusSprint,
                icon: Icon(Icons.timer, color: scheme.primary),
              )
            else
              IconButton(
                tooltip: 'Stop focus sprint',
                onPressed: onCancelFocusSprint,
                icon: Icon(Icons.stop_circle, color: scheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
