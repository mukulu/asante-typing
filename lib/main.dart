import 'package:asante_typing/screens/tutor_page.dart';
import 'package:asante_typing/state/zoom_controller.dart';
import 'package:asante_typing/state/zoom_scope.dart';
import 'package:flutter/material.dart';
/// Entry point for the Asante Typing application.
void main() {
  final zoom = ZoomController();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ZoomScope(controller: zoom, child: AsanteTypingApp(zoom: zoom)));
}

/// Root widget that configures theme and routes.
class AsanteTypingApp extends StatelessWidget {
  const AsanteTypingApp({
    required this.zoom, super.key,
  });

  final ZoomController zoom;

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
