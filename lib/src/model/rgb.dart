/// This class stores RGB values
class RGB {
  /// The Red value
  final double r;

  /// The Green value
  final double g;

  /// The Blue value
  final double b;

  const RGB(double this.r, double this.g, double this.b);

  @override
  String toString() {
    return '{R:$r, G:$g, B:$b}';
  }

  @override
  int get hashCode {
    var result = 17;
    result = 37 * result + r.hashCode;
    result = 37 * result + g.hashCode;
    result = 37 * result + b.hashCode;
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is RGB) {
      return this.r == other.r && this.g == other.g && this.b == other.b;
    }
    return false;
  }
}
