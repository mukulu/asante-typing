import 'package:asante_typing/screens/tutor_page.dart';
import 'package:flutter/material.dart';

/// Entry point for the Asante Typing application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AsanteTypingApp());
}

/// Root widget that configures theme and routes.
class AsanteTypingApp extends StatelessWidget {
  const AsanteTypingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asante Typing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TutorPage(),
    );
  }
}
