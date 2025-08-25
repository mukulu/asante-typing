import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/units.dart';
import 'subunit_screen.dart';

/// The home screen lists all available units.  It asynchronously loads
/// the unit definitions from the bundled JSON file and displays each
/// unit as a list tile.  Tapping a unit navigates to a page showing
/// its subunits.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<UnitsData> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _unitsFuture = _loadUnits();
  }

  Future<UnitsData> _loadUnits() async {
    final jsonString = await rootBundle.loadString('assets/units.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return UnitsData.fromJson(jsonMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Display the rebranded application name in the home page header.
        title: const Text('Asante Typing'),
      ),
      body: FutureBuilder<UnitsData>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load lessons: ${snapshot.error}'));
          }
          final units = snapshot.data!;
          final lessons = units.main;
          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return ListTile(
                title: Text('Unit ${index + 1}: ${lesson.title}'),
                subtitle: Text(lesson.subunits.keys.join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SubunitScreen(
                        lesson: lesson,
                        unitNumber: index + 1,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}