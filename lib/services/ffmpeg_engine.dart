import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';

import '../formats_data.dart';
import '../models.dart';

/// FFmpeg 执行引擎：负责把"任务"翻译成一条 FFmpeg 命令，
/// 并校验底层 FFmpeg 二进制是否就绪。
///
/// 真正"跑起来"的动作在 state/task_queue.dart 里做（串行队列调度），
/// 这里只负责命令拼装和就绪检查，保持单一职责、好读好测。
class FfmpegEngine {
  FfmpegEngine._();

  static bool _ready = false;

  /// 校验 FFmpeg 二进制可用（首次会加载原生库，约 1 秒）。
  static Future<bool> ensureReady() async {
    if (_ready) return true;
    try {
      final version = await FFmpegKitConfig.getFFmpegVersion();
      _ready = (version ?? '').isNotEmpty;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// 把任务拼成一条 FFmpeg 命令行字符串。
  ///
  /// 底层引擎支持用引号包裹含空格的路径，这里统一给路径加引号。
  /// 结构：-y -i 输入 [格式自带的编码参数...] 输出
  static String buildCommand(ConvertTask task) {
    final preset = presetById(task.kind, task.presetId);
    final args = preset?.buildArgs(task.settings) ?? const <String>[];
    return [
      '-hide_banner',
      '-y', // 允许覆盖同名输出
      '-i', _quote(task.inputPath),
      ...args,
      _quote(task.outputPath),
    ].join(' ');
  }

  static String _quote(String path) => '"$path"';
}
