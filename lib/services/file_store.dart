import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models.dart';

/// 输出目录与文件命名工具。
///
/// 输出目录选择"应用专属外部目录"，即
///   Android/data/<包名>/files/FormatFactory/<类别>/
/// 它在所有 Android 7.0+ 上都不需要任何存储权限，
/// 是最简单、最不会出权限问题的方案。
/// （文件可通过任务列表里的"分享"发给任何应用保存。）
class FileStore {
  FileStore._();

  static Future<Directory> outputDir(MediaKind kind) async {
    final base = await _externalDir();
    final dir = Directory(
        '${base.path}${Platform.pathSeparator}FormatFactory'
        '${Platform.pathSeparator}${kind.dirName}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 输出目录对应的"可读描述"（展示给用户看）。
  static Future<String> outputDirText() async {
    final base = await _externalDir();
    return '${base.path}${Platform.pathSeparator}FormatFactory';
  }

  /// 生成一个不会覆盖同名文件的新输出路径。
  static Future<String> uniqueOutputPath(
    MediaKind kind,
    String inputName,
    String presetExtension,
  ) async {
    final dir = await outputDir(kind);
    final dot = inputName.lastIndexOf('.');
    final base = dot > 0 ? inputName.substring(0, dot) : inputName;
    // 用"微秒时间戳后 6 位"避免重名
    final stamp =
        (DateTime.now().microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    final fileName = '${base}_$stamp.$presetExtension';
    return '${dir.path}${Platform.pathSeparator}$fileName';
  }

  /// 从文件系统元数据拿文件大小（字节）。
  static int fileBytes(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  static Future<Directory> _externalDir() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw StateError('无法获取应用外部存储目录');
    }
    return dir;
  }
}
