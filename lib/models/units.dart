// Data models representing lessons and units in the typing tutor.

/// Represents a single lesson (unit) with a title, guide text and subunits.
class Lesson {

  /// Constructs a [Lesson] instance.
  Lesson({
    required this.title,
    required this.guide,
    required this.subunits,
    required this.images,
  });

  /// Creates a [Lesson] from a JSON map.
  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subunits'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final subs = <String, String>{};
    for (final entry in rawSubs.entries) {
      subs[entry.key] = entry.value.toString();
    }
    // Parse image list. Accepts both `Img` (preferred) and `img` keys.
    final imgs = <String>[];
    final dynamic rawImgs = json['Img'] ?? json['img'];
    if (rawImgs is List) {
      for (final item in rawImgs) {
        final str = item.toString();
        if (str.isNotEmpty) imgs.add(str);
      }
    }
    return Lesson(
      title: json['title']?.toString() ?? 'Untitled',
      guide: json['guide']?.toString() ?? '',
      subunits: subs,
      images: imgs,
    );
  }
  /// Human‑readable lesson title (for example, `asdf jkl;`).
  final String title;

  /// HTML guide text introducing the lesson. May contain image tags.
  final String guide;

  /// List of image file names (relative to `assets/img/`) associated with this lesson.
  /// If multiple images are provided, the first entry is used by default.
  final List<String> images;

  /// Mapping from subunit name (e.g. `Grip`, `Words`) to practice strings.
  final Map<String, String> subunits;

  @override
  String toString() => r'Lesson(title: $title, subunits: ${subunits.length}, images: ${images.length})';
}
/// Container for the collection of units. Contains the primary [main] list and
/// an optional [alt] list for alternate layouts or number‑key lessons.
class UnitsData {

  /// Constructs a [UnitsData] instance.
  UnitsData({required this.main, this.alt});

  /// Creates [UnitsData] from JSON.
  factory UnitsData.fromJson(Map<String, dynamic> json) {
    final mains = (json['main'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
    final alts = (json['alt'] as List<dynamic>?)?.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
    return UnitsData(main: mains, alt: alts);
  }
  /// Primary list of lessons (units 1–28).
  final List<Lesson> main;

  /// Optional alternate lessons (e.g. number split style).
  final List<Lesson>? alt;

  @override
  String toString() => r'UnitsData(main: ${main.length}, alt: ${alt?.length ?? 0})';
}
