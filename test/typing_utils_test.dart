import 'package:flutter_test/flutter_test.dart';
import 'package:asante_typing/utils/typing_utils.dart';

void main() {
  group('formatDuration', () {
    test('formats zero', () {
      expect(formatDuration(const Duration(seconds: 0)), '00:00');
    });
    test('formats mm:ss', () {
      expect(formatDuration(const Duration(minutes: 1, seconds: 5)), '01:05');
      expect(formatDuration(const Duration(minutes: 12, seconds: 34)), '12:34');
    });
  });

  group('fingerAssetForUnit', () {
    test('maps units to assets', () {
      expect(fingerAssetForUnit(0), 'assets/img/home-keys-position.svg.png');
      expect(fingerAssetForUnit(4), 'assets/img/forefingers.jpg');
      expect(fingerAssetForUnit(6), 'assets/img/ringfingers.jpg'); // note mapping logic above
    });
  });
}
