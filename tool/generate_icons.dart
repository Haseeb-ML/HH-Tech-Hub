import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('assets/logo.png');
  if (!logoFile.existsSync()) {
    print('assets/logo.png not found!');
    return;
  }

  final logoBytes = logoFile.readAsBytesSync();
  final rawLogo = img.decodePng(logoBytes);
  if (rawLogo == null) {
    print('Failed to decode assets/logo.png');
    return;
  }

  print('Original logo dimensions: ${rawLogo.width}x${rawLogo.height}');

  // Dimensions for legacy ic_launcher.png
  final legacySizes = {
    'android/app/src/main/res/mipmap-mdpi': 48,
    'android/app/src/main/res/mipmap-hdpi': 72,
    'android/app/src/main/res/mipmap-xhdpi': 96,
    'android/app/src/main/res/mipmap-xxhdpi': 144,
    'android/app/src/main/res/mipmap-xxxhdpi': 192,
  };

  // Dimensions for adaptive foreground ic_launcher_foreground.png
  final adaptiveSizes = {
    'android/app/src/main/res/mipmap-mdpi': 108,
    'android/app/src/main/res/mipmap-hdpi': 162,
    'android/app/src/main/res/mipmap-xhdpi': 216,
    'android/app/src/main/res/mipmap-xxhdpi': 324,
    'android/app/src/main/res/mipmap-xxxhdpi': 432,
  };

  // 1. Generate legacy ic_launcher.png
  // White solid background with logo centered at ~76% width/height for circular safe zone
  for (final entry in legacySizes.entries) {
    final dirPath = entry.key;
    final size = entry.value;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Create solid white square canvas
    final canvas = img.Image(width: size, height: size);
    img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

    // Logo size: 76% of canvas to be safely inside circle/squircle masks
    final maxLogoDimension = (size * 0.76).round();
    int targetW, targetH;
    if (rawLogo.width >= rawLogo.height) {
      targetW = maxLogoDimension;
      targetH = (rawLogo.height * (maxLogoDimension / rawLogo.width)).round();
    } else {
      targetH = maxLogoDimension;
      targetW = (rawLogo.width * (maxLogoDimension / rawLogo.height)).round();
    }

    final resizedLogo = img.copyResize(
      rawLogo,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.cubic,
    );

    final dstX = (size - targetW) ~/ 2;
    final dstY = (size - targetH) ~/ 2;

    img.compositeImage(canvas, resizedLogo, dstX: dstX, dstY: dstY);

    final outPng = img.encodePng(canvas);
    File('$dirPath/ic_launcher.png').writeAsBytesSync(outPng);
    File('$dirPath/ic_launcher_round.png').writeAsBytesSync(outPng);
    print('Generated $dirPath/ic_launcher.png & ic_launcher_round.png ($size x $size)');
  }

  // 2. Generate adaptive foreground ic_launcher_foreground.png
  // Transparent canvas of size adaptiveSize, logo in safe center (around 56% size)
  for (final entry in adaptiveSizes.entries) {
    final dirPath = entry.key;
    final size = entry.value;

    final canvas = img.Image(width: size, height: size, numChannels: 4);
    // transparent fill
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

    // Adaptive icon safe zone is 66dp of 108dp (~60%)
    final maxLogoDimension = (size * 0.60).round();
    int targetW, targetH;
    if (rawLogo.width >= rawLogo.height) {
      targetW = maxLogoDimension;
      targetH = (rawLogo.height * (maxLogoDimension / rawLogo.width)).round();
    } else {
      targetH = maxLogoDimension;
      targetW = (rawLogo.width * (maxLogoDimension / rawLogo.height)).round();
    }

    final resizedLogo = img.copyResize(
      rawLogo,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.cubic,
    );

    final dstX = (size - targetW) ~/ 2;
    final dstY = (size - targetH) ~/ 2;

    img.compositeImage(canvas, resizedLogo, dstX: dstX, dstY: dstY);

    final outPng = img.encodePng(canvas);
    File('$dirPath/ic_launcher_foreground.png').writeAsBytesSync(outPng);
    print('Generated $dirPath/ic_launcher_foreground.png ($size x $size)');
  }

  // 3. Create values/colors.xml if needed
  final valuesDir = Directory('android/app/src/main/res/values');
  if (!valuesDir.existsSync()) valuesDir.createSync(recursive: true);
  final colorsFile = File('android/app/src/main/res/values/colors.xml');
  if (!colorsFile.existsSync()) {
    colorsFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
''');
    print('Created colors.xml');
  } else {
    var content = colorsFile.readAsStringSync();
    if (!content.contains('ic_launcher_background')) {
      content = content.replaceFirst('</resources>', '    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>');
      colorsFile.writeAsStringSync(content);
      print('Updated colors.xml with ic_launcher_background');
    }
  }

  // 4. Create mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml
  final anyDpiDir = Directory('android/app/src/main/res/mipmap-anydpi-v26');
  if (!anyDpiDir.existsSync()) anyDpiDir.createSync(recursive: true);

  const adaptiveIconContent = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:color="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''';

  final adaptiveXml = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml');
  adaptiveXml.writeAsStringSync(adaptiveIconContent);

  final adaptiveRoundXml = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml');
  adaptiveRoundXml.writeAsStringSync(adaptiveIconContent);

  print('Created mipmap-anydpi-v26/ic_launcher.xml & ic_launcher_round.xml');
  print('ALL LAUNCHER ICONS (STANDARD & ROUND) GENERATED SUCCESSFULLY!');
}
