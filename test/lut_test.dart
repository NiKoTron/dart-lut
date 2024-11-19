import 'package:test/test.dart';
import 'package:dart_lut/src/model/lut.dart';
import 'package:dart_lut/src/model/rgb.dart';
import 'package:dart_lut/src/model/table3d.dart';

void main() {
  group('LUT.interpolateFromOriginalTable', () {
    test('Basic interpolation', () {
      final table = Table3D<RGB>.fromIterable(2, [
        RGB(0, 0, 0),
        RGB(0, 0, 1),
        RGB(0, 1, 0),
        RGB(0, 1, 1),
        RGB(1, 0, 0),
        RGB(1, 0, 1),
        RGB(1, 1, 0),
        RGB(1, 1, 1),
      ]);

      final lut = LUT(
        title: 'Basic LUT',
        table: table,
        domainMin: RGB(0, 0, 0),
        domainMax: RGB(1, 1, 1),
      );

      final result = lut.interpolateFromOriginalTable(0.5, 0.5, 0.5);

      expect(result.r, closeTo(0.5, 1e-6));
      expect(result.g, closeTo(0.5, 1e-6));
      expect(result.b, closeTo(0.5, 1e-6));
    });

    test('Boundary values', () {
      final table = Table3D<RGB>.fromIterable(2, [
        RGB(0, 0, 0),
        RGB(0, 0, 1),
        RGB(0, 1, 0),
        RGB(0, 1, 1),
        RGB(1, 0, 0),
        RGB(1, 0, 1),
        RGB(1, 1, 0),
        RGB(1, 1, 1),
      ]);

      final lut = LUT(
        title: 'Boundary Test LUT',
        table: table,
        domainMin: RGB(0, 0, 0),
        domainMax: RGB(1, 1, 1),
      );

      final lowerBound = lut.interpolateFromOriginalTable(0.0, 0.0, 0.0);
      expect(lowerBound.r, equals(0.0));
      expect(lowerBound.g, equals(0.0));
      expect(lowerBound.b, equals(0.0));

      final upperBound = lut.interpolateFromOriginalTable(1.0, 1.0, 1.0);
      expect(upperBound.r, equals(1.0));
      expect(upperBound.g, equals(1.0));
      expect(upperBound.b, equals(1.0));
    });

    test('Invalid domain', () {
      final table = Table3D<RGB>.fromIterable(2, [
        RGB(0, 0, 0),
        RGB(0, 0, 1),
        RGB(0, 1, 0),
        RGB(0, 1, 1),
        RGB(1, 0, 0),
        RGB(1, 0, 1),
        RGB(1, 1, 0),
        RGB(1, 1, 1),
      ]);

      final lut = LUT(
        title: 'Invalid Domain LUT',
        table: table,
        domainMin: RGB(1, 1, 1),
        domainMax: RGB(0, 0, 0),
      );

      expect(
        () => lut.interpolateFromOriginalTable(0.5, 0.5, 0.5),
        throwsArgumentError,
      );
    });

    test('Out of range values', () {
      final table = Table3D<RGB>.fromIterable(2, [
        RGB(0, 0, 0),
        RGB(0, 0, 1),
        RGB(0, 1, 0),
        RGB(0, 1, 1),
        RGB(1, 0, 0),
        RGB(1, 0, 1),
        RGB(1, 1, 0),
        RGB(1, 1, 1),
      ]);

      final lut = LUT(
        title: 'Out of Range LUT',
        table: table,
        domainMin: RGB(0, 0, 0),
        domainMax: RGB(1, 1, 1),
      );

      final result = lut.interpolateFromOriginalTable(-0.5, 1.5, 0.5);
      expect(result.r, closeTo(0.0, 1e-6));
      expect(result.g, closeTo(1.0, 1e-6));
      expect(result.b, closeTo(0.5, 1e-6));
    });

    test('Interpolation with varied corner values', () {
      final table = Table3D<RGB>.fromIterable(2, [
        RGB(0, 0, 0),
        RGB(1, 0, 0),
        RGB(0, 1, 0),
        RGB(1, 1, 0),
        RGB(0, 0, 1),
        RGB(1, 0, 1),
        RGB(0, 1, 1),
        RGB(1, 1, 1),
      ]);

      final lut = LUT(
        title: 'Varied LUT',
        table: table,
        domainMin: RGB(0, 0, 0),
        domainMax: RGB(1, 1, 1),
      );

      final result = lut.interpolateFromOriginalTable(0.5, 0.5, 0.5);

      expect(result.r, closeTo(0.5, 1e-6));
      expect(result.g, closeTo(0.5, 1e-6));
      expect(result.b, closeTo(0.5, 1e-6));
    });
  });
}
