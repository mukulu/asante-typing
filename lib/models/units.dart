/// Data models representing lessons and units in the typing tutor.

class Lesson {
  /// Constructs a lesson with a title, guide, and a map of subunit texts.
  Lesson({
    required this.title,
    required this.guide,
    required this.subunits,
  });

  /// Human‑readable lesson title (e.g. "asdf jkl;").
  final String title;

  /// HTML guide text that introduces the lesson and may include images.
  final String guide;

  /// Mapping from subunit name (e.g. "Grip") to the text to practise.
  final Map<String, String> subunits;

  /// Factory constructor to build a Lesson from a JSON map.
  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subunits'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final subs = <String, String>{};
    for (final entry in rawSubs.entries) {
      subs[entry.key] = entry.value.toString();
    }
    return Lesson(
      title: json['title']?.toString() ?? 'Untitled',
      guide: json['guide']?.toString() ?? '',
      subunits: subs,
    );
  }
}

/// Container for the unit data loaded from JSON.
class UnitsData {
  UnitsData({required this.main, this.alt});

  /// The primary list of lessons (units 1–28).
  final List<Lesson> main;

  /// Optional alternate lessons (e.g. number split style). May be null.
  final List<Lesson>? alt;

  /// Creates a UnitsData instance from a JSON map.
  factory UnitsData.fromJson(Map<String, dynamic> json) {
    final mains = (json['main'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
    final alts = (json['alt'] as List<dynamic>?)?.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
    return UnitsData(main: mains, alt: alts);
  }
}