import 'package:asante_typing/utils/typing_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDuration', () {
    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), equals('00:00'));
    });
    test('formats single digit seconds', () {
      expect(formatDuration(const Duration(seconds: 5)), equals('00:05'));
    });
    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 2, seconds: 3)), equals('02:03'));
    });
  });

  group('fingerAssetForUnit', () {
    test('returns correct mapping for early units', () {
      expect(fingerAssetForUnit(0), equals('assets/img/home-keys-position.jpg'));
      expect(fingerAssetForUnit(3), equals('assets/img/forefingers.jpg'));
      expect(fingerAssetForUnit(5), equals('assets/img/middlefingers.jpg'));
    });
    test('returns qwerty for mid units', () {
      expect(fingerAssetForUnit(11), equals('assets/img/qwerty.jpg'));
    });
    test('returns allfingers for late units', () {
      expect(fingerAssetForUnit(25), equals('assets/img/allfingers.jpg'));
    });
  });
}
