import 'dart:io';

import 'package:dart_lut/src/interpolation.dart';
import 'package:dart_lut/src/lut.dart';
import 'package:dart_lut/src/colour.dart';
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
      final rgb = Colour(0, 0.5, 1);
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
      var l = LUT.fromString(f1.readAsStringSync());

      final isLoaded = await l
          .awaitLoading()
          .timeout(Duration(milliseconds: 3500), onTimeout: () => false);

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
          '# {r,(3*g+b)/4.0,b}\nTITLE example\nDOMAIN_MIN 1.0 2.0 3.0\nDOMAIN_MAX 4.0 5.0 6.0\n\nLUT_3D_SIZE 2\n\n0.0 0.0 0.0\n1.0 0.0 0.0\n0.0 0.75 0.0\n1.0 0.75 0.0\n0.0 0.25 1.0\n1.0 0.25 1.0\n0.0 1.0 1.0\n1.0 1.0 1.0\n';
      final l = LUT.fromString(data);

      final isLoaded = await l.awaitLoading();

      expect(isLoaded, equals(true));

      expect(l, isNotNull);
      expect(l.sizeOf3DTable, equals(2));
      expect(l.title, equals('example'));
      expect(l.table3D.get(0, 0, 0), isNotNull);
      expect(l.table3D.get(1, 1, 1), isNotNull);
      expect(l.domainMax, equals(const Colour(4, 5, 6)));
      expect(l.domainMin, equals(const Colour(1, 2, 3)));
    });

    test('fail LUT creating wrong size', () async {
      final data =
          '# {r,(3*g+b)/4.0,b}\nTITLE example\nDOMAIN_MIN 0.0 0.0 0.0\nDOMAIN_MAX 1.0 1.0 1.0\n\nLUT_3D_SIZE f2feg\n\n1.0 0.0 0.0\n1.0 0.0 0.0\n0.0 0.75 0.0\n1.0 0.75 0.0\n0.0 0.25 1.0\n1.0 0.25 1.0\n0.0 1.0 1.0\n1.0 1.0 1.0\n';
      final l = LUT.fromString(data);

      final result = await l.awaitLoading();
      expect(result, equals(false));
    });

    test('fail LUT creating wrong domain', () async {
      final data =
          '# {r,(3*g+b)/4.0,b}\nTITLE example\nDOMAIN_MIN 0.0 0.0 0.0\nDOMAIN_MAX g.0 1.0 1.0\n\nLUT_3D_SIZE 2\n\n1.0 0.0 0.0\n1.0 0.0 0.0\n0.0 0.75 0.0\n1.0 0.75 0.0\n0.0 0.25 1.0\n1.0 0.25 1.0\n0.0 1.0 1.0\n1.0 1.0 1.0\n';
      final l = LUT.fromString(data);

      final result = await l.awaitLoading();
      expect(result, equals(false));
    });

    test('fail LUT creating wrong data', () async {
      final data =
          '# {r,(3*g+b)/4.0,b}\nTITLE example\nDOMAIN_MIN 0.0 0.0 0.0\nDOMAIN_MAX 1.0 1.0 1.0\n\nLUT_3D_SIZE 2\n\n1.0 0.0 0.0\n1.0 0.0 0.0\n0.0 0asf75 0.0\n1.0 0.75 0.0\n0.0 0.25 1.0\n1.0 0.25 1.0\n0.0 1.0 1.0\n1.0 1.0 1.0\n';
      final l = LUT.fromString(data);

      final result = await l.awaitLoading();
      expect(result, equals(false));
    });

    test('fail LUT creating data bigger than domain max', () async {
      final data =
          '# {r,(3*g+b)/4.0,b}\nTITLE example\nDOMAIN_MIN 0.0 0.0 0.0\nDOMAIN_MAX 1.0 1.0 1.0\n\nLUT_3D_SIZE 2\n\n4.0 0.0 0.0\n1.0 0.0 0.0\n0.0 75 0.0\n1.0 0.75 0.0\n0.0 0.25 1.0\n1.0 0.25 1.0\n0.0 1.0 1.0\n1.0 1.0 1.0\n';
      final l = LUT.fromString(data);

      final result = await l.awaitLoading();
      expect(result, equals(false));
    });

    test('apply linear cube', () async {
      final dataLinear =
          'TITLE "linear cubi cube"\n\nLUT_3D_SIZE 3\n\n0.0 0.0 0.0\n0.5 0.0 0.0\n1.0 0.0 0.0\n\n0.0 0.5 0.0\n0.5 0.5 0.0\n1.0 0.5 0.0\n\n0.0 1.0 0.0\n0.5 1.0 0.0\n1.0 1.0 0.0\n\n#\n\n0.0 0.0 0.5\n0.5 0.0 0.5\n1.0 0.0 0.5\n\n0.0 0.5 0.5\n0.5 0.5 0.5\n1.0 0.5 0.5\n\n0.0 1.0 0.5\n0.5 1.0 0.5\n1.0 1.0 0.5\n\n#\n\n0.0 0.0 1.0\n0.5 0.0 1.0\n1.0 0.0 1.0\n\n0.0 0.5 1.0\n0.5 0.5 1.0\n1.0 0.5 1.0\n\n0.0 1.0 1.0\n0.5 1.0 1.0\n1.0 1.0 1.0\n';
      final l = LUT.fromString(dataLinear);
      await l.awaitLoading();

      final bb = [
        0xff,
        0xee,
        0x00,
        0xff,
        0xff,
        0xee,
        0x00,
        0xff,
        0xff,
        0xee,
        0x00,
        0xff,
        0xff,
        0xee,
        0x00,
        0xff
      ];

      final ll = l.applySync(bb);

      expect(ll, equals(bb));
    });
  });
}
