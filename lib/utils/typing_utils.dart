// Utility functions for formatting durations and selecting finger diagrams.

/// Returns a human‑readable string in mm:ss format for a [Duration].
String formatDuration(Duration d) {
  final total = d.inSeconds;
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Maps a zero‑based unit index to an asset path under `assets/img/` for
/// finger diagrams.
///
/// The returned string includes the `assets/img/` prefix and points to a JPG
/// image. Units 1–3 display the home row positioning (`home-keys-position.jpg`);
/// units 4–5 show the forefingers (`forefingers.jpg`); unit 6 uses the
/// middle finger diagram (`middlefingers.jpg`); unit 7 uses the ring fingers
/// (`ringfingers.jpg`); unit 8 uses the little fingers (`littlefingers.jpg`);
/// unit 9 uses the left hand (`leftfingers.jpg`); unit 10 uses the right
/// hand (`rightfingers.jpg`); unit 11 shows both little and forefingers
/// (`littleandforefingers.jpg`); units 12–21 use the full QWERTY diagram
/// (`qwerty.jpg`); units 22–28 display all fingers (`allfingers.jpg`).
String? fingerAssetForUnit(int unitIndex) {
  final n = unitIndex + 1;
  String file;
  if (n <= 3) {
    file = 'home-keys-position.jpg';
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
