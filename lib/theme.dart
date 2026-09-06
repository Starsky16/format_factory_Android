import 'package:flutter/material.dart';

/// 全局主题定义：Material 3（Material You 风格）。
///
/// 想换整体配色？改下面的 [_seed] 种子色即可，整套颜色会自动生成。
class AppTheme {
  AppTheme._();

  /// 主色调种子：青绿色。改成你喜欢的颜色如 Colors.blue / Colors.purple。
  static const Color seedColor = Color(0xFF00897B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // Material 3：从一个种子色派生全套配色
    final scheme =
        ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
