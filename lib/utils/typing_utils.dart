// Utility functions for formatting durations and selecting finger diagrams.

/// Returns a human‑readable string in mm:ss format for a [Duration].
String formatDuration(Duration d) {
  final total = d.inSeconds;
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Maps a 0‑based unit index to an asset path under `assets/img/` for finger diagrams.
///
/// Units 1–3: home keys; 4–5: forefingers; 6: middle fingers; 7: ring fingers;
/// 8: little fingers; 9: left hand; 10: right hand; 11: little+forefingers;
/// 12–21: qwerty image; 22–28: all fingers.
String? fingerAssetForUnit(int unitIndex) {
  final n = unitIndex + 1;
  String file;
  if (n <= 3) {
    file = 'home-keys-position.png';
  } else if (n <= 5) {
    file = 'forefingers.jpg';
  } else if (n == 6) {
    file = 'middlefingers.jpg';
  } else if (n == 7) {
    file = 'ringfingers.jpg';
  } else if (n == 8) {
    file = 'littlefingers.jpg';
  } else if (n == 9) {
    file = 'leftfingers.jpg';
  } else if (n == 10) {
    file = 'rightfingers.jpg';
  } else if (n == 11) {
    file = 'littleandforefingers.jpg';
  } else if (n <= 21) {
    file = 'qwerty.jpg';
  } else {
    file = 'allfingers.jpg';
  }
  return 'assets/img/$file';
}
