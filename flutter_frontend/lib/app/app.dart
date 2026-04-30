import 'package:flutter/material.dart';

import 'theme/ocean_professional_theme.dart';
import '../features/reader/reader_shell_page.dart';

/// Root application widget for the interactive book app.
///
/// Uses the Ocean Professional theme and launches the reader shell.
class VibeCodingCompanionApp extends StatelessWidget {
  const VibeCodingCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe Coding Companion',
      debugShowCheckedModeBanner: false,
      theme: OceanProfessionalTheme.light(),
      home: const ReaderShellPage(),
    );
  }
}
