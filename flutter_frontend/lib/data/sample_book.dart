import '../models/book_models.dart';

/// Sample local book content for MVP.
///
/// This keeps step 1 self-contained (no asset pipeline needed yet) while still
/// exercising chapter navigation, reader layout, and note persistence.
class SampleBookRepository {
  const SampleBookRepository();

  Future<Book> loadBook() async {
    // No await needed; still return a Future for future extensibility.
    return const Book(
      id: 'vibe-coding-book',
      title: 'Vibe Coding Companion',
      chapters: [
        Chapter(
          id: 'ch-1',
          title: '1. What is Vibe Coding?',
          sections: [
            Section(
              id: 'ch-1-sec-1',
              title: 'Definition & intent',
              markdown: '''
# What is vibe coding?

**Vibe coding** is a way of writing software by focusing on *momentum* and *feedback loops*.
It emphasizes:

- Rapid iteration
- Tight feedback (run it, see it, adjust)
- Keeping complexity in check
- Treating “developer experience” as a feature

> The goal is not to be reckless; the goal is to stay in flow while still shipping quality.
''',
            ),
            Section(
              id: 'ch-1-sec-2',
              title: 'A practical loop',
              markdown: '''
# A practical loop

A simple vibe-coding loop looks like:

1. Pick the smallest slice of value
2. Implement a thin vertical path
3. Add guardrails (types/tests/lints) as you go
4. Refactor only when friction appears

**Rule of thumb:** If you can’t explain the current behavior in one paragraph, simplify before adding more features.
''',
            ),
          ],
        ),
        Chapter(
          id: 'ch-2',
          title: '2. Tools & Setup',
          sections: [
            Section(
              id: 'ch-2-sec-1',
              title: 'Editor and commands',
              markdown: '''
# Tools & setup

Good defaults:

- formatter + lints on save
- one command to run the app
- one command to run tests
- a fast way to inspect state/logs

In Flutter, your best friend is **hot reload**.
''',
            ),
            Section(
              id: 'ch-2-sec-2',
              title: 'Guardrails',
              markdown: '''
# Guardrails

Vibe coding works best with guardrails:

- static analysis
- small, composable widgets
- persistent state only where it’s necessary

In this app, we persist:
- reading progress
- notes / annotations
''',
            ),
          ],
        ),
        Chapter(
          id: 'ch-3',
          title: '3. Notes, Annotations, and Memory',
          sections: [
            Section(
              id: 'ch-3-sec-1',
              title: 'Why notes matter',
              markdown: '''
# Why notes matter

Reading is great, but *retention* comes from interaction.

Notes help you:
- connect ideas to your own context
- track questions
- build a personal index of insights

This app supports notes per section, and optional quotes.
''',
            ),
          ],
        ),
      ],
    );
  }
}
