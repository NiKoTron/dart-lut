import 'dart:io';

import 'package:dart_lut/src/lut_parse.dart';
import 'package:image/image.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('lut-file', abbr: 'l')
    ..addOption('in-img', abbr: 'i')
    ..addOption('out-dir', abbr: 'o', defaultsTo: './out');

    final argsRes = parser.parse(args);

  await _run(argsRes);
}

Future<void> _run(final ArgResults argResult) async {
  var inputs = argResult['in-img'];
  
  if(! (inputs is Iterable)){
    inputs = [inputs];
  }

  for (var img in inputs) {
    final imageFile = File(img);

    final lutPath = argResult['lut-file'];

    final lutFile = File(lutPath);

    final l = await LUTParser.fromString(lutFile.readAsStringSync());

    final lut = LUTProcessor(l);

    final image = decodeImage(imageFile.readAsBytesSync());
    if (image == null) {
      print('Failed to decode image: ${imageFile.path}');
      return;
    }
    final sw = Stopwatch()..start();

    final v = lut.applySync(image.getBytes(order: ChannelOrder.rgba));
    final byteBuffer = Uint8List.fromList(v).buffer;

    print('lut apply in ${sw.elapsed}');
    sw.stop();
    
    final image2 = Image.fromBytes(
      order: ChannelOrder.rgba,
      width: image!.width,
      height: image!.height,
      bytes: byteBuffer,
    );
    final outputFile = new File(
        '${argResult['out-dir']}/${path.basename(imageFile.path)}_${path.basename(lutFile.path)}_tlp.jpg')
      ..writeAsBytesSync(encodeJpg(image2));
    print('output image write to: ${outputFile.path}');
  }
}
