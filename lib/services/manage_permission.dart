import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// "文件管理权限"模式共用助手（设置页 / 转换页 / 脱壳页都会用到）：
///  - Android 11+：请求"所有文件访问"
///  - Android 10 及以下：请求经典存储权限
class ManagePermission {
  ManagePermission._();

  static bool get isAndroid11Plus {
    if (!Platform.isAndroid) return false;
    final v = int.tryParse(Platform.version.split('.').first) ?? 0;
    return v >= 30;
  }

  /// 是否已授予。
  static Future<bool> isGranted() async {
    if (isAndroid11Plus) return Permission.manageExternalStorage.isGranted;
    return Permission.storage.isGranted;
  }

  /// 请求授权；被永久拒绝时自动跳系统设置。
  /// 返回最终是否可用（false 表示用户仍未授权，需调用方提示）。
  static Future<bool> ensureGranted() async {
    final perm =
        isAndroid11Plus ? Permission.manageExternalStorage : Permission.storage;
    var status = await perm.status;
    if (!status.isGranted) {
      status = await perm.request();
    }
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }
}
