// Left navigation panel listing all units.

import 'package:asante_typing/models/units.dart';
import 'package:asante_typing/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Displays the list of lessons (units) in a sidebar and handles unit
/// selection. Highlights the currently selected unit.
class LeftNav extends StatelessWidget {
  /// Creates a [LeftNav] widget.
  const LeftNav({
    required this.lessons, 
    required this.selectedIndex, 
    required this.onSelect, 
    required this.accent, 
    super.key,
  });

  /// List of lessons (units) to display.
  final List<Lesson> lessons;

  /// Index of the currently selected unit.
  final int selectedIndex;

  /// Callback when a unit is selected. Called with the index of the new unit.
  final ValueChanged<int> onSelect;

  final Color accent;

  Color get selectedBg => UnitColors.darken(kColorGreen, 0.18); // darker than accent

  @override
  Widget build(BuildContext context) {
    return Container(
      // Optional: overall panel tint—keep it subtle for readability.
      color: kColorYellow,
      width: MediaQuery.of(context).size.width * 0.25,
      child: ListView.separated(
        itemCount: lessons.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final accent = UnitColors.accent(index);
          return ListTile(
            dense: true,
            selected: isSelected,
            // Subtle fill derived from unit accent (no deprecated withOpacity)
            selectedTileColor: UnitColors.selectionFill(selectedBg),
            tileColor: isSelected ? selectedBg : null, // keeps the color even if theme ignores selectedTileColor
            selectedColor: kColorRed,
             // A slim accent stripe helps at-a-glance staging
            leading: Container(
              width: 6,
              height: double.infinity,
              color: accent,
            ),
            // Keep text legible and on-brand
            textColor: kColorRed,
            title: Text(
              'Unit ${index + 1}: ${lessons[index].title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? (selectedBg.computeLuminance() > 0.5 ? kColorRed : kColorGreen) : null,
                ),
              ),
              // optional border + rounded look for a clearer “pill” selection
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: isSelected
                    ? BorderSide(color: UnitColors.accent(index).withValues(alpha: 0.9), width: 1.2)
                    : BorderSide.none,
              ),
                // nicer hover focus (desktop/web)
              hoverColor: UnitColors.hoverShade(accent, isSelected: isSelected),
              focusColor: UnitColors.hoverShade(accent, isSelected: isSelected),
            onTap: () => onSelect(index),
          );
        },
      ),
    );
  }

}
