import 'package:flutter/material.dart';
import 'screens/tutor_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AsanteTypingApp());
}

class AsanteTypingApp extends StatelessWidget {
  const AsanteTypingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asante Typing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const TutorPage(),
    );
  }
}
