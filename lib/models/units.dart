/// Data models used by the typing tutor application.
///
/// The QuickQWERTY lessons are organised into units and subunits.  Each unit
/// introduces a small group of keys and comes with a guide explaining
/// ergonomics and fingering.  Within each unit there are several
/// subunits (Grip, Words, Control, Sentences and Test) that provide
/// progressively more challenging material.
class Lesson {
  /// Title of the unit, typically the keys introduced (e.g. "asdf jkl;").
  final String title;

  /// HTML formatted guide text that describes proper hand placement and
  /// technique for the unit.  The application renders this as rich text.
  final String guide;

  /// Map of subunit names to the practice content.  Each entry contains
  /// a single string that may include words, phrases and punctuation
  /// separated by semicolons.  The UI is responsible for splitting this
  /// string into lines for practice.
  final Map<String, String> subunits;

  Lesson({
    required this.title,
    required this.guide,
    required this.subunits,
  });

  /// Construct a lesson from a JSON map.  QuickQWERTY stores keys and
  /// values as dynamic types (objects) so we normalise them to strings here.
  factory Lesson.fromJson(Map<String, dynamic> json) {
    final Map<String, String> subs = {};
    final subunitsRaw = json['subunits'] as Map<String, dynamic>;
    subunitsRaw.forEach((key, value) {
      subs[key] = value as String;
    });
    return Lesson(
      title: json['title'] as String,
      guide: json['guide'] as String,
      subunits: subs,
    );
  }
}

/// Root model representing the collection of all units.  QuickQWERTY
/// differentiates between "main" units (6–7 split for number keys) and
/// optional alternate units (5–6 split).  The labels and prompts for the
/// splits are preserved for potential future use.
class UnitsData {
  final List<Lesson> main;
  final List<Lesson> alternate;
  final String? mainLabel;
  final String? alternateLabel;

  UnitsData({
    required this.main,
    required this.alternate,
    this.mainLabel,
    this.alternateLabel,
  });

  factory UnitsData.fromJson(Map<String, dynamic> json) {
    final main = (json['main'] as List<dynamic>)
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
    final alternate = (json['alternate'] ?? []) as List<dynamic>;
    final altLessons = alternate
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
    return UnitsData(
      main: main,
      alternate: altLessons,
      mainLabel: json['mainLabel'] as String?,
      alternateLabel: json['alternateLabel'] as String?,
    );
  }
}