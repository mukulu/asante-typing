import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:asante_typing/models/units.dart';
import 'package:asante_typing/utils/typing_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Colour palette used across the tutor.
const kColorYellow = Color(0xFFF4B233);
const kColorGreen = Color(0xFF1F5F45);
const kColorRed = Color(0xFF7A1717);

/// A unified two‑pane layout for the typing tutor.
///
/// The left pane lists all available units.  Selecting a unit updates the
/// right pane, which either shows the unit guide or the practice interface
/// depending on the chosen subunit.  Real‑time statistics (length, typed
/// characters, errors, WPM, CPM and elapsed time) are displayed during
/// practice.
class TutorPage extends StatefulWidget {
  const TutorPage({super.key});

  @override
  State<TutorPage> createState() => _TutorPageState();
}


class _TutorPageState extends State<TutorPage> {
  UnitsData? _data;
  int _selectedUnit = 0;
  String? _selectedSubunit;
  // Remembers the last selected subunit for each unit so that revisiting a unit
  // restores the previously active lesson. The key is the unit index and the
  // value is the subunit key.
  final Map<int, String> _lastSubunitPerUnit = {};
  final TextEditingController _controller = TextEditingController();
  DateTime? _startTime;
  Timer? _ticker;
  int _errors = 0;
  bool _finished = false;

