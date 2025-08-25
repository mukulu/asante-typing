// Widget that displays the final summary after completing a subunit.

import 'package:asante_typing/theme/app_colors.dart';
import 'package:asante_typing/utils/typing_utils.dart';
import 'package:asante_typing/widgets/gauge.dart';
import 'package:flutter/material.dart';

/// Shows final results including WPM, CPM, progress and accuracy once typing
/// for a subunit is complete.
class SessionSummary extends StatelessWidget {
  /// Creates a [SessionSummary].
  const SessionSummary({
    required this.length, required this.typed, required this.errors, required this.wpm, required this.cpm, required this.accuracy, required this.duration, super.key,
  });

  /// Total length of the text.
  final int length;
  /// Total typed characters.
  final int typed;
  /// Total errors made.
  final int errors;
  /// Final words per minute.
  final double wpm;
  /// Final characters per minute.
  final double cpm;
  /// Final accuracy percentage.
  final double accuracy;
  /// Duration of the session.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final progress = length > 0 ? (typed / length).clamp(0.0, 1.0) : 0.0;
    return Card(
      color: kColorGreen.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Summary',
              style: TextStyle(fontWeight: FontWeight.bold, color: kColorRed),
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
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(kColorGreen),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('Length: $length', style: const TextStyle(color: kColorRed)),
                Text('Typed: $typed', style: const TextStyle(color: kColorRed)),
                Text('Errors: $errors', style: const TextStyle(color: kColorRed)),
                Text('Accuracy: ${accuracy.toStringAsFixed(1)}%', style: const TextStyle(color: kColorRed)),
                Text('Time: ${formatDuration(duration)}', style: const TextStyle(color: kColorRed)),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
