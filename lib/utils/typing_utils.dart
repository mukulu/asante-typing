/// Pure helper functions for formatting durations and mapping units to images.

/// Returns a human‑readable string in mm:ss format for a [Duration].
String formatDuration(Duration d) {
  final total = d.inSeconds;
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Maps a 0‑based unit index to an image asset path under `assets/img/`.
///
/// The mapping follows the guidance from the QuickQWERTY curriculum:
///  - Units 1–3 use the home keys diagram.
///  - Units 4–5 emphasise forefingers.
///  - Unit 6 uses the middle fingers.
///  - Unit 7 uses the ring fingers.
///  - Unit 8 uses the little fingers.
///  - Unit 9 shows left‑hand fingers.
///  - Unit 10 shows right‑hand fingers.
///  - Unit 11 shows little and forefingers.
///  - Units 12–21 show the full keyboard (QWERTY image).
///  - Units 22–28 show all fingers (special characters and numbers).
String? fingerAssetForUnit(int unitIndex) {
  final n = unitIndex + 1;
  String file;
  if (n <= 3) {
    file = 'home-keys-position.svg.png';
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