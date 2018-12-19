import 'dart:async';
import 'dart:typed_data';

import 'package:dart_lut/src/interpolation.dart';
import 'package:dart_lut/src/rgb.dart';
import 'package:dart_lut/src/table.dart';

/// Interpolation types
enum InterpolationType {
  /// Trilinear interpollation quiete fast and quite accurate
  trilinear
}

/// The files contais constants (2^n)-1
class Depth {
  static const int bit8 = 255;
  static const int bit10 = 1023;
  static const int bit12 = 4095;
  static const int bit24 = 16383;
  static const int bit16 = 65535;
}

/// This class used for interaction with Look Up Table
class LUT {
  /// Title of LUT table stroed at TITLE field
  String title;

  int sizeOf3DTable = -1;

  Table3D<RGB> table3D;

  /// The minimum domain value
  RGB domainMin = RGB(0, 0, 0);

  /// The maximum domain value
  RGB domainMax = RGB(1, 1, 1);

  /// The bits per channel
  /// Default value is [Depth.bit8]
  int bpc = Depth.bit8;

  final Stream<String> _stream;

  final StreamController<bool> _isLoaded = StreamController<bool>.broadcast();

  Stream<bool> get isLoaded => _isLoaded.stream;

  Future<bool> awaitLoading() async {
    var r = _isLoaded.isClosed;
    await for (bool isL in isLoaded) {
      r = isL;
      if (r == true) {
        break;
      }
    }
    _isLoaded.close();
    return r;
  }

  final Map<InterpolationType, Function> _typedFunction = new Map();

  LUT(this._stream) {
    _typedFunction[InterpolationType.trilinear] = _getFromRGBTrilinear;

    _lutTransformer = StreamTransformer<String, LUT>(_onStringStreamListen);

    _stream.transform(_lutTransformer).listen(null);
  }

  /// This factory creating LUT from string
  factory LUT.fromString(String str) {
    return LUT(Stream.fromIterable(str.split('\n')));
  }

  StreamTransformer<String, LUT> _lutTransformer;

  StreamSubscription<LUT> _onStringStreamListen(
      Stream<String> input, bool cancelOnError) {
    var z = 0;
    var y = 0;
    var x = 0;

    StreamSubscription<String> subscription;

    final controller = new StreamController<LUT>(
        onPause: () {
          subscription.pause();
        },
        onResume: () {
          subscription.resume();
        },
        onCancel: () => subscription.cancel(),
        sync: true);

    subscription = _stream.listen(
        (s) {
          if (sizeOf3DTable <= 0) {
            if (title == null || title.isEmpty) {
              title = _readTitle(s);
            }
            if (sizeOf3DTable < 0) {
              sizeOf3DTable = _read3DLUTSize(s);
              if (sizeOf3DTable >= 2) {
                _k = (sizeOf3DTable - 1) / bpc;
                table3D = new Table3D(sizeOf3DTable);
              }
            }
            if (domainMin == null) {
              domainMin = _readDomainMin(s);
            }
            if (domainMax == null) {
              domainMax = _readDomainMax(s);
            }
          } else {
            final rgb = _readRGB(s);
            if (rgb != null) {
              table3D.set(x, y, z, rgb);

              x++;
              if (x == sizeOf3DTable) {
                x = 0;
                y++;
              }
              if (y == sizeOf3DTable) {
                y = 0;
                z++;
              }
            }
          }
        },
        onError: controller.addError,
        onDone: () {
          controller.close();
          _isLoaded.sink.add(true);
        },
        cancelOnError: true);

    return controller.stream.listen(null);
  }

  static final String PARSE_COMMENT_LINE = '#';
  static final String PATTERN_LUT_3D_SIZE = r'^LUT_3D_SIZE\s+(\d+)';
  static final String PATTERN_LUT_3D_INPUT_RANGE =
      r'^LUT_3D_INPUT_RANGE\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)';

  static final String PATTERN_DOMAIN_MIN =
      r'^DOMAIN_MIN\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)';
  static final String PATTERN_DOMAIN_MAX =
      r'^DOMAIN_MAX\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)';

  static final String PATTERN_DATA =
      r'^(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)';

  static final String PATTERN_TITLE = r'^TITLE\s+([\w|\s]+)$';

  static String _readTitle(String s) {
    if (!s.startsWith(PARSE_COMMENT_LINE)) {
      final exp = RegExp(PATTERN_TITLE);
      if (exp.hasMatch(s)) {
        return exp.firstMatch(s).group(1);
      }
    }
    return null;
  }

  static int _read3DLUTSize(String s) {
    if (!s.startsWith(PARSE_COMMENT_LINE)) {
      final exp = RegExp(PATTERN_LUT_3D_SIZE);
      if (exp.hasMatch(s)) {
        return int.tryParse(exp.firstMatch(s).group(1));
      }
    }
    return -1;
  }

