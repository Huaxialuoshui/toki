import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/theme_config.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import 'theme_presets.dart';

/// 外观状态：选中的预设 + 是否跟随系统 + 两个轻量微调。
///
/// 微调（字号 / 圆角）只做"叠加"，不修改预设本身；完整的主题编辑器在 Phase 11。
@immutable
class ThemeState {
  const ThemeState({
    required this.themeId,
    required this.followSystem,
    this.fontScale = 1,
    this.borderRadius,
  });

  final String themeId;
  final bool followSystem;
  final double fontScale;

  /// null 表示沿用预设自带的圆角。
  final double? borderRadius;

  ThemeConfig get preset => ThemePresets.byId(themeId);

  /// 把微调叠加到某个预设上。
  ThemeConfig configFor(ThemeConfig base) => base.copyWith(
        fontScale: fontScale,
        borderRadius: borderRadius,
      );

  /// 计算最终生效的主题。
  ///
  /// * 不跟随系统：`ThemeMode` 由所选预设的明暗决定；
  /// * 跟随系统：浅色用所选预设（若它是浅色预设）否则用 Default，深色用所选
  ///   预设（若它是深色预设）否则用 Dark。
  ThemeResolution resolve() {
    final selected = preset;
    if (!followSystem) {
      final config = configFor(selected);
      return ThemeResolution(
        mode: selected.isLight ? ThemeMode.light : ThemeMode.dark,
        light: config,
        dark: config,
      );
    }
    final lightPreset = selected.isLight
        ? selected
        : ThemePresets.byId(ThemePresets.defaultId);
    final darkPreset = selected.isDark
        ? selected
        : ThemePresets.byId(ThemePresets.darkId);
    return ThemeResolution(
      mode: ThemeMode.system,
      light: configFor(lightPreset),
      dark: configFor(darkPreset),
    );
  }

  ThemeState copyWith({
    String? themeId,
    bool? followSystem,
    double? fontScale,
    double? borderRadius,
    bool keepBorderRadius = true,
  }) {
    return ThemeState(
      themeId: themeId ?? this.themeId,
      followSystem: followSystem ?? this.followSystem,
      fontScale: fontScale ?? this.fontScale,
      borderRadius:
          keepBorderRadius ? (borderRadius ?? this.borderRadius) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.themeId == themeId &&
        other.followSystem == followSystem &&
        other.fontScale == fontScale &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(themeId, followSystem, fontScale, borderRadius);
}

/// 解析结果：`MaterialApp` 需要的两组 `ThemeData` 与 `ThemeMode`。
@immutable
class ThemeResolution {
  const ThemeResolution({
    required this.mode,
    required this.light,
    required this.dark,
  });

  final ThemeMode mode;
  final ThemeConfig light;
  final ThemeConfig dark;

  /// 根据实际生效的亮度取当前配置（供玻璃层使用）。
  ThemeConfig configFor(Brightness platformBrightness) {
    switch (mode) {
      case ThemeMode.light:
        return light;
      case ThemeMode.dark:
        return dark;
      case ThemeMode.system:
        return platformBrightness == Brightness.dark ? dark : light;
    }
  }
}

class ThemeController extends Notifier<ThemeState> {
  static const double minFontScale = 0.9;
  static const double maxFontScale = 1.3;
  static const double minBorderRadius = 0;
  static const double maxBorderRadius = 32;

  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  ThemeState build() {
    final store = ref.watch(appSettingsStoreProvider);
    final storedId = store.readThemeId();
    return ThemeState(
      themeId: storedId != null && ThemePresets.isKnownId(storedId)
          ? storedId
          : ThemePresets.defaultId,
      followSystem: store.readFollowSystem() ?? true,
      fontScale: store.readFontScale() ?? 1,
      borderRadius: store.readBorderRadius(),
    );
  }

  /// 选择某个预设；显式选择预设意味着不再跟随系统。
  void selectPreset(String id) {
    if (!ThemePresets.isKnownId(id) || id == state.themeId && !state.followSystem) {
      return;
    }
    state = state.copyWith(themeId: id, followSystem: false);
    unawaited(_persist());
  }

  void setFollowSystem(bool value) {
    if (value == state.followSystem) return;
    state = state.copyWith(followSystem: value);
    unawaited(_persist());
  }

  void setFontScale(double value) {
    final clamped = value.clamp(minFontScale, maxFontScale).toDouble();
    if (clamped == state.fontScale) return;
    state = state.copyWith(fontScale: clamped);
    unawaited(_persist());
  }

  void setBorderRadius(double value) {
    final clamped = value.clamp(minBorderRadius, maxBorderRadius).toDouble();
    if (clamped == state.borderRadius) return;
    state = state.copyWith(borderRadius: clamped, keepBorderRadius: true);
    unawaited(_persist());
  }

  void resetBorderRadius() {
    if (state.borderRadius == null) return;
    state = state.copyWith(keepBorderRadius: false);
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final store = _store;
    await store.writeThemeId(state.themeId);
    await store.writeFollowSystem(state.followSystem);
    await store.writeFontScale(state.fontScale == 1 ? null : state.fontScale);
    await store.writeBorderRadius(state.borderRadius);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(ThemeController.new);

final themeResolutionProvider = Provider<ThemeResolution>(
  (ref) => ref.watch(themeControllerProvider).resolve(),
);
