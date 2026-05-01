import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vibe_coding_companion/src/book/book_content.dart';
import 'package:vibe_coding_companion/src/book/book_models.dart';
import 'package:vibe_coding_companion/src/engagement/engagement_models.dart';
import 'package:vibe_coding_companion/src/engagement/engagement_service.dart';
import 'package:vibe_coding_companion/src/features/engagement/engagement_widgets.dart';
import 'package:vibe_coding_companion/src/features/reader/block_widgets.dart';
import 'package:vibe_coding_companion/src/features/reader/reader_persistence.dart';
import 'package:vibe_coding_companion/src/features/reader/reader_state.dart';

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
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final (Set<String> bookmarks, Map<String, Color> highlights) =
        await ReaderPersistence.load();
    final (ReadingStats stats, ReadingGoal goal, List<Achievement> achievements) =
        await EngagementService.load();

    // No context usage after await: only update primitives/state.
    setState(() {
      _state = _state.copyWith(
        bookmarkedBlockIds: bookmarks,
        highlightsByBlockId: highlights,
      );
      _stats = stats;
      _goal = goal;
      _achievements = achievements;
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
        _state = _state.copyWith(chapterIndex: c - 1, sectionIndex: prev.sections.length - 1);
      });
    }
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
                    child: wide ? _ChaptersPane(
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
                    ) : const SizedBox.shrink(),
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
                      onCompleteChallenge: _completeDailyChallenge,
                      onToggleBookmark: (String blockId) => _toggleBookmark(blockId),
                      onCycleHighlight: (String blockId) => _cycleHighlight(blockId),
                      onAnswerQuiz: (String blockId, int selected, int? correct) =>
                          _answerQuiz(blockId, selected, correct),
                    ),
                  ),

                  // Right: notes/engagement
                  SizedBox(
                    width: wide ? 320 : 0,
                    child: wide
                        ? _RightPane(
                            scheme: scheme,
                            stats: _stats,
                            goal: _goal,
                            achievements: _achievements,
                            activeMinutes: _activeMinutesCounter,
                            onLogMinutes: () {
                              // record a tiny session tick to feed streak/goals
                              _recordEngagementTick(minutes: 2);
                            },
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
        onBookmarkSection: () {
          // addictive: "save this section" by bookmarking first block
          final String firstBlockId = _section.blocks.first.id;
          _toggleBookmark(firstBlockId);
        },
        onTwoMinuteSprint: () {
          // logs 2 minutes; acts as a "micro-session" button
          _recordEngagementTick(minutes: 2);
        },
        onGoalBoost: () {
          // quick goal bump
          EngagementService.setDailyGoalMinutes((_goal.minutesPerDay + 5).clamp(5, 120));
        },
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

  final VoidCallback onCompleteChallenge;
  final void Function(String blockId) onToggleBookmark;
  final void Function(String blockId) onCycleHighlight;
  final void Function(String blockId, int selected, int? correct) onAnswerQuiz;

  const _ReaderPane({
    required this.chapter,
    required this.section,
    required this.state,
    required this.achievements,
    required this.challenge,
    required this.challengeCompleted,
    required this.stats,
    required this.goal,
    required this.onCompleteChallenge,
    required this.onToggleBookmark,
    required this.onCycleHighlight,
    required this.onAnswerQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Text(chapter.subtitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          section.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),

        StreakGoalHeader(stats: stats, goal: goal),
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
              inner = ChecklistBlock(title: b.title ?? 'Checklist', items: b.items ?? <String>[]);
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
            child: BlockCard(
              highlightColor: highlight,
              bookmarked: bookmarked,
              onToggleBookmark: () => onToggleBookmark(b.id),
              onCycleHighlight: () => onCycleHighlight(b.id),
              child: inner,
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
  final VoidCallback onLogMinutes;
  final VoidCallback onSetGoal;

  const _RightPane({
    required this.scheme,
    required this.stats,
    required this.goal,
    required this.achievements,
    required this.activeMinutes,
    required this.onLogMinutes,
    required this.onSetGoal,
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
                      Icon(Icons.auto_awesome, color: scheme.secondary),
                      const SizedBox(width: 8),
                      Text('Why this works', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Streaks + micro-sprints + daily challenge create a loop:\n'
                    '1) Small action\n'
                    '2) Immediate progress signal\n'
                    '3) Next tiny step\n\n'
                    'Use the bottom bar when you feel stuck.',
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
                      final DateTime dt = DateTime.fromMillisecondsSinceEpoch(a.unlockedAtMs, isUtc: true);
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
  final VoidCallback onBookmarkSection;
  final VoidCallback onTwoMinuteSprint;
  final VoidCallback onGoalBoost;

  const _QuickActionsBar({
    required this.onBookmarkSection,
    required this.onTwoMinuteSprint,
    required this.onGoalBoost,
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
                label: const Text('2-min sprint'),
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
          ],
        ),
      ),
    );
  }
}
