import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/theme/ocean_theme.dart';
import 'package:flutter_frontend/screens/reader_screen.dart';

void main() {
  // Entry point: wire providers (placeholders for now) and run app.
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder MultiProvider wiring to be filled later with real state.
    return MultiProvider(
      providers: const [
        // Add providers here later, e.g. ChangeNotifierProvider(create: (_) => ReaderState()),
      ],
      child: MaterialApp(
        title: 'Vibe Coding Companion',
        theme: OceanTheme.theme,
        // Use InheritedMediaQuery for responsive behavior across platforms if needed.
        // In MaterialApp v3, this is not a direct parameter; wrap the app in MediaQuery if needed elsewhere.
        // Set initial route and onGenerateRoute for navigation.
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
