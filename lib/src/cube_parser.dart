// ignore_for_file: unnecessary_null_comparison

import 'package:dart_lut/src/model/rgb.dart';

class _CLRegEx {
  static final emptyLine = RegExp(r'^\s*$');
  static final comment = RegExp(r'^#');
  static final patternTitle = RegExp(r'^TITLE\s+("[\w|\s]+"|[\w|\s]+)$');
  static final patternLut3DSize = RegExp(r'^LUT_3D_SIZE\s+(\d+)');
  static final patternDomainMin = RegExp(
      r'^DOMAIN_MIN\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)');
  static final patternDomainMax = RegExp(
      r'^DOMAIN_MAX\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)');
  static final patternData =
      RegExp(r'^(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)');
}

sealed class CubeLine<T> {
  final RegExp pattern;

  final String string;

  CubeLine({required this.pattern, required this.string});
  T get parse;
}

class EmptyLine extends CubeLine<void> {
  EmptyLine() : super(pattern: RegExp(r'^\s*$'), string: '');

  @override
  void get parse => null;
}

class CommentLine extends CubeLine<String> {
  CommentLine(String string) : super(pattern: RegExp(r'^#'), string: string);

  @override
  String get parse => string.replaceFirst(pattern, '');
}

class TitleLine extends CubeLine<String> {
  TitleLine(String string)
      : super(
          pattern: _CLRegEx.patternTitle,
          string: string,
        );

  @override
  String get parse => CubeParse.readTitle(string);
}

class Lut3DSizeLine extends CubeLine<int> {
  Lut3DSizeLine(String string)
      : super(
          pattern: _CLRegEx.patternLut3DSize,
          string: string,
        );

  @override
  int get parse => CubeParse.read3DLutSize(string);
}

class DomainMinLine extends CubeLine<RGB> {
  DomainMinLine(String string)
      : super(
          pattern: _CLRegEx.patternDomainMin,
          string: string,
        );

  @override
  RGB get parse => CubeParse.readDomainMin(string);
}

class DomainMaxLine extends CubeLine<RGB> {
  DomainMaxLine(String string)
      : super(
          pattern: _CLRegEx.patternDomainMax,
          string: string,
        );

  @override
  RGB get parse => CubeParse.readDomainMax(string);
}

class DataLine extends CubeLine<RGB> {
  final RGB domainMin;
  final RGB domainMax;

  DataLine(String string, this.domainMin, this.domainMax)
      : super(
          pattern: _CLRegEx.patternData,
          string: string,
        );

  @override
  RGB get parse => CubeParse.readRgb(string, domainMin, domainMax);
}

class CubeParse {
  static CubeLine getCubeLine(
    String string, [
    RGB domainMin = const RGB(0, 0, 0),
    RGB domainMax = const RGB(1, 1, 1),
  ]) {
    if (_CLRegEx.emptyLine.hasMatch(string)) {
      return EmptyLine();
    } else if (_CLRegEx.comment.hasMatch(string)) {
      return CommentLine(string);
    } else if (_CLRegEx.patternTitle.hasMatch(string)) {
      return TitleLine(string);
    } else if (_CLRegEx.patternLut3DSize.hasMatch(string)) {
      return Lut3DSizeLine(string);
    } else if (_CLRegEx.patternDomainMin.hasMatch(string)) {
      return DomainMinLine(string);
    } else if (_CLRegEx.patternDomainMax.hasMatch(string)) {
      return DomainMaxLine(string);
    } else {
      return DataLine(string, domainMin, domainMax);
    }
  }

  static String readTitle(String line) {
    if (_CLRegEx.patternTitle.hasMatch(line)) {
      final m = _CLRegEx.patternTitle.firstMatch(line);
      return m!.group(1)!;
    } else {
      throw FormatException('Invalid title: "$line"');
    }
  }

  static int read3DLutSize(String line) {
    final exp = _CLRegEx.patternLut3DSize;
    if (exp.hasMatch(line)) {
      final size = int.tryParse(exp.firstMatch(line)?.group(1) ?? '');
      if (size == null) {
        throw FormatException('Size cannot be parsed: "$line"');
      }
      return size;
    } else {
      throw FormatException('Invalid size value: "$line"');
    }
  }

  static RGB readDomainMin(String line) {
    return _readDomain(line, _CLRegEx.patternDomainMin);
  }

  static RGB readDomainMax(String line) {
    return _readDomain(line, _CLRegEx.patternDomainMax);
  }

  static RGB readRgb(String line, RGB domainMin, RGB domainMax) {
    final exp = _CLRegEx.patternData;
    if (exp.hasMatch(line)) {
      final match = exp.firstMatch(line)!;
      final r = _validateAndParse(match.group(1)!, domainMin.r, domainMax.r);
      final g = _validateAndParse(match.group(2)!, domainMin.g, domainMax.g);
      final b = _validateAndParse(match.group(3)!, domainMin.b, domainMax.b);
      return RGB(r, g, b);
    } else if (line.isNotEmpty) {
      throw FormatException('Invalid RGB data: "$line"');
    } else {
      throw FormatException('Empty line');
    }
  }

  static RGB _readDomain(String line, RegExp exp) {
    if (exp.hasMatch(line)) {
      final match = exp.firstMatch(line)!;
      final r = _validateAndParse(match.group(1)!);
      final g = _validateAndParse(match.group(2)!);
      final b = _validateAndParse(match.group(3)!);
      return RGB(r, g, b);
    } else {
      throw FormatException('Invalid domain value: "$line"');
    }
  }

  static double _validateAndParse(String s,
      [double min = double.negativeInfinity, double max = double.infinity]) {
    if (s.isEmpty) {
      throw FormatException('Input data shouldn`t be empty or null: "$s"');
    }
    final value = double.tryParse(s);
    if (value == null) {
      throw FormatException('Input data can`t parsed as a double value: "$s"');
    }
    if ((max != null) && (value < min || value > max)) {
      throw FormatException(
          'Input data not in range: [$min <= $value <= $max]');
    }
    return value;
  }
}
