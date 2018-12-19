# Dart LUT3D

[![pub package][pub-badge]][pub-repo]

The library for working with LUTs.

## License

project under MIT [license][license]

## Changelogs

[full changelog][changelog]

### Task List

- [x] Basic impl.
- [x] Read .cube files
- [ ] Read another formats
- [x] Store 3DLUT
- [ ] Generate LUTs by expression
- [ ] Verifying LUTs
- [x] Applying 3D LUTs
- [ ] Applying 1D LUTs
- [ ] Optimize perfomance
- [ ] Clean up code
- [x] Trilinear interpolation
- [ ] More tests
- [ ] Documentation
- [x] Publish to [PUB][pub-repo]

## 0.0.2

- remove .fromFile(File f) factory

## Instalation

add dependency in pubsec.yaml

from [pub.dartlang.org][pub-repo]:

```yaml
dependencies:
  dart_lut: ^0.0.3
```

latest from [github.com][github-repo]:

```yaml
dependencies:
  dart_lut:
      git: git://github.com/NiKoTron/dart-lut.git
```

## Usage

generic example:

```dart
import 'dart:io';

import 'package:image/image.dart';
import 'package:dart_lut/src/lut.dart';
```
```dart
final lut = LUT.fromString(File('example.cube').readAsStringSync());
await lut.awaitLoading();

Image image = decodeImage(imageFile.readAsBytesSync());

var lutedBytes = lut.applySync(image.getBytes());

var imageLUT = Image.fromBytes(image.width, image.height, lutedBytes);
var outputFile = File('out.jpg')..writeAsBytesSync(encodeJpg(imageLUT));
```

```dart
lut.applyAsStream(image.getBytes()).listen((result) {
  print('#${result.toRadixString(16).padLeft(4, '0')}'); //print ARGB value after applying LUT in HEX format
});
```

## Sample results

![Photo by Caique Silva on Unsplash][caique-silva-preview]

*image by [Caique Silva][caique-silva-page] LUTs: KURO B&W by [David Morgan Jones][david-morgan-jones-bw-free], Arabica 12 and Lenox 340 by [rocketstock][rocket-stock-35-free]*

![Photo by sean Kong on Unsplash][sean-kong-preview]

*image by [sean Kong][sean-kong-page] LUTs: KURO B&W by [David Morgan Jones][david-morgan-jones-bw-free], Arabica 12 and Lenox 340 by [rocketstock][rocket-stock-35-free]*

[license]: LICENSE
[changelog]: CHANGELOG.md
[pub-repo]: https://pub.dartlang.org/packages/dart_lut
[pub-badge]: https://img.shields.io/pub/v/dart_lut.svg
[github-repo]: https://github.com/NiKoTron/dart-lut

[caique-silva-preview]: img/caique-silva-merge-small.jpg "Photo by Caique Silva on Unsplash"
[caique-silva-page]: https://unsplash.com/@caiqueportraits?utm_medium=referral&utm_campaign=photographer-credit&utm_content=creditBadge

[sean-kong-preview]: img/sean-kong-merged-small.jpg "Photo by sean Kong on Unsplash"
[sean-kong-page]: https://unsplash.com/@seankkkkkkkkkkkkkk?utm_medium=referral&utm_campaign=photographer-credit&utm_content=creditBadge

[david-morgan-jones-bw-free]: https://davidmorganjones.net/blog/kuro-lut-free-dramatic-black-and-white-lut/
[rocket-stock-35-free]: https://www.rocketstock.com/free-after-effects-templates/35-free-luts-for-color-grading-videos/
