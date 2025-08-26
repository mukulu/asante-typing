import 'package:asante_typing/screens/tutor_page.dart';
import 'package:asante_typing/state/zoom_controller.dart';
import 'package:asante_typing/state/zoom_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Define custom zoom intents
class ZoomInIntent extends Intent { const ZoomInIntent(); }
class ZoomOutIntent extends Intent { const ZoomOutIntent(); }
class ZoomResetIntent extends Intent { const ZoomResetIntent(); }


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final zoom = ZoomController();
  await zoom.restore(); // restore persisted scale before building the app

  runApp(
    ZoomScope(
      controller: zoom,
      child: const AsanteTypingApp(),
    ),
  );
}

/// Root widget that configures theme and routes.
class AsanteTypingApp extends StatelessWidget {
  const AsanteTypingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final zoomController = ZoomScope.of(context);
    final scale = zoomController.scale;

    return MaterialApp(
      title: 'Asante Typing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Apply text scaling from zoom
        final content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );

        // Keyboard shortcuts for zoom
        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            // Windows/Linux
            SingleActivator(LogicalKeyboardKey.minus,  control: true): ZoomOutIntent(),
            SingleActivator(LogicalKeyboardKey.equal,  control: true): ZoomInIntent(),
            SingleActivator(LogicalKeyboardKey.digit0, control: true): ZoomResetIntent(),
            // macOS
            SingleActivator(LogicalKeyboardKey.minus,  meta: true): ZoomOutIntent(),
            SingleActivator(LogicalKeyboardKey.equal,  meta: true): ZoomInIntent(),
            SingleActivator(LogicalKeyboardKey.digit0, meta: true): ZoomResetIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              ZoomOutIntent:  CallbackAction<ZoomOutIntent>( onInvoke: (_) { zoomController.zoomOut();  return null; }),
              ZoomInIntent:   CallbackAction<ZoomInIntent>(  onInvoke: (_) { zoomController.zoomIn();   return null; }),
              ZoomResetIntent:CallbackAction<ZoomResetIntent>(onInvoke: (_) { zoomController.reset();    return null; }),
            },
            child: content,
          ),
        );
      },
      home: const TutorPage(),
    );
  }
}
