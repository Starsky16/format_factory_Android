import '../models.dart';

/// 用户从系统文件选择器挑出来的一个媒体文件。
/// FFprobe 的结果异步塞进 [info]，界面据此显示时长/分辨率。
class PickedMedia {
  PickedMedia({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;

  /// FFprobe 结果；null 表示读取失败（可能是不支持的格式）。
  MediaInfo? info;

  /// 是否还在读信息（界面显示占位文案）。
  bool probing = true;
}

/// 文件大小 -> "2.3 MB"。
String formatBytes(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final text = v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$text ${units[i]}';
}
