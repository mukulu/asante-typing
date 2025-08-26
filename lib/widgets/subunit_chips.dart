// Widget that displays subunit chips and handles selection.

import 'package:asante_typing/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Displays a wrap of choice chips corresponding to subunits for a lesson.
class SubunitChips extends StatelessWidget {
  /// Creates a [SubunitChips] widget.
  const SubunitChips({
    required this.keys, 
    required this.selectedKey, 
    required this.onSelect, 
    required this.unitIndex,
    required this.accent, 
    super.key,
  });

  /// Keys (names) of the subunits to display.
  final Iterable<String> keys;

  /// Currently selected subunit key.
  final String? selectedKey;

  /// Callback when a subunit is selected. Called with the subunit key.
  final ValueChanged<String> onSelect;

  final Color accent;

  final int unitIndex;

  @override
  Widget build(BuildContext context) {
    UnitColors.selectionFill(accent); // Adjusted to match the expected arguments
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final key in keys)
          ChoiceChip(
            label: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            selected: selectedKey == key,
            selectedColor: accent.withValues(alpha: 0.22),
            side: BorderSide(color: accent),
            onSelected: (selected) {
              if (selected) {
                onSelect(key);
              }
            },
          ),
      ],
    );
  }

}
