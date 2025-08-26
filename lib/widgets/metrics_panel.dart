// Widget that displays real‑time typing metrics and visualizations.

import 'package:asante_typing/widgets/gauge.dart';
import 'package:flutter/material.dart';

/// Displays the progress bar, WPM and CPM gauges, and basic metrics.
class MetricsPanel extends StatelessWidget {
  /// Creates a [MetricsPanel].
  const MetricsPanel({
    required this.currentLength, 
    required this.typedLength, 
    required this.errors, 
    required this.elapsed, 
    required this.wpm, 
    required this.cpm, 
    required this.accent,
    required this.isComplete,
    required this.total,
    required this.typed,
    super.key,
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

  final Color accent;

  final bool isComplete;     // new: toggles summary styling
  final int total;           // total target chars
  final int typed;           // chars typed so far

  @override
  Widget build(BuildContext context) {
    final correct = (typed - errors).clamp(0, typed);
    final progress = total > 0 ? typed / total : 0.0;        // 0.0 … 1.0
    final accuracy = typed > 0 ? correct / typed : 0.0;      // 0.0 … 1.0

    // Container styling changes slightly when completed (like your summary card)
    final panelBg = isComplete ? accent.withValues(alpha: 0.08) : Colors.transparent;
    final panelBorder = isComplete ? Border.all(color: accent) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBg,
        border: panelBorder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Lay out the four gauges responsively
          final isNarrow = constraints.maxWidth < 600;
          final spacing = isNarrow ? 12.0 : 16.0;

          final gauges = <Widget>[
            Gauge(
              label: 'Progress',
              value: progress * 100.0,     // percent to 0..100
              max: 100,
              accent: accent,
              footer: '$typed / $total',
            ),
            Gauge(
              label: 'Accuracy',
              value: accuracy * 100.0,     // percent to 0..100
              max: 100,
              accent: accent,
              footer: '$correct / $typed',
            ),
            Gauge(
              label: 'Words/min.',
              value: wpm,
              max: 80,                   // tune to taste or make a const
              accent: accent,
              footer: wpm.isFinite ? wpm.toStringAsFixed(1) : '0.0',
            ),
            Gauge(
              label: 'Chars/min.',
              value: cpm,
              max: 400,                  // tune to taste
              accent: accent,
              footer: cpm.isFinite ? cpm.toStringAsFixed(0) : '0',
            ),
          ];

          if (isNarrow) {
            return Wrap(spacing: spacing, runSpacing: spacing, children: gauges);
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: gauges
                .map((g) => SizedBox(width: (constraints.maxWidth - 3*spacing) / 4, child: g))
                .toList(),
          );
        },
      ),
    );
  }

}
