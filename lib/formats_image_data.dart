import 'formats.dart';
import 'models.dart';

/// ============================================================
/// 内置【图片】输出格式清单。添加格式同样复制一条改参数即可。
/// ============================================================

final List<FormatPreset> imagePresets = [
  FormatPreset(
    id: 'img_jpg',
    kind: MediaKind.image,
    name: 'JPG',
    extension: 'jpg',
    description: '通用照片格式，体积小（有损压缩）',
    fields: const [fieldResolution, fieldImageQuality],
    buildArgs: (s) {
      final q = imageQualityOf(s);
      final args = <String>['-frames:v', '1']; // 只要第一帧（GIF 输入时有用）
      appendScale(args, s);
      args.addAll(['-c:v', 'mjpeg', '-q:v', '${q.jpegQ}']);
      return args;
    },
  ),
  FormatPreset(
    id: 'img_png',
    kind: MediaKind.image,
    name: 'PNG',
    extension: 'png',
    description: '无损格式，支持透明通道',
    fields: const [fieldResolution],
    buildArgs: (s) {
      final args = <String>['-frames:v', '1'];
      appendScale(args, s);
      args.addAll(['-c:v', 'png']);
      return args;
    },
  ),
  FormatPreset(
    id: 'img_webp',
    kind: MediaKind.image,
    name: 'WebP',
    extension: 'webp',
    description: '现代网页图片格式，体积小',
    fields: const [fieldResolution, fieldImageQuality],
    buildArgs: (s) {
      final q = imageQualityOf(s);
      final args = <String>['-frames:v', '1'];
      appendScale(args, s);
      args.addAll(['-c:v', 'libwebp', '-quality', '${q.webpQ}']);
      return args;
    },
  ),
  FormatPreset(
    id: 'img_bmp',
    kind: MediaKind.image,
    name: 'BMP',
    extension: 'bmp',
    description: '老式位图格式，体积极大',
    fields: const [fieldResolution],
    buildArgs: (s) {
      final args = <String>['-frames:v', '1'];
      appendScale(args, s);
      args.addAll(['-c:v', 'bmp']);
      return args;
    },
  ),
  FormatPreset(
    id: 'img_tiff',
    kind: MediaKind.image,
    name: 'TIFF',
    extension: 'tiff',
    description: '印刷 / 扫描常用无损格式',
    fields: const [fieldResolution],
    buildArgs: (s) {
      final args = <String>['-frames:v', '1'];
      appendScale(args, s);
      args.addAll(['-c:v', 'tiff']);
      return args;
    },
  ),
  FormatPreset(
    id: 'img_gif',
    kind: MediaKind.image,
    name: 'GIF',
    extension: 'gif',
    description: '简单动图格式；静态图会转成单帧',
    fields: const [fieldResolution],
    buildArgs: (s) {
      final vfParts = <String>['fps=12'];
      final vf = resolutionToVf(s);
      if (vf != null) vfParts.add(vf);
      final args = <String>['-vf', vfParts.join(',')];
      args.addAll(['-c:v', 'gif']);
      return args;
    },
  ),
];
