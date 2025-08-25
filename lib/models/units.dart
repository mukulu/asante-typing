/// Data models for units and subunits.
class Lesson {
  Lesson({
    required this.title,
    required this.guide,
    required this.subunits,
  });
  final String title;
  final String guide;
  final Map<String, String> subunits;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final raw = json['subunits'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final subs = <String, String>{ for (final e in raw.entries) e.key: e.value.toString() };
    return Lesson(
      title: json['title']?.toString() ?? 'Untitled',
      guide: json['guide']?.toString() ?? '',
      subunits: subs,
    );
  }
}

class UnitsData {
  UnitsData({required this.main, this.alt});
  final List<Lesson> main;
  final List<Lesson>? alt;

  static UnitsData fromJson(Map<String, dynamic> json) {
    final mains = (json['main'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
    final alts = (json['alt'] as List<dynamic>?)?.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
    return UnitsData(main: mains, alt: alts);
  }
}
