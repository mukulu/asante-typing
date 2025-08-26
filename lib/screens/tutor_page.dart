import 'dart:async';
import 'dart:convert';

import 'package:asante_typing/models/units.dart';
import 'package:asante_typing/state/zoom_scope.dart';
import 'package:asante_typing/theme/app_colors.dart';
import 'package:asante_typing/utils/typing_utils.dart';
import 'package:asante_typing/widgets/footer.dart';
import 'package:asante_typing/widgets/left_nav.dart';
import 'package:asante_typing/widgets/metrics_panel.dart';
import 'package:asante_typing/widgets/subunit_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The main page of the typing tutor. Displays a left navigation pane of
/// units and a content area for guides and practice.
class TutorPage extends StatefulWidget {
  const TutorPage({super.key});

  @override
  State<TutorPage> createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPage> {

  UnitsData? _data;
  int _selectedUnit = 0;
  String? _selectedSubunit;

  /// Remembers the last selected subunit for each unit so that revisiting
  /// a unit restores the previously active lesson.
  final Map<int, String> _lastSubunitPerUnit = {};

  final TextEditingController _controller = TextEditingController();
  DateTime? _startTime;
  Timer? _ticker;
  int _errors = 0;
  bool _finished = false;

  // Session summary metrics populated when a practice session completes.
  bool _sessionCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    final raw = await rootBundle.loadString('assets/units.json');
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final data = UnitsData.fromJson(jsonMap);
    // Select first unit and its first subunit by default.
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

  /// Handles changes in the typing controller to update metrics and detect
  /// when the user has finished typing the current subunit.
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
    // Recalculate errors when editing within range.
    if (typed.length <= _currentText.length) {
      _errors = 0;
      for (var i = 0; i < typed.length; i++) {
        if (typed[i] != _currentText[i]) _errors++;
      }
    }
    // End of session detection.
    if (typed.length >= _currentText.length && !_finished) {
      _finished = true;
      _ticker?.cancel();
      // Compute session metrics.
      (_currentText.length - _errors).clamp(0, _currentText.length);
      setState(() {
        _sessionCompleted = true;
      });
    }
    setState(() {});
  }

  /// Returns the currently selected lesson.
  Lesson get _currentLesson => _data!.main[_selectedUnit];

  /// Returns the text for the current subunit, or an empty string when no
  /// subunit is selected.
  String get _currentText =>
      _selectedSubunit == null ? '' : (_currentLesson.subunits[_selectedSubunit] ?? '');

