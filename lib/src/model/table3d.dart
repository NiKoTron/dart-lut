import 'dart:typed_data';

import 'package:meta/meta.dart';

abstract class Table3D<T> {
  @protected
  List<T> get table;

  int get size;

  /// Sets some value to coordinates
  /// @param value some value
  /// @param x x part of coordinate
  /// @param y y part of coordinate
  /// @param z z part of coordinate
  void set(int x, int y, int z, T value) {
    table[index(x, y, z)] = value;
  }

  /// Take some value by coordinates
  /// @return some value
  /// @param x x part of coordinate
  /// @param y y part of coordinate
  /// @param z z part of coordinate
  T get(int x, int y, int z) {
    return table[index(x, y, z)];
  }

  @protected
  int index(int x, int y, int z) => x + (size * y) + (size * size * z);

  static Table3D<T> fromIterable<T>(int size, Iterable<T> iterable) {
    // if (T == int) {
    //   return Uint8Table3D.fromList(size, (iterable as Iterable<int>).toList())
    //       as Table3D<T>;
    // }

    return Table3DGen(size, iterable);
  }
}

/// This class represent 3 dimensional cube table
class Table3DGen<T> extends Table3D<T> {
  /// Size of cube
  @override
  final int size;

  @override
  final List<T> table;

  Table3DGen(this.size, Iterable<T> iterable)
      : assert(iterable.length == size * size * size),
        table = List<T>.from(iterable);
}

class Uint8Table3D extends Table3D<int> {
  @override
  final int size;

  @override
  final Uint8List table;

  Uint8Table3D(this.size) : table = Uint8List(size * size * size);

  Uint8Table3D.fromList(this.size, List<int> list)
      : table = Uint8List.fromList(list);
}
