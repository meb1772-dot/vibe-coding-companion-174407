import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/theme/ocean_theme.dart';
import 'package:flutter_frontend/screens/reader_screen.dart';
import 'package:flutter_frontend/state/book_state.dart';
import 'package:flutter_frontend/state/annotation_state.dart';

void main() {
  // Entry point: wire providers and run app.
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide BookState and AnnotationState to the app, and initialize content on start.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookState>(
          create: (_) {
            final bs = BookState();
            // Initialize asynchronously; do not use context after await per async rules.
            // We trigger without awaiting here to avoid build context issues.
            bs.initialize();
            return bs;
          },
        ),
        ChangeNotifierProvider<AnnotationState>(
          create: (_) => AnnotationState(),
        ),
      ],
      child: MaterialApp(
        title: 'Vibe Coding Companion',
        theme: OceanTheme.theme,
        initialRoute: '/reader',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/reader':
              return MaterialPageRoute<void>(
                builder: (_) => const ReaderScreen(),
                settings: settings,
              );
            default:
              return MaterialPageRoute<void>(
                builder: (_) => const ReaderScreen(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}
