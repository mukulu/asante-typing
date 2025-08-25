/// Utility functions for the typing tutor (pure & testable).

String formatDuration(Duration d) {
  final total = d.inSeconds;
  final mm = (total ~/ 60).toString().padLeft(2, '0');
  final ss = (total % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// Map unit index (0-based) to an asset path under assets/img/.
/// Adjust mapping to mirror your curriculum. Defaults to 'allfingers.jpg'.
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
    file = 'allfingers.jpg'; // units 22–28: special characters etc.
  }
  return 'assets/img/$file';
}
