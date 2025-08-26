// A reusable circular gauge widget used to display WPM and CPM.
import 'package:asante_typing/state/zoom_scope.dart';
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
    required this.label, 
    required this.value, 
    required this.max,
    required this.accent,
    this.footer,
    super.key,
    this.size = 110,
    this.iconSize = 28,
    this.icon = Icons.speed,
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

  final double iconSize;

  final IconData icon;

  final Color accent;

  final String? footer;

  @override
  Widget build(BuildContext context) {
    // Clamp ratio between 0 and 1 to avoid overflow.
    final clamped = value.isFinite ? value.clamp(0, max).toDouble() : 0.0;
    final progress = max > 0 ? (clamped / max) : 0.0; // 0..1 for the arc
    final centerText = max == 100.0
          ? '${clamped.toStringAsFixed(0)}%'
          : clamped.toStringAsFixed(clamped < 10 ? 1 : 0);

    final zoomScale = ZoomScope.of(context).scale;
    final effSize = size * zoomScale;                   // scale the diameter
    final effIconSize = iconSize * zoomScale;           // scale the icon
    final effStroke = (8 * zoomScale).clamp(6.0, 14.0); // scale the arc width (keep sane)


    return SizedBox(
      width: effSize,
      height: effSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: effSize,
            height: effSize,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: effStroke,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          // Center content (icon + value)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: effIconSize, color: kColorRed),
              const SizedBox(height: 4),
              Text(
                centerText, // ← use the formatted value (% for max==100)
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kColorRed,
                ),
              ),
              // Footer (e.g., "123 / 300" or "57.4")
              if (footer != null) ...[
                const SizedBox(height: 4),
                Text(
                  footer!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),


        ],
      ),
    );
  }

}
