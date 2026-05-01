import 'package:flutter/material.dart';
import 'package:vibe_coding_companion/src/features/reader/reader_screen.dart';
import 'package:vibe_coding_companion/src/theme/ocean_theme.dart';

class VibeCodingCompanionApp extends StatelessWidget {
  const VibeCodingCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe Coding Companion',
      theme: OceanTheme.light(),
      darkTheme: OceanTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const ReaderScreen(),
    );
  }
}
