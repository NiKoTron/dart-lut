import 'dart:io';

import 'package:dart_lut/src/interpolation.dart';
import 'package:test/test.dart';

void main() {
  group('interpolations', () {
    test('trilerp basic', () {
      final result = Interpolation.trilerp(
          0.5, 0.5, 0.5, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1);
      expect(result, closeTo(0.5, 1e-6));
    });
    test('lerp', () {
      final i = Interpolation.lerp(0.5, 0, 1, 5, 10);
      expect(i, equals(7.5));
    });

    test('bilerp', () {
      final i = Interpolation.bilerp(0.5, 0.5, 10, 10, 20, 20, 0, 1, 0, 1);
      final i2 = Interpolation.bilerp(0.5, 0.5, 10, 15, 15, 20, 0, 1, 0, 1);

      expect(i, equals(15));
      expect(i2, equals(15));
    });

    test('trilerp', () {
      final i = Interpolation.trilerp(
          0.5, 0.5, 0.5, 10, 20, 10, 20, 10, 20, 10, 20, 0, 1, 0, 1, 0, 1);
      expect(i, equals(15));
    });
  });
}
