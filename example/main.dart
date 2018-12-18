import 'dart:io';

import 'package:dart_lut/src/lut.dart';
import 'package:image/image.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('lut-file', abbr: 'l', allowMultiple: false)
    ..addOption('in-img', abbr: 'i', allowMultiple: true)
    ..addOption('out-dir',
        abbr: 'o', defaultsTo: './out', allowMultiple: false);

  _runStreamed(parser.parse(args));
}

void _run(final ArgResults argResult) {
  for (var img in argResult['in-img']) {
    final imageFile = File(img);

    final lutFile = File(argResult['lut-file']);

    final lut = LUT.fromString(lutFile.readAsStringSync());

    lut.isLoaded.listen((data) async {
      Image image = decodeImage(imageFile.readAsBytesSync());
      final sw = Stopwatch()..start();
      var interp = InterpolationType.trilinear;

      var v = lut.applySync(image.getBytes(), interp);

      print('lut apply in ${sw.elapsed}');
      sw.stop();
      var image2 = Image.fromBytes(image.width, image.height, v);
      var outputFile = new File(
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

    var isLoaded = await lut.awaitLoading();
    if(isLoaded){
      Image image = decodeImage(imageFile.readAsBytesSync());
      var interp = InterpolationType.trilinear;
      lut.applyAsStream(image.getBytes(), interp).listen((result) {
            print('#${result.toRadixString(16).padLeft(4, '0')}');
      });
    };
  }
}
