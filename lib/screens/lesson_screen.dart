import 'package:flutter/material.dart';
import 'dart:async';

import '../models/units.dart';

/// Screen that presents an interactive typing exercise.  It displays the
/// target text, tracks the user's input in real time, highlights correct
/// and incorrect characters, measures typing speed and accuracy, and
/// reports results upon completion.  The user can access the unit
/// guide via the information icon in the app bar.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final String subunitKey;
  final int unitNumber;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.subunitKey,
    required this.unitNumber,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final String _lessonText;
  final TextEditingController _controller = TextEditingController();
  DateTime? _startTime;
  int _errors = 0;
  bool _finished = false;

  // Periodic timer used to refresh the UI each second once typing
  // begins.  Without this the elapsed time and computed speeds
  // remain static between keystrokes.  It is cancelled when the
  // lesson finishes or when the widget is disposed.
  Timer? _ticker;

  /// Map unit numbers to instructional finger position diagrams.  These
  /// images are hosted on GitHub and originate from the QuickQWERTY
  /// rebranding commit.  They illustrate which fingers should be used
  /// for each group of keys.  If a unit number is not present in this
  /// map, no image is shown for that lesson.
  static const Map<int, String> _fingerImages = {
    1:
        'https://raw.githubusercontent.com/susam/quickqwerty/4f8a121baa0c1ef4df0c867993f684749f8c630e/img/home-keys-position.svg.png',
    2:
        'https://raw.githubusercontent.com/susam/quickqwerty/4f8a121baa0c1ef4df0c867993f684749f8c630e/img/forefingers.svg.png',
    3:
        'https://raw.githubusercontent.com/susam/quickqwerty/4f8a121baa0c1ef4df0c867993f684749f8c630e/img/middlefingers.svg.png',
    4:
        'https://raw.githubusercontent.com/susam/quickqwerty/4f8a121baa0c1ef4df0c867993f684749f8c630e/img/ringfingers.svg.png',
    5:
        'https://raw.githubusercontent.com/susam/quickqwerty/4f8a121baa0c1ef4df0c867993f684749f8c630e/img/littlefingers.svg.png',
    6:
        'https://raw.githubusercontent.com/susam/quickqwerty/4f8a121baa0c1ef4df0c867993f684749f8c630e/img/allfingers.svg.png',
  };

  @override
  void initState() {
    super.initState();
    // Concatenate all sentences separated by semicolons into a single string.
    final raw = widget.lesson.subunits[widget.subunitKey] ?? '';
    final parts = raw
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _lessonText = parts.join(' ');
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    // Cancel the periodic ticker if it is still running.
    _ticker?.cancel();
    super.dispose();
  }

  /// Callback invoked whenever the text in the input field changes.
  void _onChanged() {
    final typed = _controller.text;
    if (_finished) return;
    // Start timing when the first character is entered.  Also start a
    // periodic timer that calls setState() every second to refresh
    // time‑dependent metrics such as elapsed time, WPM and CPM.  The
    // timer is started only once.
    if (typed.isNotEmpty && _startTime == null) {
      _startTime = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_finished) {
          setState(() {
            // Trigger rebuild; the actual metrics are computed in
            // the build method.  No state variables updated here.
          });
        }
      });
    }
    // Count mismatches.  Extra characters typed beyond the target
    // contribute to the error count.
    int mismatches = 0;
    for (int i = 0; i < typed.length; i++) {
      if (i >= _lessonText.length) {
        mismatches += typed.length - _lessonText.length;
        break;
      }
      if (typed[i] != _lessonText[i]) {
        mismatches++;
      }
    }
    setState(() {
      _errors = mismatches;
    });
    // Check for completion.
    if (typed.length >= _lessonText.length) {
      _finished = true;
      // Cancel ticker when finished to stop updating the UI.
      _ticker?.cancel();
      _showResults();
    }
  }

  /// Display the guide associated with this unit in a modal dialog.  The
  /// HTML tags present in the guide are stripped for a plain text
  /// presentation.  If required, a more sophisticated renderer could be
  /// plugged in here.
  void _showGuide() {
    final plainGuide = widget.lesson.guide
        .replaceAll(RegExp('<p>'), '\n\n')
        .replaceAll(RegExp('<[^>]+>'), '')
        .trim();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Guide'),
          content: SingleChildScrollView(
            child: Text(plainGuide),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Compute and display performance statistics once the user finishes
  /// typing the full exercise.  The speed is computed as words per
  /// minute using the standard definition: one word equals five
  /// characters.  Accuracy is computed as the ratio of correct
  /// characters to total characters in the target text.
  void _showResults() {
    final typedLength = _controller.text.length;
    // Clamp correct character count to a non‑negative value in case
    // errors exceed the target text length.
    final correctChars = (_lessonText.length - _errors).clamp(0, _lessonText.length);
    final Duration elapsed = _startTime == null
        ? Duration.zero
        : DateTime.now().difference(_startTime!);
    final double minutes = elapsed.inSeconds / 60.0;
    final double wpm = minutes > 0 ? (correctChars / 5.0) / minutes : 0.0;
    final double cpm = minutes > 0 ? (typedLength / minutes) : 0.0;
    final double accuracy = _lessonText.isNotEmpty
        ? (correctChars / _lessonText.length) * 100.0
        : 0.0;
    final String elapsedStr = _formatDuration(elapsed);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lesson Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Length: ${_lessonText.length}'),
              Text('Typed: $typedLength'),
              Text('Errors: $_errors'),
              Text('WPM: ${wpm.toStringAsFixed(2)}'),
              Text('CPM: ${cpm.toStringAsFixed(2)}'),
              Text('Accuracy: ${accuracy.toStringAsFixed(1)}%'),
              Text('Time: $elapsedStr'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop() // close dialog
                  ..pop(); // return to subunit list
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Format a [Duration] into a human‑readable mm:ss string.  Single
  /// digit values are zero‑padded to maintain a consistent width.
  String _formatDuration(Duration d) {
    final int totalSeconds = d.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Build a rich text widget that highlights correct and incorrect
  /// characters.  Typed characters are coloured green if correct and
  /// red if incorrect.  Untyped characters are rendered in a muted
  /// colour.  The entire target text is displayed to allow the user
  /// to see upcoming characters.
  Widget _buildTargetText() {
    final typed = _controller.text;
    final List<TextSpan> spans = [];
    // Highlight each character in the typed portion.
    for (int i = 0; i < typed.length && i < _lessonText.length; i++) {
      final bool correct = typed[i] == _lessonText[i];
      spans.add(TextSpan(
        text: _lessonText[i],
        style: TextStyle(
          color: correct ? Colors.green : Colors.red,
          fontWeight: correct ? FontWeight.bold : FontWeight.bold,
        ),
      ));
    }
    // If there are extra characters typed beyond the lesson text, show
    // them as errors too.
    if (typed.length > _lessonText.length) {
      final extra = typed.substring(_lessonText.length);
      spans.add(TextSpan(
        text: extra,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
    }
    // Append the untyped part of the lesson.
    if (typed.length < _lessonText.length) {
      spans.add(TextSpan(
        text: _lessonText.substring(typed.length),
        style: TextStyle(color: Colors.grey.shade600),
      ));
    }
    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 20.0, fontFamily: 'monospace'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compute derived metrics for the progress indicator.  These values
    // update each time the state changes or when the periodic ticker
    // triggers a rebuild.
    final int typedLength = _controller.text.length;
    final Duration elapsed = _startTime == null
        ? Duration.zero
        : DateTime.now().difference(_startTime!);
    final double minutes = elapsed.inSeconds / 60.0;
    final double wpm = minutes > 0
        ? ((_lessonText.length - _errors).clamp(0, _lessonText.length) / 5.0) /
            minutes
        : 0.0;
    final double cpm = minutes > 0 ? (typedLength / minutes) : 0.0;
    final String elapsedStr = _formatDuration(elapsed);
    final String? fingerUrl = _fingerImages[widget.unitNumber];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Unit ${widget.unitNumber}: ${widget.lesson.title} — ${widget.subunitKey}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGuide,
            tooltip: 'Show guide',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show a diagram illustrating which fingers to use for
            // this unit's keys.  If no diagram is defined, nothing
            // appears here.
            if (fingerUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.network(
                  fingerUrl,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            // Display the target text with highlighting.
            Expanded(
              child: SingleChildScrollView(
                child: _buildTargetText(),
              ),
            ),
            const SizedBox(height: 16.0),
            // Input field for the user.  We use an OutlineInputBorder to
            // differentiate the typing area.  The text field grows
            // vertically as the user types multiple lines.
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Start typing here...',
              ),
            ),
            const SizedBox(height: 8.0),
            // Real‑time feedback on progress and performance.  A Wrap
            // widget ensures that long rows wrap gracefully on narrow
            // screens.
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                Text('Length: ${_lessonText.length}'),
                Text('Typed: $typedLength'),
                Text('Errors: $_errors'),
                Text('WPM: ${wpm.toStringAsFixed(1)}'),
                Text('CPM: ${cpm.toStringAsFixed(1)}'),
                Text('Time: $elapsedStr'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}