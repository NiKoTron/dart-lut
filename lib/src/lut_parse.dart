import 'dart:async';
import 'dart:typed_data';

import 'package:dart_lut/src/cube_parser.dart';
import 'package:dart_lut/src/interpolation.dart';
import 'package:dart_lut/src/model/lut.dart';
import 'package:dart_lut/src/model/rgb.dart';
import 'package:dart_lut/src/model/table3d.dart';

/// This class used for interaction with Look Up Table
abstract final class LUTParser {
  /// This factory creating LUT from string
  static Future<LUT> fromString(String str) =>
      _parse(Stream.fromIterable(str.split('\n')));

  static Future<LUT> fromStream(Stream<String> stream) => _parse(stream);

  static Future<LUT> _parse(Stream<String> stream) async {
    final lutCompleter = Completer<LUT>();

    var size = -1;

    var title = '';

    var domainMin = RGB(0, 0, 0);
    var domainMax = RGB(1, 1, 1);

    final rgbList = <RGB>[];

    await for (final str in stream) {
      final line = CubeParse.getCubeLine(str, domainMin, domainMax);
      switch (line) {
        case CommentLine():
          print('Comment line');
          print(line.parse);
          break;
        case TitleLine():
          title = line.parse;
          break;
        case Lut3DSizeLine():
          size = line.parse;
          if (size < 2) {
            throw FormatException(
                'Size of 3D LUT table should be greater than 1');
          }
          break;
        case DomainMinLine():
          domainMin = line.parse;
          break;
        case DomainMaxLine():
          domainMax = line.parse;
          break;
        case DataLine():
          rgbList.add(line.parse);
          break;
        case EmptyLine():
          print('Empty line');
          break;
      }
    }

    final table = Table3D.fromIterable(size, rgbList);

    lutCompleter.complete(LUT(
        title: title,
        domainMin: domainMin,
        domainMax: domainMax,
        table: table));

    return lutCompleter.future;
  }
}

class LUTProcessor {
  final LUT lut;
  int get sizeOf3DTable => lut.size;

  final bitDepth = 8;
  late final bpc = 1 << bitDepth; // 2^bitDepth

  // Precomputed table for faster processing
  late final Table3D<int> table;

  LUTProcessor(this.lut, {bool precompute = true}) {
    _precomputeTables();
  }

  /// Compute tables for faster processing
  void _precomputeTables() {
    table = normalizedTable();
  }

  Table3D<int> normalizedTable() {
    final normalizedSize = bpc;

    final stepR = (lut.domainMax.r - lut.domainMin.r) / (lut.size - 1);
    final stepG = (lut.domainMax.g - lut.domainMin.g) / (lut.size - 1);
    final stepB = (lut.domainMax.b - lut.domainMin.b) / (lut.size - 1);

    final list = List<int>.generate(
      normalizedSize * normalizedSize * normalizedSize,
      (index) {
        final x = index % normalizedSize;
        final y = (index ~/ normalizedSize) % normalizedSize;
        final z = (index ~/ (normalizedSize * normalizedSize));

        // normalize coordinates
        final normalizedR = lut.domainMin.r + x * stepR;
        final normalizedG = lut.domainMin.g + y * stepG;
        final normalizedB = lut.domainMin.b + z * stepB;

        // interpolate value from original table
        final rgb = interpolateRGB(normalizedR, normalizedG, normalizedB);

        // Convert RGB to int
        return _rgbToInt(rgb.r, rgb.g, rgb.b);
      },
    );

    final tbl = Table3D.fromIterable(normalizedSize, list);
    return tbl;
  }

  int _clampToChannelSize(int x) => x.clamp(0, bpc).floor();

