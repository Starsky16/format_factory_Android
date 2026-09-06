import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models.dart';
import '../state/app_settings.dart';

/// 输出目录与文件命名工具。
///
/// 有两种输出位置（由设置页决定）：
///  1. "应用专属目录"（默认）：Android/data/<包名>/files/FormatFactory/<类别>/
///     全版本无需任何权限。
///  2. "用户自选 SAF 目录"：FFmpeg 先写到看不见的内部工作区，
///     转换成功后再由 StorageAccess 复制进用户选择的目录。
class FileStore {
  FileStore._();

  /// 应用专属输出目录（默认落点）。
  static Future<Directory> appOutputDir(MediaKind kind) async {
    final base = await _externalDir();
    final dir = Directory(
        '${base.path}${Platform.pathSeparator}FormatFactory'
        '${Platform.pathSeparator}${kind.dirName}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 内部工作区：仅当用户选择了 SAF 输出目录时作为临时落点。
  static Future<Directory> workDir(MediaKind kind) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(
        '${base.path}${Platform.pathSeparator}FormatFactory_work'
        '${Platform.pathSeparator}${kind.dirName}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 按设置的目标决定输出目录
  /// （target='app' 用专属目录；否则 target 是 SAF uri，写内部工作区）。
  static Future<Directory> outputDir(MediaKind kind, String target) =>
      target == AppSettings.targetApp ? appOutputDir(kind) : workDir(kind);

  /// 输出目录对应的"可读描述"（展示给用户看）。
  static Future<String> appOutputDirText() async {
    final base = await _externalDir();
    return '${base.path}${Platform.pathSeparator}FormatFactory';
  }

  /// 生成一个不会覆盖同名文件的新输出路径。
  static Future<String> uniqueOutputPath(
    MediaKind kind,
    String inputName,
    String presetExtension, {
    required String target,
  }) async {
    final dir = await outputDir(kind, target);
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
