import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// Entry point for the typing tutor application.  Creates a Material
/// application with a simple blue theme and sets the home screen to
/// display the list of available units.  This widget is intentionally
/// lightweight; all heavy lifting occurs in the screens themselves.
void main() {
  runApp(const TypingTutorApp());
}

class TypingTutorApp extends StatelessWidget {
  const TypingTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Typing Tutor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}