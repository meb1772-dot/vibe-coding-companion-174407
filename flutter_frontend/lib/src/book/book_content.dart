import 'package:vibe_coding_companion/src/book/book_models.dart';

class BookContent {
  BookContent._();

  static const List<BookChapter> chapters = <BookChapter>[
    BookChapter(
      id: 'ch1',
      title: '1. What is Vibe Coding?',
      subtitle: 'Coding with flow, feedback, and intention',
      minutes: 8,
      sections: <BookSection>[
        BookSection(
          id: 'ch1_s1',
          title: 'The core loop',
          blocks: <BookBlock>[
            BookBlock(
              id: 'b_ch1_s1_h1',
              type: BookBlockType.heading,
              title: 'Vibe Coding = fast iteration + sharp feedback',
              text:
                  'Vibe coding is a way of building where you keep momentum by shortening the distance between an idea and a working result. '
                  'You do this by making tiny changes, checking them immediately, and letting the product “pull” the next step.',
            ),
            BookBlock(
              id: 'b_ch1_s1_p1',
              type: BookBlockType.paragraph,
              text:
                  'A practical definition: vibe coding is the habit of staying in a productive emotional state (curious, playful, focused) while still shipping real outcomes.',
            ),
            BookBlock(
              id: 'b_ch1_s1_callout',
              type: BookBlockType.callout,
              title: 'Pro tip',
              text:
                  'If you feel stuck, shrink the task. You don’t need “the feature”, you need the next 5 minutes of progress.',
            ),
            BookBlock(
              id: 'b_ch1_s1_check',
              type: BookBlockType.checklist,
              title: 'Micro-iteration checklist',
              items: <String>[
                'Make the change tiny enough to test in < 2 minutes',
                'Run it / preview it immediately',
                'Write down the next smallest step',
                'Stop when you still have momentum (leave a breadcrumb)',
              ],
            ),
          ],
        ),
        BookSection(
          id: 'ch1_s2',
          title: 'A tiny example',
          blocks: <BookBlock>[
            BookBlock(
              id: 'b_ch1_s2_p1',
              type: BookBlockType.paragraph,
              text:
                  'Instead of “build the reader UI”, you might start with: render a chapter title, then add a section list, then add a single block renderer.',
            ),
            BookBlock(
              id: 'b_ch1_s2_code',
              type: BookBlockType.code,
              title: 'Decompose big tasks into tiny commits',
              language: 'text',
              code: '''
- [ ] Show chapter title
- [ ] Render section headers
- [ ] Render paragraph blocks
- [ ] Add bookmarks
- [ ] Add streak + daily challenge
''',
            ),
            BookBlock(
              id: 'b_ch1_s2_quiz',
              type: BookBlockType.quiz,
              title: 'Quick quiz',
              text: 'Which choice best matches vibe coding?',
              options: <QuizOption>[
                QuizOption(id: 'a', text: 'Plan everything in detail first'),
                QuizOption(id: 'b', text: 'Iterate quickly with feedback loops'),
                QuizOption(id: 'c', text: 'Avoid testing until the end'),
              ],
              correctIndex: 1,
              explanation:
                  'Vibe coding is about tight feedback loops and momentum: small steps, quick checks.',
            ),
          ],
        ),
      ],
    ),
    BookChapter(
      id: 'ch2',
      title: '2. The Momentum Engine',
      subtitle: 'Habits that keep you shipping',
      minutes: 10,
      sections: <BookSection>[
        BookSection(
          id: 'ch2_s1',
          title: 'Friction audit',
          blocks: <BookBlock>[
            BookBlock(
              id: 'b_ch2_s1_h1',
              type: BookBlockType.heading,
              title: 'Remove friction like it’s a bug',
              text:
                  'Most “motivation problems” are friction problems. Treat every slowdown as a defect you can fix.',
            ),
            BookBlock(
              id: 'b_ch2_s1_prompt',
              type: BookBlockType.prompt,
              title: '2-minute friction audit',
              text:
                  'What is the first annoying step between you and running your app right now? '
                  'Write it down. Then make a one-step improvement.',
            ),
            BookBlock(
              id: 'b_ch2_s1_check',
              type: BookBlockType.checklist,
              title: 'Common friction killers',
              items: <String>[
                'One-command dev startup',
                'Fast hot reload / preview',
                'Small reusable UI components',
                'Clear “next step” notes',
              ],
            ),
          ],
        ),
        BookSection(
          id: 'ch2_s2',
          title: 'Progress visible = progress addictive',
          blocks: <BookBlock>[
            BookBlock(
              id: 'b_ch2_s2_p1',
              type: BookBlockType.paragraph,
              text:
                  'Humans stay engaged when progress is visible. That’s why streaks, checklists, and small achievements work.',
            ),
            BookBlock(
              id: 'b_ch2_s2_callout',
              type: BookBlockType.callout,
              title: 'In this app',
              text:
                  'You’ll see streaks, achievements, and daily challenges. They’re lightweight on purpose: enough to nudge you, not overwhelm you.',
            ),
          ],
        ),
      ],
    ),
    BookChapter(
      id: 'ch3',
      title: '3. Prompts, Patterns, and Guardrails',
      subtitle: 'How to collaborate with AI without getting sloppy',
      minutes: 12,
      sections: <BookSection>[
        BookSection(
          id: 'ch3_s1',
          title: 'Guardrails',
          blocks: <BookBlock>[
            BookBlock(
              id: 'b_ch3_s1_h1',
              type: BookBlockType.heading,
              title: 'Guardrails keep speed safe',
              text:
                  'Speed without guardrails becomes chaos. A guardrail is a rule you follow even when you’re excited.',
            ),
            BookBlock(
              id: 'b_ch3_s1_check',
              type: BookBlockType.checklist,
              title: 'My 5 guardrails',
              items: <String>[
                'Always run the app after meaningful changes',
                'Keep commits small and reversible',
                'Avoid “mystery code”: if you can’t explain it, refactor it',
                'Write down assumptions in plain language',
                'Prefer simple over clever',
              ],
            ),
            BookBlock(
              id: 'b_ch3_s1_quiz',
              type: BookBlockType.quiz,
              title: 'Quick quiz',
              text: 'A good guardrail is…',
              options: <QuizOption>[
                QuizOption(id: 'a', text: 'A strict process that blocks iteration'),
                QuizOption(id: 'b', text: 'A simple rule that prevents common failure'),
                QuizOption(id: 'c', text: 'Only for advanced developers'),
              ],
              correctIndex: 1,
              explanation:
                  'Guardrails are lightweight and practical; they prevent predictable mistakes while you move fast.',
            ),
          ],
        ),
        BookSection(
          id: 'ch3_s2',
          title: 'Prompt pattern',
          blocks: <BookBlock>[
            BookBlock(
              id: 'b_ch3_s2_p1',
              type: BookBlockType.paragraph,
              text:
                  'When asking an AI for help, include: context, constraints, examples, and what “done” looks like.',
            ),
            BookBlock(
              id: 'b_ch3_s2_code',
              type: BookBlockType.code,
              title: 'A high-signal prompt template',
              language: 'text',
              code: '''
You are helping me build: <what>
Constraints:
- <platform/framework>
- <style/architecture rules>
Existing code:
- <relevant snippet or file list>
Task:
- <exact change requested>
Done means:
- <how to verify>
''',
            ),
          ],
        ),
      ],
    ),
  ];
}