  /// Generates the dynamic title for the app bar.
  String get _dynamicTitle {
    if (_data == null) return 'Asante Typing';
    final unitNo = _selectedUnit + 1;
    final title = _currentLesson.title;
    final sub = _selectedSubunit;
    return sub == null ? 'Unit $unitNo: $title' : 'Unit $unitNo: $title – $sub';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine which image to display for the current lesson.
    final selectedLesson = data.main[_selectedUnit];
    // Accent for this unit stage
    final accent = UnitColors.accent(_selectedUnit);

    String? diagramAsset;
    if (selectedLesson.images.isNotEmpty) {
      final imgPath = selectedLesson.images.first;
      diagramAsset = imgPath.startsWith('assets/') ? imgPath : 'assets/$imgPath';
    } else {
      diagramAsset = fingerAssetForUnit(_selectedUnit);
    }

    final elapsed = _startTime == null
        ? Duration.zero
        : DateTime.now().difference(_startTime!);
    final typedLen = _controller.text.length;
    final correct = _selectedSubunit == null
        ? 0
        : (_currentText.length - _errors).clamp(0, _currentText.length);
    final minutes = elapsed.inMilliseconds / 60000.0;
    final wpm = minutes > 0 ? (correct / 5.0) / minutes : 0.0;
    final cpm = minutes > 0 ? correct / minutes : 0.0;

    final zoomScale = ZoomScope.of(context).scale; // 1.0 = normal, >1 = zoomed in

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              // Left brand
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Builder(
                    builder: (context) {
                      // Current zoom scale (1.0 = normal). This is already wired up in your app.
                      final s = ZoomScope.of(context).scale;

                      // Keep the brand text base size at 18; it will be multiplied by the
                      // global text scaler automatically. We size the logo to match.
                      const kBrandBaseFont = 18.0;

                      // Make the logo roughly the same visual height as the text (slightly larger).
                      final logoSide = (kBrandBaseFont * s) * 2.0;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo scales with zoom
                          Image.asset(
                            'assets/img/aorlogo.jpg',
                            height: logoSide,
                            width: logoSide,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                          const SizedBox(width: 8),
                          // Brand text: its size already scales via your global text scaler
                          const Text(
                            'Asante Typing',
                            style: TextStyle(
                              color: kColorYellow,
                              fontWeight: FontWeight.w700,
                              fontSize: kBrandBaseFont,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Center dynamic lesson title
              Align(
                child: Text(
                  _dynamicTitle,                          // the computed title
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kColorYellow,                  // the yellow text (top)
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ⬇️ scale the action icons with the zoom value
        actionsIconTheme: IconThemeData(size: 24.0 * zoomScale),
        // (optional) also scale the leading/back icon if you ever use one
        iconTheme: IconThemeData(size: 24.0 * zoomScale),
        actions: [
          IconButton(
            tooltip: 'Zoom out (Ctrl+-)',
            icon: const Icon(Icons.zoom_out, color: kColorYellow),
            onPressed: () => ZoomScope.of(context).zoomOut(),
          ),
          IconButton(
            tooltip: 'Zoom in (Ctrl+=)',
            icon: const Icon(Icons.zoom_in, color: kColorYellow),
            onPressed: () => ZoomScope.of(context).zoomIn(),
          ),
          //Optional: reset via long-press or a third button:
          IconButton(
            tooltip: 'Reset zoom (Ctrl+0)',
            icon: const Icon(Icons.refresh, color: kColorYellow),
            onPressed: () => ZoomScope.of(context).reset(),
          ),
      ],
        backgroundColor: kColorGreen,
        foregroundColor: kColorYellow,
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Left navigation panel
          LeftNav(
            lessons: data.main,
            selectedIndex: _selectedUnit,
            accent: accent,
            onSelect: (index) {
              setState(() {
                _selectedUnit = index;
                // Restore last subunit or default.
                final lesson = _data!.main[index];
                var sub = _lastSubunitPerUnit[index];
                if (sub == null || !lesson.subunits.containsKey(sub)) {
                  sub = lesson.subunits.keys.isNotEmpty
                      ? lesson.subunits.keys.first
                      : null;
                }
                _selectedSubunit = sub;
                if (sub != null) _lastSubunitPerUnit[index] = sub;
                // Reset session state.
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
          const VerticalDivider(width: 1),
          // Right content area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subunit chips
                        IconTheme.merge(
                          data: IconThemeData(size: 18.0 * zoomScale),
                          child: SubunitChips(
                            keys: selectedLesson.subunits.keys,
                            selectedKey: _selectedSubunit,
                            accent: accent,
                            unitIndex: _selectedUnit,
                            onSelect: (key) {
                              setState(() {
                                _selectedSubunit = key;
                                _lastSubunitPerUnit[_selectedUnit] = key;
                                // Reset session state.
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
                        ),
                        const SizedBox(height: 12),
                        // Guide image
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
                        // Guide text
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: kColorYellow.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _stripHtml(selectedLesson.guide),
                            textAlign: TextAlign.left,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedSubunit == null) ...[
                          // Guide-only view: no practice fields.
                        ] else ...[                      
                          // Real-time metrics panel FIRST (so it’s not pushed by growing input)
                          MetricsPanel(
                            currentLength: _currentText.length,
                            typedLength: typedLen,
                            errors: _errors,
                            elapsed: elapsed,
                            wpm: wpm,
                            cpm: cpm,
                            accent: accent,
                            isComplete: _sessionCompleted,
                            total: _currentText.length,
                            typed: typedLen,
                          ),
                          const SizedBox(height: 16),

                          // Target text (the text you read)
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: accent),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildTargetText(_currentText, _controller.text),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Typing input
                          TextField(
                            controller: _controller,
                            autofocus: true,
                            maxLines: null,
                            style: const TextStyle(fontSize: 20), // keep base font 20
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Start typing here…',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  /// Strips all HTML tags from the [html] string.
  String _stripHtml(String html) {
    return html.replaceAll(RegExp('<[^>]+>'), '');
  }

  /// Builds a coloured [Text.rich] representation of the target and typed strings.
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
    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 20, color: Colors.black),
    );
  }

}
