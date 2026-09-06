import 'formats.dart';
import 'formats_audio_data.dart';
import 'formats_image_data.dart';
import 'formats_video_data.dart';
import 'models.dart';

/// ============================================================
/// 按媒体类别取"该类别支持的输出格式清单"。
///
/// 视频格式清单在  formats_video_data.dart
/// 音频格式清单在  formats_audio_data.dart
/// 图片格式清单在  formats_image_data.dart
/// 想加格式就打开对应文件，照着现有一条复制修改即可。
/// ============================================================
List<FormatPreset> presetsFor(MediaKind kind) => switch (kind) {
      MediaKind.video => videoPresets,
      MediaKind.audio => audioPresets,
      MediaKind.image => imagePresets,
    };

/// 按 id 在某个类别里找格式（找不到返回 null，调用方应兜底）。
FormatPreset? presetById(MediaKind kind, String id) {
  for (final p in presetsFor(kind)) {
    if (p.id == id) return p;
  }
  return null;
}
