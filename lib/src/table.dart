/// This class represent 3 dimensional cube table
class Table3D<T> {
  final int _size;

  List<T> _tablen;

  List<T> get tbl => _tablen;

  /// Constructor for 3 dimensional cube table
  /// @param _size size of cube
  Table3D(this._size) {
    _tablen = List<T>(_size * _size * _size);
  }

  /// Sets some value to coordinates
  /// @param value some value
  /// @param x x part of coordinate
  /// @param y y part of coordinate
  /// @param z z part of coordinate
  void set(int x, int y, int z, T value) {
    _tablen[_index(x, y, z)] = value;
  }

  int _index(int x, int y, int z) => x + (_size * y) + (_size * _size * z);

  /// Take some value by coordinates
  /// @return some value
  /// @param x x part of coordinate
  /// @param y y part of coordinate
  /// @param z z part of coordinate
  T get(int x, int y, int z) {
    return _tablen[_index(x, y, z)];
  }

  /// Size of cube
  int get size => _size;
}
