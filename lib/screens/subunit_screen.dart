import 'package:flutter/material.dart';

import '../models/units.dart';
import 'lesson_screen.dart';

/// Page that lists all subunits for a given lesson (unit).  Each subunit
/// represents a different type of exercise such as Grip, Words, Control,
/// Sentences or Test.  Selecting a subunit navigates to the practice
/// interface.
class SubunitScreen extends StatelessWidget {
  final Lesson lesson;
  final int unitNumber;

  const SubunitScreen({
    super.key,
    required this.lesson,
    required this.unitNumber,
  });

  @override
  Widget build(BuildContext context) {
    final entries = lesson.subunits.entries.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Unit $unitNumber: ${lesson.title}'),
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final subunitName = entries[index].key;
          return ListTile(
            title: Text(subunitName),
            trailing: const Icon(Icons.keyboard),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LessonScreen(
                    lesson: lesson,
                    subunitKey: subunitName,
                    unitNumber: unitNumber,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}