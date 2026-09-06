import 'models.dart';

/// ============================================================
/// 格式预设目录 —— "想改支持哪些格式"就看这一个文件。
///
/// 每种目标格式 = 一个 FormatPreset：
///   - name / extension      显示名与扩展名
///   - fields                转换设置页上要展示的参数下拉框
///   - buildArgs             如何把用户设置翻译成 FFmpeg 参数
///
/// 想增加新格式：在 formats_data.dart 里照着现有一条复制即可。
/// 想调整某格式编码参数：改它 buildArgs 里的参数数组。
/// ============================================================

/// 一个可调参数项（在设置页显示为下拉框）。
class OptionField {
  const OptionField(this.key, this.label, this.options, {this.help});

  final SettingKey key;
  final String label;
  final List<String> options;
  final String? help; // 鼠标/悬停时的解释（已用中文写到 UI 上）
}

/// 一个目标格式（视频/音频/图片都适用）。
class FormatPreset {
  const FormatPreset({
    required this.id,
    required this.kind,
    required this.name,
    required this.extension,
    required this.description,
    required this.buildArgs,
    this.fields = const [],
  });

  final String id;
  final MediaKind kind;
  final String name; // 展示名，如 "MP4"
  final String extension; // 输出扩展名，如 "mp4"
  final String description; // 一行说明，展示在卡片上
  final List<OptionField> fields;

  /// 把用户设置翻译成 FFmpeg 参数列表（不含 -i 和输出路径）。
  final List<String> Function(ConvertSettings s) buildArgs;
}

// ---------- 各预设通用的下拉选项 ----------

/// 画面尺寸：数值代表"输出画面最大宽度"，高度按原比例缩放。
const List<String> kResolutionOptions = [
  '原始尺寸',
  '1920 宽',
  '1280 宽',
  '854 宽',
  '640 宽',
];

/// 视频质量档位（对应 libx264/libx265 的 CRF 值，越小越清晰越大）。
const List<String> kVideoQualityOptions = ['画质优先', '推荐', '体积优先'];

const List<String> kAudioBitrateOptions = [
  '自动',
  '320k',
  '256k',
  '192k',
  '128k',
  '96k',
];
const List<String> kSampleRateOptions = ['自动', '48000', '44100'];
const List<String> kChannelsOptions = ['自动', '双声道', '单声道'];
const List<String> kImageQualityOptions = ['高质量', '标准', '小体积'];

// ---------- 各预设都要展示的"参数下拉框"公共定义 ----------
// 名字即含义：resolution=画面尺寸 / video=视频质量 / audio=音频相关 / image=图片质量
const OptionField fieldResolution = OptionField(
    SettingKey.resolution, '画面尺寸', kResolutionOptions);
const OptionField fieldVideoQuality = OptionField(
    SettingKey.videoQuality, '视频质量', kVideoQualityOptions);
const OptionField fieldAudioBitrate = OptionField(
    SettingKey.audioBitrate, '音频码率', kAudioBitrateOptions);
const OptionField fieldSampleRate =
    OptionField(SettingKey.sampleRate, '采样率', kSampleRateOptions);
const OptionField fieldChannels =
    OptionField(SettingKey.channels, '声道', kChannelsOptions);
const OptionField fieldImageQuality = OptionField(
    SettingKey.imageQuality, '图片质量', kImageQualityOptions);

// ---------- 通用参数翻译助手 ----------

/// "1920 宽" -> FFmpeg 缩放滤镜；返回 null 表示不缩放。
String? resolutionToVf(ConvertSettings s) {
  final v = s.of(SettingKey.resolution);
  final width = switch (v) {
    '1920 宽' => '1920',
    '1280 宽' => '1280',
    '854 宽' => '854',
    '640 宽' => '640',
    _ => null,
  };
  if (width == null) return null;
  // -2 表示高度按原比例自动计算并保持为偶数（H.264 要求）
  return 'scale=$width:-2';
}

/// 视频质量档位 -> CRF 数值。
int videoQualityCrf(ConvertSettings s) => switch (s.of(SettingKey.videoQuality)) {
      '画质优先' => 18,
      '体积优先' => 28,
      _ => 23,
    };

/// 音频通用参数（码率/采样率/声道），全是"自动"时返回 null。
List<String>? audioCommonArgs(ConvertSettings s) {
  final args = <String>[];
  final br = s.of(SettingKey.audioBitrate);
  if (br != '自动') args.addAll(['-b:a', br]);
  final sr = s.of(SettingKey.sampleRate);
  if (sr != '自动') args.addAll(['-ar', sr]);
  final ch = s.of(SettingKey.channels);
  if (ch == '双声道') args.addAll(['-ac', '2']);
  if (ch == '单声道') args.addAll(['-ac', '1']);
  return args.isEmpty ? null : args;
}

/// 图片质量档位：jpeg 用 q:v（2~8），webp 用 quality（0~100）。
({int jpegQ, int webpQ}) imageQualityOf(ConvertSettings s) =>
    switch (s.of(SettingKey.imageQuality)) {
      '高质量' => (jpegQ: 2, webpQ: 90),
      '小体积' => (jpegQ: 8, webpQ: 60),
      _ => (jpegQ: 4, webpQ: 80),
    };

/// 给参数列表追加缩放滤镜（若用户选了非原始尺寸）。
void appendScale(List<String> args, ConvertSettings s) {
  final vf = resolutionToVf(s);
  if (vf != null) args.addAll(['-vf', vf]);
}
