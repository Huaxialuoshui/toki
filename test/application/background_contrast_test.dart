import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/appearance/background_contrast.dart';
import 'package:toki/application/theme/theme_presets.dart';

void main() {
  group('背景明暗分析', () {
    test('深色背景推荐浅色文字，浅色背景推荐深色文字', () {
      expect(
        BackgroundTone.fromColor(const Color(0xFF0B0D12)).prefersLightText,
        isTrue,
      );
      expect(
        BackgroundTone.fromColor(const Color(0xFFF6F7FB)).prefersLightText,
        isFalse,
      );
    });

    test('明暗混杂的渐变会被识别出来', () {
      final tone = BackgroundTone.fromColors(<Color>[
        const Color(0xFF000000),
        const Color(0xFFFFFFFF),
      ]);
      expect(tone.isMixed, isTrue);
      expect(tone.maximum - tone.minimum, greaterThan(0.42));
    });
  });

  group('自动对比度主题', () {
    test('浅色主题 + 深色背景会切成浅色文字', () {
      final result = resolveAdaptiveBackgroundTheme(
        base: ThemePresets.defaultTheme,
        tone: BackgroundTone.fromColor(const Color(0xFF0B0D12)),
        enabled: true,
      );

      expect(result.usesLightText, isTrue);
      expect(result.config.textColor.computeLuminance(), greaterThan(0.5));
      expect(
        contrastRatio(
          result.config.textColor,
          const Color(0xFF0B0D12),
        ),
        greaterThan(4.5),
      );
    });

    test('明暗混杂时增加遮罩，避免局部深色像素压住文字', () {
      final result = resolveAdaptiveBackgroundTheme(
        base: ThemePresets.defaultTheme,
        tone: BackgroundTone.fromColors(<Color>[
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ]),
        enabled: true,
      );

      expect(result.overlayOpacity, greaterThan(0));
      expect(result.overlayColor, const Color(0xFFFFFFFF));
    });

    test('关闭自动对比度时保留原主题', () {
      final result = resolveAdaptiveBackgroundTheme(
        base: ThemePresets.darkTheme,
        tone: BackgroundTone.fromColor(const Color(0xFFF6F7FB)),
        enabled: false,
      );

      expect(result.config, ThemePresets.darkTheme);
      expect(result.overlayOpacity, 0);
    });
  });
}
