import 'package:flutter/material.dart';

/// 应用主题
class AppTheme {
  /// 亮色主题
  /// 匹配 Web 版本的设计系统，使用 #4caf50 作为主色调
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50), // #4caf50 - 匹配 Web 版本的主题色
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA), // #fafafa - 匹配 Web 版本的内容背景色
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white, // 匹配 Web 版本的白色卡片背景
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white, // 匹配 Web 版本的白色背景
      ),
      dividerColor: const Color(0xFFE0E0E0), // #e0e0e0 - 匹配 Web 版本的边框色
    );
  }

  /// 暗色主题
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
