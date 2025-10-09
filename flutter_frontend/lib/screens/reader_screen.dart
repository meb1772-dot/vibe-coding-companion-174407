import 'package:flutter/material.dart';

/// Temporary ReaderScreen stub to allow routing and preview.
/// Replace with full reading pane, navigation drawer, and notes sidebar later.
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibe Coding Companion'),
        actions: const [
          _HeaderActionBar(),
        ],
      ),
      drawer: const _ReaderDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Optional left spacer when wide to mimic a table-of-contents area in future.
                if (isWide) const SizedBox(width: 8),
                // Reading card
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 1,
                      surfaceTintColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome to Vibe Coding',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary,
                                    )),
                            const SizedBox(height: 12),
                            Text(
                              'Your interactive companion for learning vibe coding concepts. '
                              'This is a placeholder reading view. The full app will include chapters, '
                              'annotations, and interactive examples.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                Chip(label: Text('Beginner')),
                                Chip(label: Text('Interactive')),
                                Chip(label: Text('Annotations')),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text('Start Reading'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Notes/annotations placeholder panel when wide
                if (isWide)
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16, left: 8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(16),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notes',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    )),
                            const SizedBox(height: 12),
                            Text(
                              'Capture insights and highlights as you read. '
                              'This is a placeholder notes sidebar for preview.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.note_add_outlined),
                              label: const Text('Add Note'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Read'),
          NavigationDestination(icon: Icon(Icons.sticky_note_2_outlined), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}

class _HeaderActionBar extends StatelessWidget {
  const _HeaderActionBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          tooltip: 'Search',
          onPressed: () {},
          icon: const Icon(Icons.search),
          color: cs.primary,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _ReaderDrawer extends StatelessWidget {
  const _ReaderDrawer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: Text(
                'Chapters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.looks_one_outlined),
              title: Text('Introduction to Vibe Coding'),
            ),
            const ListTile(
              leading: Icon(Icons.looks_two_outlined),
              title: Text('Core Concepts'),
            ),
            const ListTile(
              leading: Icon(Icons.looks_3_outlined),
              title: Text('Advanced Patterns'),
            ),
          ],
        ),
      ),
    );
  }
}
