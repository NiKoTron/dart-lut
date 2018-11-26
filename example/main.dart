import 'dart:io';

import 'package:dart_lut/src/lut.dart';
import 'package:image/image.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('lut-file', abbr: 'l', allowMultiple: false)
    ..addOption('in-img', abbr: 'i', allowMultiple: true)
    ..addOption('out-dir', abbr: 'o', defaultsTo: 'out', allowMultiple: false);

  _run(parser.parse(args));
}

void _run(final ArgResults argResult) {
  for (var img in argResult['in-img']) {
    final imageFile = new File(img);

    final lutFile = new File(argResult['lut-file']);

    var l = LUT.fromFile(lutFile);

    l.isLoaded.listen((data) async {
      Image image = decodeImage(imageFile.readAsBytesSync());
      final sw = Stopwatch()..start();
      var interp = InterpolationType.trilinear;
      var v = l.applySync(image.getBytes(), interp);

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