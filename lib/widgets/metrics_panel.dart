// Widget that displays real‑time typing metrics and visualizations.

import 'package:asante_typing/theme/app_colors.dart';
import 'package:asante_typing/utils/typing_utils.dart';
import 'package:asante_typing/widgets/gauge.dart';
import 'package:flutter/material.dart';

/// Displays the progress bar, WPM and CPM gauges, and basic metrics.
class MetricsPanel extends StatelessWidget {
  /// Creates a [MetricsPanel].
  const MetricsPanel({
    required this.currentLength, required this.typedLength, required this.errors, required this.elapsed, required this.wpm, required this.cpm, super.key,
  });

  /// Total length of the practice text.
  final int currentLength;

  /// Number of characters typed so far.
  final int typedLength;

  /// Number of errors made so far.
  final int errors;

  /// Elapsed time since typing began.
  final Duration elapsed;

  /// Current words per minute.
  final double wpm;

  /// Current characters per minute.
  final double cpm;

  @override
  Widget build(BuildContext context) {
    final progress = currentLength > 0
        ? (typedLength / currentLength).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progress', style: TextStyle(color: kColorRed)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(kColorGreen),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Gauge(label: 'WPM', value: wpm, max: 60),
            const SizedBox(width: 24),
            Gauge(label: 'CPM', value: cpm, max: 300),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('Length: $currentLength', style: const TextStyle(color: kColorRed)),
            Text('Typed: $typedLength', style: const TextStyle(color: kColorRed)),
            Text('Errors: $errors', style: const TextStyle(color: kColorRed)),
            Text('Time: ${formatDuration(elapsed)}', style: const TextStyle(color: kColorRed)),
          ],
        ),
      ],
    );
  }

}
