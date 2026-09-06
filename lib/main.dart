import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/foreground_notifier.dart';
import 'state/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化前台通知通道（转码时显示通知/后台保活）
  ForegroundNotifier.init();
  // 先取到 SharedPreferences 再启动，设置 Provider 就能同步读取
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const FormatFactoryApp(),
    ),
  );
}
