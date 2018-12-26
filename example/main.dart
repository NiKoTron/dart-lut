import 'dart:io';

import 'package:dart_lut/src/lut.dart';
import 'package:image/image.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('lut-file', abbr: 'l')
    ..addOption('in-img', abbr: 'i')
    ..addOption('out-dir', abbr: 'o', defaultsTo: './out');

  _run(parser.parse(args));
}

void _run(final ArgResults argResult) {
  for (var img in argResult['in-img']) {
    final imageFile = File(img);

    final lutFile = File(argResult['lut-file']);

    final lut = LUT.fromString(lutFile.readAsStringSync());

    lut.isLoaded.listen((data) async {
      final image = decodeImage(imageFile.readAsBytesSync());
      final sw = Stopwatch()..start();
      final interp = InterpolationType.trilinear;

      final v = lut.applySync(image.getBytes(), interp);

      print('lut apply in ${sw.elapsed}');
      sw.stop();
      final image2 = Image.fromBytes(image.width, image.height, v);
      final outputFile = new File(
          '${argResult['out-dir']}/${path.basename(imageFile.path)}_${path.basename(lutFile.path)}_$interp.jpg')
        ..writeAsBytesSync(encodeJpg(image2));
      print('output image write to: ${outputFile.path}');
    });
  }
}

void _runStreamed(final ArgResults argResult) async {
  for (var img in argResult['in-img']) {
    final imageFile = File(img);

    final lutFile = File(argResult['lut-file']);

    final lut = LUT.fromString(lutFile.readAsStringSync());

    final isLoaded = await lut.awaitLoading();
    if (isLoaded) {
      final image = decodeImage(imageFile.readAsBytesSync());
      final interp = InterpolationType.trilinear;
      lut.applyAsStream(image.getBytes(), interp).listen((result) {
        //print('#${result.toRadixString(16).padLeft(4, '0')}');
      });
    }
    ;
  }
}