  RGB interpolateRGB(double r, double g, double b) {
    final sizeOf3DTable = lut.table.size;

    final _k = (sizeOf3DTable - 1) / 255;

    final iR = (r * _k);
    final fR1 = iR >= sizeOf3DTable - 1
        ? _clampToChannelSize(sizeOf3DTable - 1)
        : _clampToChannelSize((iR + 1).floor());
    final fR0 = iR <= 0 ? 0 : _clampToChannelSize((iR - 1).floor());

    final iG = (g * _k);
    final fG1 = iG >= sizeOf3DTable - 1
        ? _clampToChannelSize(sizeOf3DTable - 1)
        : _clampToChannelSize((iG + 1).floor());
    final fG0 = iG <= 0 ? 0 : _clampToChannelSize((iG - 1).floor());

    final iB = (b * _k);
    final fB1 = iB >= sizeOf3DTable - 1
        ? _clampToChannelSize(sizeOf3DTable - 1)
        : _clampToChannelSize((iB + 1).floor());
    final fB0 = iB <= 0 ? 0 : _clampToChannelSize((iB - 1).floor());

    final c000 = lut.table.get(fR0, fG0, fB0);
    final c010 = lut.table.get(fR0, fG1, fB0);
    final c001 = lut.table.get(fR0, fG0, fB1);
    final c011 = lut.table.get(fR0, fG1, fB1);
    final c101 = lut.table.get(fR1, fG0, fB1);
    final c100 = lut.table.get(fR1, fG0, fB0);
    final c110 = lut.table.get(fR1, fG1, fB0);
    final c111 = lut.table.get(fR1, fG1, fB1);

    final rx = Interpolation.trilerp(iR, iG, iB, c000.r, c001.r, c010.r, c011.r,
        c100.r, c101.r, c110.r, c111.r, fR0, fR1, fG0, fG1, fB0, fB1);

    final gx = Interpolation.trilerp(iR, iG, iB, c000.g, c001.g, c010.g, c011.g,
        c100.g, c101.g, c110.g, c111.g, fR0, fR1, fG0, fG1, fB0, fB1);

    final bx = Interpolation.trilerp(iR, iG, iB, c000.b, c001.b, c010.b, c011.b,
        c100.b, c101.b, c110.b, c111.b, fR0, fR1, fG0, fG1, fB0, fB1);

    return RGB(rx, gx, bx);
  }

  int _rgbToInt(double r, double g, double b) {
    // Преобразуем значения [0, 1] в [0, bpc] и собираем их в int
    final red = (r.clamp(0.0, 1.0) * 0xFF).toInt();
    final green = (g.clamp(0.0, 1.0) * 0xFF).toInt();
    final blue = (b.clamp(0.0, 1.0) * 0xFF).toInt();

    return (red << 16) | (green << 8) | blue;
  }

  int _rgbaToInt(double r, double g, double b, int a) {
    // Преобразуем значения [0, 1] в [0, bpc] и собираем их в int
    final red = (r.clamp(0.0, 1.0) * bpc).toInt();
    final green = (g.clamp(0.0, 1.0) * bpc).toInt();
    final blue = (b.clamp(0.0, 1.0) * bpc).toInt();

    return (a << 24) | (red << 16) | (green << 8) | blue;
  }

  /// Apply LUT transformation for bitmap array synchroniously
  /// @param data The bitmap array for transformation.
  /// @param intType the type of interpolation chose between speed and accuracy;
  ///
  /// _surprisingly but [List<int>] actualy faster then [Uint8List]_
  Uint8List applySync(Uint8List data) {
    if (data.length % 4 != 0) {
      throw ArgumentError('Data length must be a multiple of 4 (RGBA format)');
    }

    final result = Uint8List(data.length);

    for (var i = 0; i < data.length; i += 4) {
      final color = table.get(data[i], data[i + 1], data[i + 2]);

      result[i] = ((color >> 16) & 0xFF);
      result[i + 1] = ((color >> 8) & 0xFF);
      result[i + 2] = (color & 0xFF);
      result[i + 3] = data[i + 3]; //preserve alpha
    }

    return result;
  }
}
