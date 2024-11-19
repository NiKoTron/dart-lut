import 'package:dart_lut/src/model/rgb.dart';
import 'package:dart_lut/src/model/table3d.dart';

class LUT {
  /// Title of LUT table stroed at TITLE field
  final String title;

  /// The minimum domain value
  final RGB domainMin;

  /// The maximum domain value
  final RGB domainMax;

  final Table3D<RGB> table;

  LUT({
    required this.title,
    required this.table,
    this.domainMin = const RGB(0, 0, 0),
    this.domainMax = const RGB(1, 1, 1),
  });

  int get size => table.size;

  @override
  String toString() {
    return 'LUT(title: $title, domainMin: $domainMin, domainMax: $domainMax, table: $table)';
  }
}
