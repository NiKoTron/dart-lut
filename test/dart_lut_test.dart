import 'dart:io';

import 'package:dart_lut/src/interpolation.dart';
import 'package:dart_lut/src/lut.dart';
import 'package:dart_lut/src/rgb.dart';
import 'package:dart_lut/src/table.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  group('interpolations', () {
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

  group('RGB tests', () {
    test('creation test', () {
      final rgb = RGB(0, 0.5, 1);
      expect(rgb.r, equals(0));
      expect(rgb.g, equals(0.5));
      expect(rgb.b, equals(1));
    });
  });

  group('Table3D tests', () {
    test('create table', () {
      final size = 3;
      final t3d = Table3D<int>(size);
      expect(t3d.size, equals(size));
      expect(t3d.get(2, 2, 2), equals(null));
    });

    test('set value in to table', () {
      final size = 3;
      final t3d = Table3D<int>(size)..set(2, 2, 2, 5)..set(0, 1, 2, 7);

      expect(t3d.get(2, 2, 2), equals(5));
      expect(t3d.get(0, 1, 2), equals(7));
    });
  });

  group('LUT tests', () {
    test('create LUT from file', () async {
      var f1 = new File('test/asserts/exmp.cube');
      var l = LUT.fromFile(f1);

      final isLoaded = await l.awaitLoading();

      expect(isLoaded, equals(true));

      expect(l, isNotNull);
      expect(l.sizeOf3DTable, equals(2));
      expect(l.title, equals('example'));
      expect(l.table3D, isNotNull);
      expect(l.table3D.get(0, 0, 0), isNotNull);
      expect(l.table3D.get(1, 1, 1), isNotNull);
    });

    test('create LUT from string', () async {
      final data =
          '# {r,(3*g+b)/4.0,b}\nTITLE example\nDOMAIN_MIN 0.0 0.0 0.0\nDOMAIN_MAX 1.0 1.0 1.0\n\nLUT_3D_SIZE 2\n\n0.0 0.0 0.0\n1.0 0.0 0.0\n0.0 0.75 0.0\n1.0 0.75 0.0\n0.0 0.25 1.0\n1.0 0.25 1.0\n0.0 1.0 1.0\n1.0 1.0 1.0\n';
      final l = LUT.fromString(data);

      final isLoaded = await l.awaitLoading();

      expect(isLoaded, equals(true));

      expect(l, isNotNull);
      expect(l.sizeOf3DTable, equals(2));
      expect(l.title, equals('example'));
      expect(l.table3D.get(0, 0, 0), isNotNull);
      expect(l.table3D.get(1, 1, 1), isNotNull);
    });
  });
}
