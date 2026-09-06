import 'formats.dart';
import 'models.dart';

/// ============================================================
/// 内置【视频】输出格式清单。
/// 想加一种视频格式：复制下面任意一个 FormatPreset 改参数即可。
/// 每个 preset 的 buildArgs 决定 FFmpeg 编码命令，
/// 参数含义已写在 buildArgs 的中文注释里。
/// ============================================================

final List<FormatPreset> videoPresets = [
  FormatPreset(
    id: 'mp4_h264',
    kind: MediaKind.video,
    name: 'MP4',
    extension: 'mp4',
    description: '最通用：手机 / 电脑 / 网页都能播（H.264）',
    fields: const [fieldResolution, fieldVideoQuality],
    buildArgs: (s) {
      // -crf：H.264 恒定质量参数，数字越小越清晰、文件越大
      final args = <String>[
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', '${videoQualityCrf(s)}',
        '-pix_fmt', 'yuv420p', // 保证全平台兼容的像素格式
      ];
      appendScale(args, s);
      args.addAll([
        '-c:a', 'aac', // 音频统一转成 AAC
        '-b:a', '128k',
        '-movflags', '+faststart', // 优化网页/流媒体边下边播
      ]);
      return args;
    },
  ),
  FormatPreset(
    id: 'mp4_hevc',
    kind: MediaKind.video,
    name: 'MP4 (HEVC)',
    extension: 'mp4',
    description: 'H.265 编码：同画质体积更小，老设备可能播不了',
    fields: const [fieldResolution, fieldVideoQuality],
    buildArgs: (s) {
      final args = <String>[
        '-c:v', 'libx265',
        '-crf', '${videoQualityCrf(s)}',
        '-pix_fmt', 'yuv420p',
        '-tag:v', 'hvc1', // 让苹果系设备也能识别 HEVC
      ];
      appendScale(args, s);
      args.addAll(['-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart']);
      return args;
    },
  ),
  FormatPreset(
    id: 'mkv_hevc',
    kind: MediaKind.video,
    name: 'MKV',
    extension: 'mkv',
    description: 'Matroska 封装：适合收藏（H.265）',
    fields: const [fieldResolution, fieldVideoQuality],
    buildArgs: (s) {
      final args = <String>[
        '-c:v', 'libx265',
        '-crf', '${videoQualityCrf(s)}',
        '-pix_fmt', 'yuv420p',
      ];
      appendScale(args, s);
      args.addAll(['-c:a', 'aac', '-b:a', '128k']);
      return args;
    },
  ),
  FormatPreset(
    id: 'avi_xvid',
    kind: MediaKind.video,
    name: 'AVI',
    extension: 'avi',
    description: '老式兼容格式（Xvid），适合老设备 / 老软件',
    fields: const [fieldResolution, fieldVideoQuality],
    buildArgs: (s) {
      final args = <String>['-c:v', 'libxvid', '-q:v', '4'];
      appendScale(args, s);
      args.addAll(['-c:a', 'libmp3lame', '-b:a', '128k']);
      return args;
    },
  ),
  FormatPreset(
    id: 'mov_h264',
    kind: MediaKind.video,
    name: 'MOV',
    extension: 'mov',
    description: 'Apple QuickTime 格式（H.264）',
    fields: const [fieldResolution, fieldVideoQuality],
    buildArgs: (s) {
      final args = <String>[
        '-c:v', 'libx264',
        '-crf', '${videoQualityCrf(s)}',
        '-pix_fmt', 'yuv420p',
      ];
      appendScale(args, s);
      args.addAll(['-c:a', 'aac', '-b:a', '128k']);
      return args;
    },
  ),
  FormatPreset(
    id: 'webm_vp9',
    kind: MediaKind.video,
    name: 'WebM',
    extension: 'webm',
    description: '网页通用（VP9 + Opus），压缩率高',
    fields: const [fieldResolution, fieldVideoQuality],
    buildArgs: (s) {
      // VP9：码率必须为 0，用 CRF 控制质量（值越大越省空间）
      final crf = switch (s.of(SettingKey.videoQuality)) {
        '画质优先' => 28,
        '体积优先' => 40,
        _ => 34,
      };
      final args = <String>[
        '-c:v', 'libvpx-vp9',
        '-crf', '$crf',
        '-b:v', '0',
        '-row-mt', '1',
      ];
      appendScale(args, s);
      args.addAll(['-c:a', 'libopus', '-b:a', '96k']);
      return args;
    },
  ),
  FormatPreset(
    id: 'flv_h264',
    kind: MediaKind.video,
    name: 'FLV',
    extension: 'flv',
    description: '老式流媒体格式（H.264），兼容老播放器',
    fields: const [fieldResolution, fieldVideoQuality],
    buildArgs: (s) {
      final args = <String>[
        '-c:v', 'libx264',
        '-crf', '${videoQualityCrf(s)}',
        '-pix_fmt', 'yuv420p',
      ];
      appendScale(args, s);
      args.addAll(['-c:a', 'aac', '-b:a', '128k', '-f', 'flv']);
      return args;
    },
  ),
  FormatPreset(
    id: '3gp_h264',
    kind: MediaKind.video,
    name: '3GP',
    extension: '3gp',
    description: '老手机视频格式，体积小画质一般',
    fields: const [fieldResolution],
    buildArgs: (s) {
      final args = <String>[
        '-c:v', 'libx264',
        '-profile:v', 'baseline', // 老设备兼容性最好的编码配置档
        '-level', '3.0',
      ];
      appendScale(args, s);
      args.addAll(['-c:a', 'aac', '-b:a', '64k']);
      return args;
    },
  ),
  FormatPreset(
    id: 'gif_anim',
    kind: MediaKind.video,
    name: 'GIF',
    extension: 'gif',
    description: '转成 GIF 动图（文件偏大）',
    fields: const [fieldResolution],
    buildArgs: (s) {
      // 抽帧降到 12fps 以减小体积
      final vfParts = <String>['fps=12'];
      final vf = resolutionToVf(s);
      if (vf != null) vfParts.add(vf);
      final args = <String>['-vf', vfParts.join(',')];
      args.addAll(['-c:v', 'gif']);
      return args;
    },
  ),
];
