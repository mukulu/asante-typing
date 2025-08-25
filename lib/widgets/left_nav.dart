// Left navigation panel listing all units.

import 'package:asante_typing/models/units.dart';
import 'package:asante_typing/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Displays the list of lessons (units) in a sidebar and handles unit
/// selection. Highlights the currently selected unit.
class LeftNav extends StatelessWidget {
  /// Creates a [LeftNav] widget.
  const LeftNav({
    required this.lessons, required this.selectedIndex, required this.onSelect, super.key,
  });

  /// List of lessons (units) to display.
  final List<Lesson> lessons;

  /// Index of the currently selected unit.
  final int selectedIndex;

  /// Callback when a unit is selected. Called with the index of the new unit.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kColorYellow,
      width: MediaQuery.of(context).size.width * 0.25,
      child: ListView.separated(
        itemCount: lessons.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white),
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          final isSelected = index == selectedIndex;
          return ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor: kColorGreen.withValues(alpha: 0.15),
            selectedColor: kColorRed,
            textColor: kColorRed,
            title: Text('Unit ${index + 1}: ${lesson.title}'),
            onTap: () => onSelect(index),
          );
        },
      ),
    );
  }

}
