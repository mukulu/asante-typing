import 'dart:async';
import 'dart:convert';

import 'package:asante_typing/models/units.dart';
import 'package:asante_typing/services/custom_lessons_service.dart';
import 'package:asante_typing/state/zoom_scope.dart';
import 'package:asante_typing/theme/app_colors.dart';
import 'package:asante_typing/utils/csv_two_col.dart';
import 'package:asante_typing/utils/pick_text.dart' as picktext;
import 'package:asante_typing/utils/typing_utils.dart';
import 'package:asante_typing/widgets/custom_lessons_panel.dart';
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

  /// Stores custom lessons loaded from persistence. Each entry contains a
  /// `title` and `content` string. This list is used to populate the
  /// subunits of the special "Custom lessons" unit appended to the end of
  /// [_data!.main].
  List<Map<String, String>> _customLessons = [];

  /// Index in [_data!.main] corresponding to the custom lessons unit, if
  /// present. Set in [_loadUnits] after loading lessons. If `null`, no
  /// custom unit has been appended yet.
  int? _customUnitIndex;

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
    // Load persisted custom lessons and append as a new unit.
    final lessons = await CustomLessonsService.loadLessons();
    _customLessons = List<Map<String, String>>.from(lessons);
    // Build subunits map for the custom unit. Preserve order.
    final customSubunits = <String, String>{};
    for (final lesson in _customLessons) {
      final title = lesson['title'] ?? '';
      final content = lesson['content'] ?? '';
      if (title.isNotEmpty) {
        customSubunits[title] = content;
      }
    }
    // Always append the "Custom lessons" unit (even if empty) so that users
    // can add lessons later. Use a simple guide that describes its purpose.
    final customLesson = Lesson(
      title: 'Custom lessons',
      guide:
          'Create your own passages for practice. Use the buttons below to add, edit, delete or bulk upload lessons.',
      subunits: customSubunits,
      images: const [],
    );
    data.main.add(customLesson);
    _customUnitIndex = data.main.length - 1;

    // Select first unit and its first subunit by default (unit 0). Avoid
    // selecting a subunit for the custom unit here; it will be set when
    // the user navigates to it.
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
                        // Subunit chips or custom lessons panel
                        if (selectedLesson.title == 'Custom lessons')
                          CustomLessonsPanel(
                            onResetAll: _confirmResetAll,
                            lessons: _customLessons,
                            selectedTitle: _selectedSubunit,
                            accent: accent,
                            onSelect: (title) {
                              setState(() {
                                _selectedSubunit = title;
                                if (_customUnitIndex != null) {
                                  _lastSubunitPerUnit[_customUnitIndex!] = title;
                                }
                                // Reset session state for new selection.
                                _controller.clear();
                                _startTime = null;
                                _ticker?.cancel();
                                _ticker = null;
                                _errors = 0;
                                _finished = false;
                                _sessionCompleted = false;
                              });
                            },
                            onAdd: () {
                              _showAddOrEditLesson(null);
                            },
                            onEdit: _showAddOrEditLesson,
                            onDelete: _confirmDeleteLesson,
                            onBulkUpload: _showBulkUploadDialog,
                          )
                        else
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
                          Builder(
                            builder: (context) {
                              final s = ZoomScope.of(context).scale;          // <- zoom value (1.0 = normal)
                              final base = _selectedSubunit == null ? 180.0 : 145.0; // <- bumped up a bit from 150/120
                              final imgHeight = base * s;                     // <- responsive height

                              return Center(
                                child: Image.asset(
                                  diagramAsset ?? '',
                                  height: imgHeight,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              );
                            },
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

  /// Saves the current [_customLessons] list to persistent storage.
  Future<void> _saveCustomLessons() async {
    await CustomLessonsService.saveLessons(_customLessons);
  }

  /// Rebuilds the custom lessons unit within [_data] based on the
  /// current [_customLessons] list. This method also ensures that the
  /// selected subunit for the custom unit remains valid (or is reset to
  /// the first available). Call this after adding, editing or deleting a
  /// custom lesson.
  void _updateCustomUnit() {
    if (_data == null || _customUnitIndex == null) return;
    final map = <String, String>{};
    for (final lesson in _customLessons) {
      final title = lesson['title'] ?? '';
      final content = lesson['content'] ?? '';
      if (title.isNotEmpty) {
        map[title] = content;
      }
    }
    // Replace the custom unit with updated subunits but keep the guide text.
    final oldLesson = _data!.main[_customUnitIndex!];
    _data!.main[_customUnitIndex!] = Lesson(
      title: oldLesson.title,
      guide: oldLesson.guide,
      subunits: map,
      images: const [],
    );
    // Adjust selected subunit when necessary.
    if (_selectedUnit == _customUnitIndex) {
      if (_selectedSubunit == null || !map.containsKey(_selectedSubunit)) {
        _selectedSubunit = map.isNotEmpty ? map.keys.first : null;
      }
      if (_customUnitIndex != null && _selectedSubunit != null) {
        _lastSubunitPerUnit[_customUnitIndex!] = _selectedSubunit!;
      }
    }
  }

  /// Opens a dialog allowing the user to add a new custom lesson or edit
  /// an existing one. When [index] is `null`, a new lesson is created;
  /// otherwise the lesson at [index] is modified. After saving, the
  /// lessons list is persisted and the UI is refreshed.
  void _showAddOrEditLesson(int? index) {
    final isEdit = index != null;
    final originalTitle = isEdit ? (_customLessons[index]['title'] ?? '') : '';
    final originalContent = isEdit ? (_customLessons[index]['content'] ?? '') : '';
    final titleController = TextEditingController(text: originalTitle);
    final contentController = TextEditingController(text: originalContent);

    bool hasUnsavedChanges() {
      return titleController.text.trim() != originalTitle.trim() ||
          contentController.text.trim() != originalContent.trim();
    }

    void maybeDiscard(VoidCallback onDiscard) {
      if (!hasUnsavedChanges()) {
        onDiscard();
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes. Do you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDiscard();
                },
                child: const Text('Discard'),
              ),
            ],
          );
        },
      );
    }

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            final size = MediaQuery.of(ctx).size;
            return AlertDialog(
              title: Text(isEdit ? 'Edit lesson' : 'Add lesson'),
              content: SizedBox(
                width: size.width * 0.80,
                height: size.height * 0.80,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: contentController,
                        decoration: const InputDecoration(labelText: 'Passage'),
                        minLines: 3,
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    maybeDiscard(() {
                      Navigator.of(dialogCtx).pop(false);
                    });
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final trimmedTitle = titleController.text.trim();
                    final trimmedContent = contentController.text;
                    if (trimmedTitle.isEmpty || trimmedContent.isEmpty) {
                      // Require non‑empty fields; keep editing.
                      return;
                    }
                    Navigator.of(dialogCtx).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((save) {
      if (save != true) return;
      final newLesson = <String, String>{
        'title': titleController.text.trim(),
        'content': contentController.text,
      };
      setState(() {
        if (isEdit) {
          _customLessons[index] = newLesson;
        } else {
          _customLessons.add(newLesson);
        }
        _updateCustomUnit();
        _saveCustomLessons();
        _selectedSubunit = newLesson['title'];
        if (_customUnitIndex != null && _selectedSubunit != null) {
          _lastSubunitPerUnit[_customUnitIndex!] = _selectedSubunit!;
        }
        // Reset typing session for the new selection.
        _controller.clear();
        _startTime = null;
        _ticker?.cancel();
        _ticker = null;
        _errors = 0;
        _finished = false;
        _sessionCompleted = false;
      });
    });
  }

  /// Prompts the user to confirm deletion of the custom lesson at [index].
  /// If confirmed, the lesson is removed, persisted and the UI is updated.
  void _confirmDeleteLesson(int index) {
    final lessonTitle = _customLessons[index]['title'] ?? '';
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete lesson'),
          content: Text('Are you sure you want to delete "$lessonTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ).then((confirm) {
      if (confirm != true) return;
      setState(() {
        final removed = _customLessons.removeAt(index);
        // Update selected subunit if the removed lesson was selected.
        if (_selectedSubunit == removed['title']) {
          _selectedSubunit = _customLessons.isNotEmpty ? _customLessons.first['title'] : null;
        }
        _updateCustomUnit();
        _saveCustomLessons();
        if (_customUnitIndex != null && _selectedSubunit != null) {
          _lastSubunitPerUnit[_customUnitIndex!] = _selectedSubunit!;
        }
        // Reset typing session for deletion.
        _controller.clear();
        _startTime = null;
        _ticker?.cancel();
        _ticker = null;
        _errors = 0;
        _finished = false;
        _sessionCompleted = false;
      });
    });
  }

  void _confirmResetAll() {
    if (_customLessons.isEmpty) return;
  
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete ALL custom lessons?'),
          content: Text(
            'This will permanently remove ${_customLessons.length} custom '
            'lesson(s) and leave the list empty. Are you sure?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    ).then((yes) {
      if (yes != true) return;
      setState(() {
        _customLessons.clear();
        _updateCustomUnit();
        _saveCustomLessons();
  
        _selectedSubunit = null;
        if (_customUnitIndex != null) {
          _lastSubunitPerUnit.remove(_customUnitIndex);
        }
  
        // reset typing session
        _controller.clear();
        _startTime = null;
        _ticker?.cancel();
        _ticker = null;
        _errors = 0;
        _finished = false;
        _sessionCompleted = false;
      });
    });
  }

  /// Shows a dialog allowing the user to paste or upload multiple passages
  /// separated by newlines. Each line will become a new lesson. Default
  /// titles will be generated as "Paragraph 01", "Paragraph 02", etc.
  void _showBulkUploadDialog() {
    final textController = TextEditingController();
    List<MapEntry<String, String>>? csvRows; // null => not a valid 2-col CSV

    showDialog<List<Map<String, String>>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;

        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            // Local helper so we can re-parse on text change or file load
            void reparse() {
              csvRows = TwoColCsv.tryParse(textController.text);
              setStateDialog(() {}); // refresh banner
            }

            Future<void> pickFile() async {
              final result = await picktext.pickTextFile();
              if (result != null) {
                textController.text = result; // programmatic update
                reparse();                    // ensure detection runs
              }
            }

            return AlertDialog(
              // NEW: occupy ~80% of the viewport
              insetPadding: EdgeInsets.symmetric(
                horizontal: size.width * 0.10,
                vertical: size.height * 0.10,
              ),
              title: const Text('Bulk upload lessons'),
              content: SizedBox(
                width: size.width * 0.80,
                height: size.height * 0.80,
                child: Column(
                  children: [
                    // Banner: green when CSV detected, amber tip otherwise
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (csvRows != null)
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.amber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (csvRows != null)
                              ? Colors.green.withValues(alpha: 0.40)
                              : Colors.amber.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        (csvRows != null)
                            ? 'Detected a two-column CSV: "Title","Passage". Each row will be imported as a lesson with its title.'
                            : 'Tip: Paste or upload text. You can also use a two-column CSV for "Title","Passage". Each line becomes its own lesson. Avoid newlines inside cells.',
                        style: TextStyle(
                          color: (csvRows != null) ? Colors.green : Colors.black87,
                          fontWeight: (csvRows != null) ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),

                    // Big editor that grows with dialog
                    Expanded(
                      child: TextField(
                        controller: textController,
                        onChanged: (_) => reparse(),  // detect CSV on paste/type
                        decoration: const InputDecoration(
                          labelText: 'TIP: Paste or upload your lessons text here. You can also upload a CSV with two columns for "Title","Passage". No need for headers. Note: Each new line becomes a new lesson in the file, thus avoid newlines within paragraphs.',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        expands: true,
                        maxLines: null,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose file'),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Upload a .txt or a two-column CSV. Each row becomes a lesson.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final raw = textController.text.trim();
                    if (raw.isEmpty) return;

                    // If CSV detected, build lessons from CSV rows
                    final parsed = csvRows ?? TwoColCsv.tryParse(raw);
                    if (parsed != null && parsed.isNotEmpty) {
                      // Optional header skip: Title,Passage
                      final rows = List<MapEntry<String, String>>.from(parsed);
                      if (rows.first.key.toLowerCase() == 'title' &&
                          rows.first.value.toLowerCase() == 'passage') {
                        rows.removeAt(0);
                      }

                      final items = <Map<String, String>>[
                        for (final r in rows)
                          {
                            'title': (r.key.trim().isEmpty) ? 'Untitled' : r.key.trim(),
                            'content': r.value,
                          }
                      ];
                      Navigator.of(dialogCtx).pop(items);
                      return;
                    }

                    // Fallback: one line => one lesson (keep your old behavior)
                    final lines = raw
                        .split(RegExp(r'[\r\n]+'))
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    var indexStart = _customLessons.length + 1;
                    final items = <Map<String, String>>[];
                    for (final line in lines) {
                      final label = 'Paragraph ${indexStart.toString().padLeft(2, '0')}';
                      items.add({'title': label, 'content': line});
                      indexStart++;
                    }
                    if (items.isEmpty) return;
                    Navigator.of(dialogCtx).pop(items);
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      // result is List<Map<String,String>>? (null => cancelled)
      if (result == null || result.isEmpty) return;

      setState(() {
        _customLessons.addAll(result);
        _updateCustomUnit();
        _saveCustomLessons();

        // Select first of the new ones if nothing selected
        _selectedSubunit ??= result.first['title'];
        if (_customUnitIndex != null && _selectedSubunit != null) {
          _lastSubunitPerUnit[_customUnitIndex!] = _selectedSubunit!;
        }

        // Reset typing session
        _controller.clear();
        _startTime = null;
        _ticker?.cancel();
        _ticker = null;
        _errors = 0;
        _finished = false;
        _sessionCompleted = false;
      });
    });
  }


}
