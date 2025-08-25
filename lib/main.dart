import 'package:flutter/material.dart';

import 'screens/tutor_page.dart';

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
    // Set up a Material application for the Asante Typing tutor.  The title
    // and theme are customised to reflect the rebranded name introduced
    // upstream.  This app can run as a web application as well as on
    // mobile platforms.
    return MaterialApp(
      // Use the new application title based on the rebranding from
      // QuickQWERTY to Asante Typing.  This text appears in the
      // browser tab title when deployed as a web app.
      title: 'Asante Typing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TutorPage(),
    );
  }
}