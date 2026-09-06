import 'package:flutter/services.dart';

/// 原生存储能力（见 android MainActivity 里同名的 MethodChannel）：
///  1. 弹系统"选择目录"对话框，返回并持久化 SAF 目录 uri
///  2. 把一个已转好的本地文件复制进该目录
class StorageAccess {
  StorageAccess._();

  static const MethodChannel _channel =
      MethodChannel('com.formatfactory.app/storage');

  /// 弹出系统目录选择器；用户取消返回 null。
  static Future<String?> pickDirectory() async {
    return _channel.invokeMethod<String>('pickOutputDir');
  }

  /// 把 [srcPath] 文件复制到 [treeUri] 目录下，命名为 [fileName]。
  /// 返回目标文件的 content uri；失败返回 null。
  static Future<String?> copyToTree({
    required String treeUri,
    required String fileName,
    required String srcPath,
  }) async {
    try {
      return await _channel.invokeMethod<String>('copyToTree', {
        'treeUri': treeUri,
        'fileName': fileName,
        'srcPath': srcPath,
      });
    } catch (_) {
      return null;
    }
  }
}
