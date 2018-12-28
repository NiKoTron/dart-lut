import 'dart:async';
import 'dart:typed_data';

import 'package:dart_lut/src/interpolation.dart';
import 'package:dart_lut/src/colour.dart';
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

  int _sizeOf3DTable = -1;

  Table3D<Colour> table3D;

  /// The minimum domain value
  Colour domainMin;

  /// The maximum domain value
  Colour domainMax;

  /// The bits per channel
  /// Default value is [Depth.bit8]
  int bpc = Depth.bit8;

  final Stream<String> _stream;

  final StreamController<bool> _isLoadedStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get isLoaded => _isLoadedStreamController.stream;

  bool _isLoaded = false;

  Future<bool> awaitLoading() async {
    if (_isLoadedStreamController.isClosed) {
      return _isLoaded;
    }
    try {
      await for (bool val in isLoaded) {
        _isLoaded = val;
        break;
      }
    } on FormatException {
      _isLoaded = false;
    }

    return _isLoaded;
  }

  final Map<InterpolationType, Function> _typedFunction = new Map();

  LUT._() : this._stream = null;

  LUT._fromStream(this._stream) {
    _typedFunction[InterpolationType.trilinear] = _getFromRGBTrilinear;

    _lutTransformer = StreamTransformer<String, LUT>(_onStringStreamListen);

    _stream
        .transform(_lutTransformer)
        .listen(null)
        .onError(_isLoadedStreamController.sink.addError);

    isLoaded.listen((v) => _isLoaded = v,
        onError: (Object e) => _isLoaded = false,
        onDone: () => _isLoadedStreamController.close());
  }

  /// This factory creating LUT from string
  factory LUT.fromString(String str) {
    return LUT._fromStream(Stream.fromIterable(str.split('\n')));
  }

  factory LUT.linear(int size,
      [Colour domainMax = const Colour(1, 1, 1),
      Colour domainMin = const Colour(0, 0, 0)]) {
    final lut = LUT._()
      ..domainMax = domainMax
      ..domainMin = domainMin
      .._sizeOf3DTable = size
      ..table3D = Table3D(size);

    final ln = size * size * size;

    final drs = (domainMax.r - domainMin.r) / (size - 1);
    final dgs = (domainMax.g - domainMin.g) / (size - 1);
    final dbs = (domainMax.b - domainMin.b) / (size - 1);

    var r = domainMin.r;
    var g = domainMin.r;
    var b = domainMin.r;

    for (var i = 0; i < ln; i++) {
      final c = Colour(r, g, b);
      lut.table3D.tbl[i] = c;

      r += drs;
      if (r > domainMax.r) {
        r = 0;
        g += dgs;
        if (g > domainMax.g) {
          g = 0;
          b += dbs;
        }
      }
    }

    return lut;
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
        onCancel: () {
          subscription.cancel();
        },
        sync: true);
    var hasErrors = false;
    subscription = _stream.listen(
        (s) {
          try {
            if (_sizeOf3DTable <= 0) {
              if (title == null || title.isEmpty) {
                title = _readTitle(s);
              }
              if (_sizeOf3DTable < 0) {
                _sizeOf3DTable = _read3DLUTSize(s);
                if (_sizeOf3DTable >= 2) {
                  _k = (_sizeOf3DTable - 1) / bpc;
                  table3D = Table3D(_sizeOf3DTable);
                }
              }
              domainMin ??= _readDomainMin(s);
              domainMax ??= _readDomainMax(s);
            } else {
              final rgb = _readRGB(s);
              if (rgb != null) {
                table3D.set(x, y, z, rgb);

                x++;
                if (x == _sizeOf3DTable) {
                  x = 0;
                  y++;
                }
                if (y == _sizeOf3DTable) {
                  y = 0;
                  z++;
                }
              }
            }
          } on FormatException catch (e) {
            hasErrors = true;
            controller.addError(e);
          }
        },
        onError: controller.addError,
        onDone: () {
          controller.close();
          if (!_isLoadedStreamController.isClosed) {
            domainMin ??= Colour(0, 0, 0);
            domainMax ??= Colour(1, 1, 1);
            _isLoadedStreamController.sink.add(!hasErrors &&
                _sizeOf3DTable >= 2 &&
                table3D != null &&
                table3D.size == _sizeOf3DTable);
            _isLoadedStreamController.close();
          }
        },
        cancelOnError: true);

    return controller.stream.listen(null);
  }

  static final String PARSE_COMMENT_LINE = '#';

  static final String HEADER_LUT_3D_SIZE = 'LUT_3D_SIZE';
  static final String PATTERN_LUT_3D_SIZE =
      r'^' + HEADER_LUT_3D_SIZE + r'\s+(\d+)';

  static final String HEADER_DOMAIN_MIN = 'DOMAIN_MIN';
  static final String PATTERN_DOMAIN_MIN = r'^' +
      HEADER_DOMAIN_MIN +
      r'\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)';

  static final String HEADER_DOMAIN_MAX = 'DOMAIN_MAX';
  static final String PATTERN_DOMAIN_MAX = r'^' +
      HEADER_DOMAIN_MAX +
      r'\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)\s+(\d+.\d+|\d+|.\d+)';

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
    if (!s.startsWith(PARSE_COMMENT_LINE) && s.startsWith(HEADER_LUT_3D_SIZE)) {
      final exp = RegExp(PATTERN_LUT_3D_SIZE);
      if (exp.hasMatch(s)) {
        final size = int.tryParse(exp.firstMatch(s).group(1));
        if (size == null) {
          throw FormatException('Size can`t parse to integer value: "$s"');
        }
        return size;
      } else {
        throw FormatException('Wrong value: "$s"');
      }
    }
    return -1;
  }

  static Colour _readDomainMin(String s) {
    if (!s.startsWith(PARSE_COMMENT_LINE) && s.startsWith(HEADER_DOMAIN_MIN)) {
      final expInputRange = RegExp(PATTERN_DOMAIN_MIN);
      if (expInputRange.hasMatch(s)) {
        final r = _validateAndParse(expInputRange.firstMatch(s).group(1));
        final g = _validateAndParse(expInputRange.firstMatch(s).group(2));
        final b = _validateAndParse(expInputRange.firstMatch(s).group(3));

        return Colour(r, g, b);
      } else {
        throw FormatException('Wrong value: "$s"');
      }
    }
    return null;
  }

  static Colour _readDomainMax(String s) {
    if (!s.startsWith(PARSE_COMMENT_LINE) && s.startsWith(HEADER_DOMAIN_MAX)) {
      final expInputRange = RegExp(PATTERN_DOMAIN_MAX);
      if (expInputRange.hasMatch(s)) {
        final r = _validateAndParse(expInputRange.firstMatch(s).group(1));
        final g = _validateAndParse(expInputRange.firstMatch(s).group(2));
        final b = _validateAndParse(expInputRange.firstMatch(s).group(3));

        return Colour(r, g, b);
      } else {
        throw FormatException('Wrong value: "$s"');
      }
    }
    return null;
  }

  static Colour _readRGB(String s,
      [Colour domainMin = const Colour(0, 0, 0),
      Colour domainMax = const Colour(1, 1, 1)]) {
    if (!s.startsWith(PARSE_COMMENT_LINE)) {
      final expInputRange = RegExp(PATTERN_DATA);
      if (expInputRange.hasMatch(s)) {
        final r = _validateAndParse(
            expInputRange.firstMatch(s).group(1), domainMin.r, domainMax.r);
        final g = _validateAndParse(
            expInputRange.firstMatch(s).group(2), domainMin.g, domainMax.g);
        final b = _validateAndParse(
            expInputRange.firstMatch(s).group(3), domainMin.b, domainMax.b);

        return Colour(r, g, b);
      } else if (s.isNotEmpty) {
        throw FormatException('Wrong format of input data: "$s"');
      }
    }
    return null;
  }

  static double _validateAndParse(String s, [double min, double max]) {
    if (s == null || s.isEmpty) {
      throw FormatException('Input data shouldn`t be empty or null: "$s"');
    }
    final value = double.tryParse(s);
    if (value == null) {
      throw FormatException('Input data can`t parsed as a double value: "$s"');
    }
    if ((min != null && max != null) && (value < min || value > max)) {
      throw FormatException(
          'Input data not in range: [$min <= $value <= $max]');
    }
    return value;
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
        final Colour rgb = fun(data[i], data[i + 1], data[i + 2]);

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
        final Colour rgb = fun(data[i], data[i + 1], data[i + 2]);

        yield _intRGBA(_toIntCh(rgb.r * dKR), _toIntCh(rgb.g * dKG),
            _toIntCh(rgb.b * dKB), bpc);
      }
    }
  }

  int _intRGBA(int r, int g, int b, int a) => a << 24 | b << 16 | g << 8 | r;

  // The depth coefficient - (sizeOf3DTable - 1) / bitPerChannel
  double _k;

  int _toIntCh(double x) => _clampToChannelSize((x * bpc).floor());
  int _clampToChannelSize(int x) => x.clamp(0, bpc).floor();

  Colour _getFromRGBTrilinear(int r, int g, int b) {
    final iR = (r * _k);
    final fR1 = iR >= _sizeOf3DTable - 1
        ? _clampToChannelSize(_sizeOf3DTable - 1)
        : _clampToChannelSize((iR + 1).floor());
    final fR0 = iR <= 0 ? 0 : _clampToChannelSize((iR - 1).floor());

    final iG = (g * _k);
    final fG1 = iG >= _sizeOf3DTable - 1
        ? _clampToChannelSize(_sizeOf3DTable - 1)
        : _clampToChannelSize((iG + 1).floor());
    final fG0 = iG <= 0 ? 0 : _clampToChannelSize((iG - 1).floor());

    final iB = (b * _k);
    final fB1 = iB >= _sizeOf3DTable - 1
        ? _clampToChannelSize(_sizeOf3DTable - 1)
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

    return Colour(rx, gx, bx);
  }
}
