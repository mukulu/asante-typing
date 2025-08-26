// Widget that displays real‑time typing metrics and visualizations.
import 'package:asante_typing/state/zoom_scope.dart';
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
    final progress = total > 0 ? typed / total : 0.0;    // 0.0 … 1.0
    final accuracy = typed > 0 ? correct / typed : 0.0;  // 0.0 … 1.0

    // When completed, give the panel a subtle “summary” look
    final panelBg     = isComplete ? accent.withValues(alpha: 0.08) : Colors.transparent;
    final panelBorder = isComplete ? Border.all(color: accent) : null;

    // Pick up the current zoom (Text scaling)
    final zoomScale = ZoomScope.of(context).scale;  // 1.0 = normal

    // Size the gauges & icons as zoom increases
    final gaugeSize = (110.0 * zoomScale).clamp(110.0, 170.0);
    final iconSize  = (28.0  * zoomScale).clamp(28.0,  36.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        // Give headroom so text/values don’t clip when zoomed
        minHeight: gaugeSize + 36,
      ),
      decoration: BoxDecoration(
        color: panelBg,
        border: panelBorder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decide columns responsively to avoid overflow
          final maxW = constraints.maxWidth;
          const spacing = 16.0;
          final columns = maxW >= 960 ? 4 : (maxW >= 600 ? 2 : 1);
          final itemWidth = (maxW - (columns - 1) * spacing) / columns;

          final gauges = <Widget>[
            Gauge(
              label: 'Progress',
              value: progress * 100.0,   // show 0..100
              max: 100,
              accent: accent,
              size: gaugeSize,
              iconSize: iconSize,
              footer: '$typed / $total',
            ),
            Gauge(
              label: 'Accuracy',
              value: accuracy * 100.0,   // show 0..100
              max: 100,
              accent: accent,
              size: gaugeSize,
              iconSize: iconSize,
              footer: '$correct / $typed',
            ),
            Gauge(
              label: 'Words/min.',
              value: wpm,
              max: 80,                   // tune if needed
              accent: accent,
              size: gaugeSize,
              iconSize: iconSize,
              footer: wpm.isFinite ? wpm.toStringAsFixed(1) : '0.0',
            ),
            Gauge(
              label: 'Chars/min.',
              value: cpm,
              max: 400,                  // tune if needed
              accent: accent,
              size: gaugeSize,
              iconSize: iconSize,
              footer: cpm.isFinite ? cpm.toStringAsFixed(0) : '0',
            ),
          ];

          // Always use Wrap so it reflows on zoom/smaller widths
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: gauges
                .map((g) => SizedBox(width: itemWidth, child: g))
                .toList(),
          );
        },
      ),
    );
  }


}
