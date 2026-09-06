import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// 应用图标生成器（Flutter 渲染，程序化生成，无外部图片工具依赖）。
///
/// 运行：flutter test tool/generate_icons.dart
/// 设计：深青渐变圆角底 + 白色"⇄ 双换向箭头"（寓意格式转换/互转）。
/// 输出会直接覆盖 android/app/src/main/res 下的 mipmap 图标资源。
/// 已从 test/ 移出，普通 `flutter test` 不会执行它。
void main() async {
  await generateIcons();
}

// 品牌渐变与箭头颜色
const int _cTop = 0xFF00695C; // 深青（teal 800）
const int _cBottom = 0xFF26A69A; // 青（teal 400）
const int _cArrow = 0xFFFFFFFF; // 白色箭头
const int _cBg = 0xFF00695C; // 自适应背景纯色

const List<(String, int)> _dpiLegacy = [
  ('mipmap-mdpi', 48),
  ('mipmap-hdpi', 72),
  ('mipmap-xhdpi', 96),
  ('mipmap-xxhdpi', 144),
  ('mipmap-xxxhdpi', 192),
];

const List<(String, int)> _dpiForeground = [
  ('mipmap-mdpi', 108),
  ('mipmap-hdpi', 162),
  ('mipmap-xhdpi', 216),
  ('mipmap-xxhdpi', 324),
  ('mipmap-xxxhdpi', 432),
];

Future<void> generateIcons() async {
  final root = Directory('android/app/src/main/res');
  for (final (dir, size) in _dpiLegacy) {
    final img = await _render(size, legacyStyle: true);
    await _writePng(
      File('${root.path}/$dir/ic_launcher.png'),
      img,
    );
  }
  for (final (dir, size) in _dpiForeground) {
    final img = await _render(size, legacyStyle: false);
    await _writePng(
      File('${root.path}/$dir/ic_launcher_foreground.png'),
      img,
    );
  }

  // 自适应图标资源（values 颜色 + anydpi-v26 xml）
  final colors = File('${root.path}/values/colors.xml');
  await colors.writeAsString('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${'#'}${_cBg.toRadixString(16).padLeft(8, '0').substring(2)}</color>
</resources>
''');
  final anydpi = Directory('${root.path}/mipmap-anydpi-v26');
  if (!anydpi.existsSync()) await anydpi.create(recursive: true);
  await File('${anydpi.path}/ic_launcher.xml').writeAsString('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''');
  // ignore: avoid_print
  print('图标已生成到 $root');
}

Future<ui.Image> _render(int size, {required bool legacyStyle}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  if (legacyStyle) {
    // 圆角底 + 渐变
    canvas.clipRRect(ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      ui.Radius.circular(size * 0.20),
    ));
    final paint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, 0),
        ui.Offset(0, size.toDouble()),
        const [ui.Color(_cTop), ui.Color(_cBottom)],
      );
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint,
    );
    _drawArrows(canvas, size.toDouble(), size * 0.60);
  } else {
    // 自适应前景：透明背景 + 居中白色箭头（预留遮罩安全区）
    _drawArrows(canvas, size.toDouble(), size * 0.46);
  }

  return recorder.endRecording().toImage(size, size);
}

void _drawArrows(ui.Canvas canvas, double s, double l) {
  final cx = s * 0.5;
  final strokeW = l * 0.085;
  final halfH = l * 0.13;
  final yTop = s * 0.5 - l * 0.16;
  final yBottom = s * 0.5 + l * 0.16;

  final stroke = ui.Paint()
    ..color = const ui.Color(_cArrow)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;

  final fill = ui.Paint()
    ..color = const ui.Color(_cArrow)
    ..style = ui.PaintingStyle.fill;

  // 上箭头 → 左
  canvas.drawLine(
    ui.Offset(cx + l * 0.32, yTop),
    ui.Offset(cx - l * 0.14, yTop),
    stroke,
  );
  final headUp = ui.Path()
    ..moveTo(cx - l * 0.06, yTop - halfH)
    ..lineTo(cx - l * 0.42, yTop)
    ..lineTo(cx - l * 0.06, yTop + halfH)
    ..close();
  canvas.drawPath(headUp, fill);

  // 下箭头 → 右
  canvas.drawLine(
    ui.Offset(cx - l * 0.32, yBottom),
    ui.Offset(cx + l * 0.14, yBottom),
    stroke,
  );
  final headDown = ui.Path()
    ..moveTo(cx + l * 0.06, yBottom - halfH)
    ..lineTo(cx + l * 0.42, yBottom)
    ..lineTo(cx + l * 0.06, yBottom + halfH)
    ..close();
  canvas.drawPath(headDown, fill);
}

Future<void> _writePng(File file, ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = data!.buffer.asUint8List();
  file.writeAsBytesSync(bytes);
}
