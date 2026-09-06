import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'ui/home_shell.dart';

/// 应用根组件：包一层 ProviderScope（Riverpod 全局状态容器），
/// 然后按系统亮暗模式套用 Material 3 主题。
class FormatFactoryApp extends StatelessWidget {
  const FormatFactoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: '格式工厂',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system, // 跟随系统切换亮/暗
        home: const HomeShell(),
      ),
    );
  }
}
