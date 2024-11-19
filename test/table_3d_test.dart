import 'dart:io';

import 'package:dart_lut/src/model/table3d.dart';
import 'package:test/test.dart';

void main() {
  group('Table3D tests', () {
    test('create table', () {
      final size = 3;
      final t3d =
          Table3D<int>.fromIterable(size, List.filled(size * size * size, 0));
      expect(t3d.size, equals(size));
      expect(t3d.get(2, 2, 2), equals(0));
    });

    test('set value in to table', () {
      final size = 3;
      final t3d =
          Table3D<int>.fromIterable(size, List.filled(size * size * size, 0))
            ..set(2, 2, 2, 5)
            ..set(0, 1, 2, 7);

      expect(t3d.get(2, 2, 2), equals(5));
      expect(t3d.get(0, 1, 2), equals(7));
    });
  });
}
