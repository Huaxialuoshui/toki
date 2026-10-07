import 'package:flutter/material.dart';

import '../../domain/entities/theme_config.dart';

/// 把 [ThemeConfig] 翻译成 `ThemeData`。
///
/// 这里只处理 `ThemeData` 该管的东西：颜色、字体、组件主题、圆角、字号缩放。
/// **透明度与模糊不在这里**，它们属于 `GlassStyle`，见
/// `domain/entities/glass_style.dart` 与 `shared/widgets/glass_card.dart`。
ThemeData buildThemeData(ThemeConfig config) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: config.primaryColor,
    brightness: config.brightness,
  ).copyWith(
    primary: config.primaryColor,
    onPrimary: _onColorFor(config.primaryColor),
    secondary: config.secondaryColor,
    onSecondary: _onColorFor(config.secondaryColor),
    surface: config.surfaceColor,
    onSurface: config.textColor,
  );

  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
  final mutedText = config.textColor.withValues(alpha: 0.72);
  final hairline = config.textColor.withValues(alpha: 0.10);

  return base.copyWith(
    scaffoldBackgroundColor: config.backgroundColor,
    // 字号缩放不在这里：`ThemeData` 的文本样式在部分平台上没有显式 fontSize，
    // 真正生效的做法是在 `TokiApp` 里通过 MediaQuery.textScaler 应用。
    textTheme: base.textTheme.apply(
      bodyColor: config.textColor,
      displayColor: config.textColor,
    ),
    iconTheme: IconThemeData(color: config.textColor.withValues(alpha: 0.86)),
    dividerTheme: DividerThemeData(color: hairline, space: 1, thickness: 1),
    pageTransitionsTheme: config.animationEnabled
        ? null
        : const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: _InstantPageTransitionsBuilder(),
              TargetPlatform.windows: _InstantPageTransitionsBuilder(),
              TargetPlatform.linux: _InstantPageTransitionsBuilder(),
              TargetPlatform.macOS: _InstantPageTransitionsBuilder(),
              TargetPlatform.fuchsia: _InstantPageTransitionsBuilder(),
              TargetPlatform.iOS: _InstantPageTransitionsBuilder(),
            },
          ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: config.navigationBarColor ?? config.surfaceColor,
      indicatorColor: config.primaryColor.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          fontSize: 12,
          color: config.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: config.navigationBarColor ?? config.surfaceColor,
      indicatorColor: config.primaryColor.withValues(alpha: 0.18),
      selectedIconTheme: IconThemeData(color: config.primaryColor),
      unselectedIconTheme: IconThemeData(color: mutedText),
      selectedLabelTextStyle: TextStyle(
        color: config.primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: mutedText,
        fontSize: 12,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: config.surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: config.radius,
        borderSide: BorderSide(color: hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: config.radius,
        borderSide: BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: config.radius,
        borderSide: BorderSide(color: config.primaryColor, width: 1.6),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: config.primaryColor,
      thumbColor: config.primaryColor,
      inactiveTrackColor: config.primaryColor.withValues(alpha: 0.20),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: config.surfaceColor,
      selectedColor: config.primaryColor.withValues(alpha: 0.18),
      side: BorderSide(color: hairline),
      shape: RoundedRectangleBorder(borderRadius: config.radius),
      labelStyle: TextStyle(color: config.textColor, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: config.primaryColor, fontSize: 13),
    ),
  );
}

Color _onColorFor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1B1D2A);

/// `animationEnabled == false` 时使用的"瞬时"页面过渡。
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
