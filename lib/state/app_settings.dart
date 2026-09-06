import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// SharedPreferences 单例：在 main() 里 await 后通过 override 注入，
/// 让设置 Provider 可以同步读取，避免到处异步。
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider 必须在 ProviderScope 中 override');
});

/// 应用设置。
///
/// 三个媒体类别的输出目标：值为 "app"（应用专属目录，默认），
/// 或一段 SAF 目录 uri（用户自选目录，需已持久化授权）。
/// [pickerMode]：'saf' = 系统文件选择器（默认）；'manage' = 文件管理权限 + 自建浏览器。
class AppSettings {
  const AppSettings({
    required this.pickerMode,
    required this.videoTarget,
    required this.audioTarget,
    required this.imageTarget,
    this.notificationsEnabled = true,
  });

  final String pickerMode;
  final String videoTarget;
  final String audioTarget;
  final String imageTarget;

  /// 转码时是否显示通知 + 保持后台运行。
  final bool notificationsEnabled;

  static const String targetApp = 'app';

  String targetOf(MediaKind kind) => switch (kind) {
        MediaKind.video => videoTarget,
        MediaKind.audio => audioTarget,
        MediaKind.image => imageTarget,
      };

  AppSettings copyWith({
    String? pickerMode,
    String? videoTarget,
    String? audioTarget,
    String? imageTarget,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      pickerMode: pickerMode ?? this.pickerMode,
      videoTarget: videoTarget ?? this.videoTarget,
      audioTarget: audioTarget ?? this.audioTarget,
      imageTarget: imageTarget ?? this.imageTarget,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _kPicker = 'picker.mode';
  static const _kV = 'out.video';
  static const _kA = 'out.audio';
  static const _kI = 'out.image';
  static const _kNotify = 'notify.enabled';

  @override
  AppSettings build() {
    final p = ref.watch(sharedPrefsProvider);
    return AppSettings(
      pickerMode: p.getString(_kPicker) ?? 'saf',
      videoTarget: p.getString(_kV) ?? AppSettings.targetApp,
      audioTarget: p.getString(_kA) ?? AppSettings.targetApp,
      imageTarget: p.getString(_kI) ?? AppSettings.targetApp,
      notificationsEnabled: p.getBool(_kNotify) ?? true,
    );
  }

  /// 切换读取文件方式：'saf' / 'manage'。
  Future<void> setPickerMode(String mode) async {
    state = state.copyWith(pickerMode: mode);
    await _persist();
  }

  /// 设置某个类别的输出目标（'app' 或 SAF uri）。
  Future<void> setOutput(MediaKind kind, String target) async {
    state = switch (kind) {
      MediaKind.video => state.copyWith(videoTarget: target),
      MediaKind.audio => state.copyWith(audioTarget: target),
      MediaKind.image => state.copyWith(imageTarget: target),
    };
    await _persist();
  }

  /// 通知（后台进度条）开关。
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _persist();
  }

  Future<void> _persist() async {
    final p = ref.read(sharedPrefsProvider);
    await p.setString(_kPicker, state.pickerMode);
    await p.setString(_kV, state.videoTarget);
    await p.setString(_kA, state.audioTarget);
    await p.setString(_kI, state.imageTarget);
    await p.setBool(_kNotify, state.notificationsEnabled);
  }
}
