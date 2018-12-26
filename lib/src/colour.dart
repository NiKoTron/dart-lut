/// This class stores RGB values
class Colour {
  final double _r;
  final double _g;
  final double _b;

  const Colour(double this._r, double this._g, double this._b)
      : assert(_r != null),
        assert(_g != null),
        assert(_b != null);

  /// The Red value
  double get r => _r;

  /// The Green value
  double get g => _g;

  /// The Blue value
  double get b => _b;

  @override
  String toString() {
    return '{R:$_r, G:$_g, B:$_b}';
  }

  @override
  int get hashCode {
    var result = 17;
    result = 37 * result + _r.hashCode;
    result = 37 * result + _g.hashCode;
    result = 37 * result + _b.hashCode;
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is Colour) {
      return this._r == other.r && this._g == other.g && this._b == other.b;
    }
    return false;
  }
}