  // Session summary metrics. When a session (i.e. a subunit practice) is
  // completed, these values are populated and `_sessionCompleted` is set to
  // true.  They are cleared whenever a new lesson or subunit is selected.
  bool _sessionCompleted = false;
  Duration _sessionDuration = Duration.zero;
  int _sessionTyped = 0;
  int _sessionErrorsFinal = 0;
  double _sessionWpm = 0;
  double _sessionCpm = 0;
  double _sessionAccuracy = 0;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller..removeListener(_onChanged)
    ..dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    final raw = await rootBundle.loadString('assets/units.json');
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final data = UnitsData.fromJson(jsonMap);
    // After loading, select the first unit and its first subunit by default.
    String? initialSub;
    if (data.main.isNotEmpty) {
      final firstLesson = data.main[_selectedUnit];
      if (firstLesson.subunits.isNotEmpty) {
        initialSub = firstLesson.subunits.keys.first;
        _lastSubunitPerUnit[_selectedUnit] = initialSub;
      }
    }
    setState(() {
      _data = data;
      _selectedSubunit = initialSub;
    });
  }

  void _onChanged() {
    if (_selectedSubunit == null) return;
    final typed = _controller.text;
    if (typed.isNotEmpty && _startTime == null) {
      _startTime = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
    }
    if (typed.length <= _currentText.length) {
      _errors = 0;
      for (var i = 0; i < typed.length; i++) {
        if (typed[i] != _currentText[i]) _errors++;
      }
    }
    if (typed.length >= _currentText.length && !_finished) {
      _finished = true;
      _ticker?.cancel();
      // Compute session metrics when practice completes.
      final elapsed = _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!);
      final correct = (_currentText.length - _errors).clamp(0, _currentText.length);
      final minutes = elapsed.inMilliseconds / 60000.0;
      final wpm = minutes > 0 ? (correct / 5.0) / minutes : 0.0;
      final cpm = minutes > 0 ? correct / minutes : 0.0;
      final accuracy = typed.isNotEmpty ? ((typed.length - _errors) / typed.length * 100).clamp(0, 100) : 0.0;
      setState(() {
        _sessionCompleted = true;
        _sessionDuration = elapsed;
        _sessionTyped = typed.length;
        _sessionErrorsFinal = _errors;
        _sessionWpm = wpm;
        _sessionCpm = cpm;
        _sessionAccuracy = accuracy;
      });
    }
    setState(() {});
  }

  Lesson get _currentLesson => _data!.main[_selectedUnit];
  String get _currentText => _selectedSubunit == null ? '' : (_currentLesson.subunits[_selectedSubunit] ?? '');


  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final selectedLesson = data.main[_selectedUnit];
    // Determine which image to display for the selected lesson. Prefer the
    // first entry in the lesson's `images` list, falling back to the
    // fingerAssetForUnit helper when none are defined. The stored image path
    // in the lesson is relative to the project root, e.g. `img/home.jpg`.
    String? diagramAsset;
    if (selectedLesson.images.isNotEmpty) {
      final imgPath = selectedLesson.images.first;
      diagramAsset = imgPath.startsWith('assets/') ? imgPath : 'assets/$imgPath';
    } else {
      diagramAsset = fingerAssetForUnit(_selectedUnit);
    }
    final elapsed = _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!);
    final typedLen = _controller.text.length;
    final correct = _selectedSubunit == null ? 0 : (_currentText.length - _errors).clamp(0, _currentText.length);
    final minutes = elapsed.inMilliseconds / 60000.0;
    final wpm = minutes > 0 ? (correct / 5.0) / minutes : 0;
    final cpm = minutes > 0 ? correct / minutes : 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(dynamicTitle),
        backgroundColor: kColorGreen,
        foregroundColor: kColorRed,
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Left navigation: units list
          Container(
            color: kColorYellow,
            width: MediaQuery.of(context).size.width * 0.25,
            child: ListView.separated(
              itemCount: data.main.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white),
              itemBuilder: (context, i) {
                final isSelected = i == _selectedUnit;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: kColorGreen.withValues(alpha: 0.15),
                  selectedColor: kColorRed,
                  textColor: kColorRed,
                  title: Text('Unit ${i + 1}: ${data.main[i].title}'),
                  onTap: () {
                    setState(() {
                      _selectedUnit = i;
                      // Restore last active subunit for this unit if available;
                      // otherwise default to the first subunit of the lesson.
                      final lesson = _data!.main[i];
                      var sub = _lastSubunitPerUnit[i];
                      if (sub == null || !lesson.subunits.containsKey(sub)) {
                        sub = lesson.subunits.keys.isNotEmpty ? lesson.subunits.keys.first : null;
                      }
                      _selectedSubunit = sub;
                      // update memory
                      if (sub != null) _lastSubunitPerUnit[i] = sub;
                      _controller.clear();
                      _startTime = null;
                      _ticker?.cancel();
                      _ticker = null;
                      _errors = 0;
                      _finished = false;
                      _sessionCompleted = false;
                    });
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Right pane: guide or practice
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subunit chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in selectedLesson.subunits.keys)
                        ChoiceChip(
                          label: Text(key),
                          selected: _selectedSubunit == key,
                          selectedColor: kColorGreen.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            if (!selected) return;
                            setState(() {
                              _selectedSubunit = key;
                              _lastSubunitPerUnit[_selectedUnit] = key;
                              _controller.clear();
                              _startTime = null;
                              _ticker?.cancel();
                              _ticker = null;
                              _errors = 0;
                              _finished = false;
                              _sessionCompleted = false;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Always display guide and image for clarity, regardless of practice mode.
                  if (diagramAsset != null) ...[
                    Center(
                      child: Image.asset(
                        diagramAsset,
                        height: _selectedSubunit == null ? 150 : 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _stripHtml(selectedLesson.guide),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kColorRed),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedSubunit == null) ...[
                    // Guide-only view: no practice fields.
                  ] else ...[
                    // Practice view
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildTargetText(_currentText, _controller.text),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Start typing here…',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Real-time metrics with simple visualizations
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress bar for typed vs total length
                        const Text('Progress', style: TextStyle(color: kColorRed)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _currentText.isNotEmpty ? (typedLen / _currentText.length).clamp(0.0, 1.0) : 0.0,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(kColorGreen),
                        ),
                        const SizedBox(height: 8),
                        // Gauges for WPM and CPM
                        Row(
                          children: [
                            _buildGauge('WPM', wpm, 60),
                            const SizedBox(width: 24),
                            _buildGauge('CPM', cpm, 300),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text('Length: ${_currentText.length}', style: const TextStyle(color: kColorRed)),
                            Text('Typed: $typedLen', style: const TextStyle(color: kColorRed)),
                            Text('Errors: $_errors', style: const TextStyle(color: kColorRed)),
                            Text('Time: ${formatDuration(elapsed)}', style: const TextStyle(color: kColorRed)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_sessionCompleted) ...[
                      Card(
                        color: kColorGreen.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Session Summary', style: TextStyle(fontWeight: FontWeight.bold, color: kColorRed)),
                              const SizedBox(height: 8),
                              // Final gauges
                              Row(
                                children: [
                                  _buildGauge('WPM', _sessionWpm, 60),
                                  const SizedBox(width: 24),
                                  _buildGauge('CPM', _sessionCpm, 300),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _currentText.isNotEmpty ? (_sessionTyped / _currentText.length).clamp(0.0, 1.0) : 0.0,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(kColorGreen),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Text('Length: ${_currentText.length}', style: const TextStyle(color: kColorRed)),
                                  Text('Typed: $_sessionTyped', style: const TextStyle(color: kColorRed)),
                                  Text('Errors: $_sessionErrorsFinal', style: const TextStyle(color: kColorRed)),
                                  Text('Accuracy: ${_sessionAccuracy.toStringAsFixed(1)}%', style: const TextStyle(color: kColorRed)),
                                  Text('Time: ${formatDuration(_sessionDuration)}', style: const TextStyle(color: kColorRed)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      )
  }

  /// Strips all HTML tags from the [html] string.
  String _stripHtml(String html) {
    return html.replaceAll(RegExp('<[^>]+>'), '');
  }

  /// Builds a coloured [RichText] representation of the target and typed strings.
  Widget _buildTargetText(String target, String typed) {
    final spans = <TextSpan>[];
    for (var i = 0; i < target.length; i++) {
      final ch = target[i];
      final inRange = i < typed.length;
      final correct = inRange && typed[i] == ch;
      final color = !inRange
          ? Colors.grey.shade700
          : (correct ? Colors.green : Colors.red);
      spans.add(TextSpan(text: ch, style: TextStyle(color: color)));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: spans,
      ),
    );
  }
}
