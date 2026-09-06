import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// 前台通知封装（基于 flutter_foreground_task）。
///
/// 作用：
///  1. 转码时启动"前台服务"提高进程优先级，切后台/锁屏不会被系统杀掉
///  2. 通知栏展示实时进度（文本百分比）
///
/// 说明：该插件通知不支持原生进度条，采用"转换中 45%（1/3）"文本进度。
class ForegroundNotifier {
  ForegroundNotifier._();

  static bool _started = false;

  static bool get started => _started;

  /// 应用启动时初始化（在 main 里调用一次）。
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: '转码进度',
        channelDescription: '后台转码时的进度通知',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // 本应用不依赖周期回调：转码由主 isolate 的任务队列驱动
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
  }

  /// 启动前台服务。重复调用安全。
  static Future<void> start() async {
    if (_started) return;
    try {
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationTitle: '格式工厂',
        notificationText: '准备转换…',
        callback: _serviceEntry,
      );
      _started = true;
    } catch (_) {
      _started = false; // 失败不阻塞转换，只是没有后台保活/通知
    }
  }

  /// 更新通知内容（标题 + 文本）。
  static Future<void> update({required String title, String? text}) async {
    if (!_started) return;
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } catch (_) {}
  }

  /// 停止前台服务并移除通知。
  static Future<void> stop() async {
    if (!_started) return;
    _started = false;
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }
}

/// 前台服务的后台入口（插件要求顶层函数）。
/// 本应用的转码逻辑跑在主 isolate 的任务队列里，
/// 前台服务只负责"保活 + 通知展示"，这里无需额外工作。
void _serviceEntry() {}
