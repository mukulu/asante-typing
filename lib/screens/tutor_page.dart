import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/units.dart';

/// A unified tutor page that presents the entire typing tutor within a
/// single screen.  The page is divided into a left navigation pane
/// listing all units and a main pane that shows either the guide or
/// the practice interface.  Selecting a unit or a subunit updates
/// the state rather than navigating to a new route.  This design
/// avoids back‑and‑forth transitions between screens and keeps the
/// layout consistent at all times.
class TutorPage extends StatefulWidget {
  const TutorPage({super.key});

  @override
  State<TutorPage> createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPage> {
  UnitsData? _unitsData;
  int _selectedUnit = 0;
  String? _selectedSubunit;
  String _lessonText = '';
  final TextEditingController _controller = TextEditingController();
  DateTime? _startTime;
  int _errors = 0;
  bool _finished = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _controller.addListener(_onInputChanged);
  }

  Future<void> _loadUnits() async {
    final jsonString = await rootBundle.loadString('assets/units.json');
    final map = json.decode(jsonString) as Map<String, dynamic>;
    setState(() {
      _unitsData = UnitsData.fromJson(map);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _selectUnit(int index) {
    if (index == _selectedUnit) return;
    setState(() {
      _selectedUnit = index;
      _selectedSubunit = null;
      _resetTypingState();
    });
  }

  void _selectSubunit(String name) {
    if (name == _selectedSubunit) return;
    setState(() {
      _selectedSubunit = name;
      _resetTypingState();
      // Concatenate the semicolon‑separated phrases into one string.
      final lesson = _unitsData!.main[_selectedUnit];
      final raw = lesson.subunits[name] ?? '';
      final parts = raw
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _lessonText = parts.join(' ');
    });
  }

  void _resetTypingState() {
    _controller.text = '';
    _startTime = null;
    _errors = 0;
    _finished = false;
    _lessonText = '';
    _ticker?.cancel();
  }

  void _onInputChanged() {
    if (_unitsData == null || _selectedSubunit == null) return;
    final typed = _controller.text;
    if (_finished) return;
    // Start timer on first keystroke.
    if (typed.isNotEmpty && _startTime == null) {
      _startTime = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_finished) setState(() {});
      });
    }
    // Count mismatches.
    int mismatches = 0;
    for (int i = 0; i < typed.length; i++) {
      if (i >= _lessonText.length) {
        mismatches += typed.length - _lessonText.length;
        break;
      }
      if (typed[i] != _lessonText[i]) mismatches++;
    }
    setState(() {
      _errors = mismatches;
    });
    // Completion check.
    if (typed.length >= _lessonText.length && !_finished) {
      _finished = true;
      _ticker?.cancel();
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final typedLength = _controller.text.length;
    final correctChars = (_lessonText.length - _errors).clamp(0, _lessonText.length);
    final elapsed = _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!);
    final minutes = elapsed.inSeconds / 60.0;
    final wpm = minutes > 0 ? (correctChars / 5.0) / minutes : 0.0;
    final cpm = minutes > 0 ? (typedLength / minutes) : 0.0;
    final accuracy = _lessonText.isNotEmpty ? (correctChars / _lessonText.length) * 100.0 : 0.0;
    final elapsedStr = _formatDuration(elapsed);
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final total = d.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Determine which finger position diagram to show for the given unit.
  String? _fingerDiagramForUnit(int unitIndex) {
    // Mapping based on the QuickQWERTY rebranding commit.  Units beyond
    // six reuse the allfingers image as a fallback.
    const images = [
      'home-keys-position.svg.png',
      'forefingers.svg.png',
      'middlefingers.svg.png',
      'ringfingers.svg.png',
      'littlefingers.svg.png',
      'allfingers.svg.png',
    ];
    final idx = unitIndex.clamp(0, images.length - 1);
    final name = images[idx];
    return 'https://raw.githubusercontent.com/susam/quickqwerty/4f8a121baa0c1ef4df0c867993f684749f8c630e/img/$name';
  }

  @override
  Widget build(BuildContext context) {
    if (_unitsData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final lessons = _unitsData!.main;
    final lesson = lessons[_selectedUnit];
    final subunitNames = lesson.subunits.keys.toList();
    // Compute metrics for real‑time display.
    final typedLength = _controller.text.length;
    final elapsed = _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!);
    final minutes = elapsed.inSeconds / 60.0;
    final wpm = minutes > 0 ? ((_lessonText.length - _errors).clamp(0, _lessonText.length) / 5.0) / minutes : 0.0;
    final cpm = minutes > 0 ? (typedLength / minutes) : 0.0;
    final elapsedStr = _formatDuration(elapsed);
    final fingerUrl = _fingerDiagramForUnit(_selectedUnit);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asante Typing'),
      ),
      body: Row(
        children: [
          // Left navigation pane listing units.
          Container(
            width: 250,
            color: Colors.grey.shade200,
            child: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final selected = index == _selectedUnit;
                return ListTile(
                  title: Text('Unit ${index + 1}: ${lessons[index].title}'),
                  selected: selected,
                  onTap: () => _selectUnit(index),
                );
              },
            ),
          ),
          // Main pane.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subunit tabs.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: subunitNames.map((name) {
                        final selected = name == _selectedSubunit;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (_) => _selectSubunit(name),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  // Show guide when no subunit selected.
                  if (_selectedSubunit == null) ...[
                    // Finger diagram.
                    if (fingerUrl != null)
                      Image.network(
                        fingerUrl,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    const SizedBox(height: 8.0),
                    // Plain guide text.
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          lesson.guide
                              .replaceAll(RegExp('<p>'), '\n\n')
                              .replaceAll(RegExp('<[^>]+>'), '')
                              .trim(),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Practice interface.
                    if (fingerUrl != null)
                      Image.network(
                        fingerUrl,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    const SizedBox(height: 8.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildTargetText(),
                      ),
                    ),
                    const SizedBox(height: 8.0),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the coloured target text for the practice area.  Typed
  /// characters are coloured green if correct and red if incorrect.
  Widget _buildTargetText() {
    final typed = _controller.text;
    final List<TextSpan> spans = [];
    for (int i = 0; i < typed.length && i < _lessonText.length; i++) {
      final correct = typed[i] == _lessonText[i];
      spans.add(TextSpan(
        text: _lessonText[i],
        style: TextStyle(
          color: correct ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ));
    }
    if (typed.length > _lessonText.length) {
      final extra = typed.substring(_lessonText.length);
      spans.add(TextSpan(
        text: extra,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
    }
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
}