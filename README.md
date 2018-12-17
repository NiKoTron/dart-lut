# Dart LUT3D

The library for working with LUTs.

## License

project under MIT [license][license]

## Changelogs

[full changelog][changelog]

### Task List

- [x] Basic impl.
- [x] Read .cube files
- [x] Read another formats
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
- [ ] Publish to [PUB][pub-repo]

## 0.0.1
- initial release

## Instalation

add dependency in pubsec.yaml

from [pub.dartlang.org][pub-repo]:

```yaml
dependencies:
  dart_lut: ^0.0.1
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
var lut = LUT.fromFile(File('example.cube'));
await lut.awaitLoading();

Image image = decodeImage(imageFile.readAsBytesSync());

var v = lut.applySync(image.getBytes());

var image2 = Image.fromBytes(image.width, image.height, v);
var outputFile = File('out.jpg')..writeAsBytesSync(encodeJpg(image2));
```

[license]: LICENSE
[changelog]: CHANGELOG.md
[pub-repo]: https://pub.dartlang.org/dart_lut
[github-repo]: https://github.com/NiKoTron/dart-lut