import 'package:flutter/material.dart';
import 'package:vibe_coding_companion/src/engagement/engagement_models.dart';

class StreakGoalHeader extends StatelessWidget {
  final ReadingStats stats;
  final ReadingGoal goal;

  const StreakGoalHeader({
    super.key,
    required this.stats,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double progress =
        goal.minutesPerDay <= 0 ? 0 : (goal.minutesToday / goal.minutesPerDay).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.local_fire_department, color: scheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '${stats.streakDays} day streak',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(Icons.timer, color: scheme.primary),
                const SizedBox(width: 6),
                Text('${goal.minutesToday}/${goal.minutesPerDay} min'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: scheme.primary.withAlpha(30),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              progress >= 1.0 ? 'Goal complete for today. Keep going for bonus progress.' : 'Read a bit more to hit today’s goal.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final bool completed;
  final VoidCallback onComplete;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    required this.completed,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.bolt, color: scheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Daily challenge',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Completed',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: scheme.secondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              challenge.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(challenge.description),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: completed ? null : onComplete,
                icon: const Icon(Icons.check),
                label: const Text('Mark done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementChip extends StatelessWidget {
  final String text;

  const AchievementChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withAlpha(30)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
