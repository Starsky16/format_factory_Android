import 'package:flutter/services.dart';

/// 调 Android 原生"脱壳"通道（MainActivity 里的 com.formatfactory.app/unlock）。
/// 每个私有格式一个方法；目前支持 ncm，后续 qmc/kgm 在同一通道扩展。
class UnlockApi {
  UnlockApi._();

  static const MethodChannel _channel =
      MethodChannel('com.formatfactory.app/unlock');

  /// 网易云 .ncm 脱壳：读 [src]，把解出的原始音频写到 [destDir] 目录。
  /// 返回实际输出文件路径与扩展名。
  static Future<({String path, String ext})> unlockNcm({
    required String src,
    required String destDir,
  }) async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'unlockNcm',
        {'src': src, 'destDir': destDir},
      );
      if (map == null) {
        throw Exception('无返回结果');
      }
      return (
        path: map['path'] as String,
        ext: map['ext'] as String,
      );
    } on PlatformException catch (e) {
      throw Exception(e.message ?? '解密失败');
    }
  }
}