  static RGB _readDomainMin(String s) {
    if (!s.startsWith(PARSE_COMMENT_LINE)) {
      final expInputRange = RegExp(PATTERN_DOMAIN_MIN);
      if (expInputRange.hasMatch(s)) {
        return RGB(
            double.tryParse(expInputRange.firstMatch(s).group(1)),
            double.tryParse(expInputRange.firstMatch(s).group(2)),
            double.tryParse(expInputRange.firstMatch(s).group(3)));
      }
    }
    return null;
  }

  static RGB _readDomainMax(String s) {
    if (!s.startsWith(PARSE_COMMENT_LINE)) {
      final expInputRange = RegExp(PATTERN_DOMAIN_MAX);
      if (expInputRange.hasMatch(s)) {
        return RGB(
            double.tryParse(expInputRange.firstMatch(s).group(1)),
            double.tryParse(expInputRange.firstMatch(s).group(2)),
            double.tryParse(expInputRange.firstMatch(s).group(3)));
      }
    }
    return null;
  }

  static RGB _readRGB(String s) {
    if (!s.startsWith(PARSE_COMMENT_LINE)) {
      final expInputRange = RegExp(PATTERN_DATA);
      if (expInputRange.hasMatch(s)) {
        return RGB(
            double.tryParse(expInputRange.firstMatch(s).group(1)),
            double.tryParse(expInputRange.firstMatch(s).group(2)),
            double.tryParse(expInputRange.firstMatch(s).group(3)));
      }
    }
    return null;
  }

  /// Apply LUT transformation for bitmap array synchroniously
  /// @param data The bitmap array for transformation.
  /// @param intType the type of interpolation chose between speed and accuracy;
  ///
  /// _surprisingly but [List<int>] actualy faster then [Uint8List]_
  List<int> applySync(List<int> data,
      [InterpolationType intType = InterpolationType.trilinear]) {
    final fun = _typedFunction[intType];

    final dKR = domainMax.r - domainMin.r;
    final dKG = domainMax.g - domainMin.g;
    final dKB = domainMax.b - domainMin.b;

    final result = new List<int>(data.length);
    if (data != null && data.length >= 4) {
      for (var i = 0; i < data.length; i += 4) {
        final RGB rgb = fun(data[i], data[i + 1], data[i + 2]);

        result[i] = _toIntCh(rgb.r * dKR);
        result[i + 1] = _toIntCh(rgb.g * dKG);
        result[i + 2] = _toIntCh(rgb.b * dKB);
        result[i + 3] = bpc;
      }
    }

    return result;
  }

  /// Apply LUT transformation for bitmap array
  /// @param data The bitmap array for transformation.
  /// @param intType the type of interpolation chose between speed and accuracy;
  ///
  /// _surprisingly but [List<int>] actualy faster then [Uint8List]_
  Future<List<int>> apply(List<int> data, [InterpolationType intType]) async {
    return applySync(data, intType);
  }

  /// This methods yields [int] output value in RGBA format
  Stream<int> applyAsStream(List<int> data,
      [InterpolationType intType]) async* {
    final fun = _typedFunction[intType];

    final dKR = domainMax.r - domainMin.r;
    final dKG = domainMax.g - domainMin.g;
    final dKB = domainMax.b - domainMin.b;

    if (data != null && data.length >= 4) {
      for (var i = 0; i < data.length; i += 4) {
        final RGB rgb = fun(data[i], data[i + 1], data[i + 2]);

        yield _intRGBA(_toIntCh(rgb.r * dKR), _toIntCh(rgb.g * dKG),
            _toIntCh(rgb.b * dKB), bpc);
      }
    }
  }

  int _intRGBA(int r, int g, int b, int a) => a << 24 | b << 16 | g << 8 | r;

  double _k;

  int _toIntCh(double x) => _clampToChannelSize((x * bpc).floor());
  int _clampToChannelSize(int x) => x.clamp(0, bpc).floor();

  RGB _getFromRGBTrilinear(int r, int g, int b) {
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

    final c000 = table3D.get(fR0, fG0, fB0);
    final c010 = table3D.get(fR0, fG1, fB0);
    final c001 = table3D.get(fR0, fG0, fB1);
    final c011 = table3D.get(fR0, fG1, fB1);
    final c101 = table3D.get(fR1, fG0, fB1);
    final c100 = table3D.get(fR1, fG0, fB0);
    final c110 = table3D.get(fR1, fG1, fB0);
    final c111 = table3D.get(fR1, fG1, fB1);

    final rx = Interpolation.trilerp(iR, iG, iB, c000.r, c001.r, c010.r, c011.r,
        c100.r, c101.r, c110.r, c111.r, fR0, fR1, fG0, fG1, fB0, fB1);

    final gx = Interpolation.trilerp(iR, iG, iB, c000.g, c001.g, c010.g, c011.g,
        c100.g, c101.g, c110.g, c111.g, fR0, fR1, fG0, fG1, fB0, fB1);

    final bx = Interpolation.trilerp(iR, iG, iB, c000.b, c001.b, c010.b, c011.b,
        c100.b, c101.b, c110.b, c111.b, fR0, fR1, fG0, fG1, fB0, fB1);

    return RGB(rx, gx, bx);
  }
}
