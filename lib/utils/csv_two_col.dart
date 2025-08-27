// NEW: simple two-column CSV detector & parser (supports quotes, no newlines in cells)
import 'dart:convert';

class TwoColCsv {
  /// Returns null when not a valid 2-col CSV, otherwise a list of (title, passage).
  static List<MapEntry<String, String>>? tryParse(String raw) {
    if (raw.trim().isEmpty) return null;

    final lines = const LineSplitter().convert(raw.trim());
    if (lines.isEmpty) return null;

    final rows = <MapEntry<String, String>>[];
    var ok = 0;
    var total = 0;

    for (final line in lines) {
      final parsed = _parseTwoCells(line);
      if (parsed == null) {
        total++;
        continue;
      }
      total++;
      ok++;
      rows.add(parsed);
    }

    // Heuristic: at least 3 valid lines and >=80% lines are valid
    if (rows.length >= 3 && ok / total >= 0.8) {
      return rows;
    }
    return null;
  }

  // Very small CSV line parser for exactly 2 cells, supports quotes and commas.
  // Disallows newlines inside cells (your UX hint says “avoid newline characters”).
  static MapEntry<String, String>? _parseTwoCells(String line) {
    // Match:  "a","b"   or   a,b   or   "a",b   or   a,"b"
    final re = RegExp(
      r'^\s*(?:"([^"]*)"|([^",]*))\s*,\s*(?:"([^"]*)"|([^",]*))\s*$'
    );
    final m = re.firstMatch(line);
    if (m == null) return null;

    final cell1 = m.group(1) ?? m.group(2) ?? '';
    final cell2 = m.group(3) ?? m.group(4) ?? '';
    return MapEntry(cell1, cell2);
  }
}
