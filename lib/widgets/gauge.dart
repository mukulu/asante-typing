// A reusable circular gauge widget used to display WPM and CPM.

import 'package:asante_typing/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A simple circular gauge for displaying progress toward a target value.
///
/// Displays a label and a numerical value inside a circular progress
/// indicator. The [max] parameter defines the value corresponding to a
/// full circle. Values greater than [max] will be clamped.
class Gauge extends StatelessWidget {
  /// Creates a gauge with the given [label], [value] and [max] target.
  const Gauge({
    required this.label, required this.value, required this.max, super.key,
    this.size = 84,
  });

  /// Label shown below the value (for example, `WPM` or `CPM`).
  final String label;

  /// Current value to display. Typically the words per minute or
  /// characters per minute calculated in real time.
  final double value;

  /// Maximum value that corresponds to a full 360° progress.
  final double max;

  /// Diameter of the gauge in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    // Clamp ratio between 0 and 1 to avoid overflow.
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final display = value.isFinite ? value.toStringAsFixed(0) : '0';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(kColorGreen),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                display,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kColorRed,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: kColorRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
