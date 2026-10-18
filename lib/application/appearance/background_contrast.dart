import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/theme_config.dart';

/// 背景的明暗统计。
///
/// [minimum] / [maximum] 使用 10% / 90% 分位，避免一张图里的极小高光
/// 或极暗噪点把整体判断带偏。
@immutable
class BackgroundTone {
  const BackgroundTone({
    required this.average,
    required this.minimum,
    required this.maximum,
    this.samples = 1,
  });

  factory BackgroundTone.fromColor(Color color) {
    final double luminance = color.computeLuminance();
    return BackgroundTone(
      average: luminance,
      minimum: luminance,
      maximum: luminance,
    );
  }

  factory BackgroundTone.fromColors(Iterable<Color> colors) {
    final List<double> values = colors
        .where((Color color) => color.a > 0.01)
        .map((Color color) => color.computeLuminance())
        .toList(growable: false);
    return BackgroundTone.fromLuminances(values);
  }

  factory BackgroundTone.fromLuminances(List<double> values) {
    if (values.isEmpty) {
      return const BackgroundTone(average: 1, minimum: 1, maximum: 1);
    }
    final List<double> sorted = List<double>.of(values)..sort();
    final double average =
        sorted.fold<double>(0, (double sum, double v) => sum + v) /
            sorted.length;
    final int low = ((sorted.length - 1) * 0.1).round();
    final int high = ((sorted.length - 1) * 0.9).round();
    return BackgroundTone(
      average: average,
      minimum: sorted[low],
      maximum: sorted[high],
      samples: sorted.length,
    );
  }

  final double average;
  final double minimum;
  final double maximum;
  final int samples;

  /// 背景是否同时有明显亮部和暗部。
  ///
  /// 这种情况下只换文字颜色还不够：黑色文字会压在局部深色像素上，
  /// 白色文字会压在局部高光上，所以需要再加一层轻遮罩。
  bool get isMixed => (maximum - minimum) >= 0.42;

  /// 更推荐浅色文字（也就是深色主题）。
  bool get prefersLightText => average < 0.5;

  Color get representativeColor =>
      prefersLightText ? const Color(0xFF14161C) : const Color(0xFFF4F5FA);

  @override
  bool operator ==(Object other) =>
      other is BackgroundTone &&
      other.average == average &&
      other.minimum == minimum &&
      other.maximum == maximum &&
      other.samples == samples;

  @override
  int get hashCode => Object.hash(average, minimum, maximum, samples);
}

/// 自动对比度计算后的主题与遮罩。
@immutable
class AdaptiveBackgroundTheme {
  const AdaptiveBackgroundTheme({
    required this.config,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.usesLightText,
  });

  final ThemeConfig config;
  final Color overlayColor;
  final double overlayOpacity;
  final bool usesLightText;
}

const Color _kLightText = Color(0xFFF4F6FB);
const Color _kDarkText = Color(0xFF15171F);
const Color _kDarkBackground = Color(0xFF0E1016);
const Color _kDarkSurface = Color(0xFF1A1D26);
const Color _kLightBackground = Color(0xFFF4F5FA);
const Color _kLightSurface = Color(0xFFFFFFFF);

/// 相对亮度对比度（WCAG）。
double contrastRatio(Color a, Color b) {
  final double left = a.computeLuminance();
  final double right = b.computeLuminance();
  final double lighter = math.max(left, right);
  final double darker = math.min(left, right);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 根据背景明暗，决定是否需要把主题切到深色 / 浅色，以及是否加遮罩。
AdaptiveBackgroundTheme resolveAdaptiveBackgroundTheme({
  required ThemeConfig base,
  required BackgroundTone tone,
  required bool enabled,
}) {
  if (!enabled) {
    return AdaptiveBackgroundTheme(
      config: base,
      overlayColor: const Color(0xFF000000),
      overlayOpacity: 0,
      usesLightText: base.textColor.computeLuminance() > 0.5,
    );
  }

  final bool useLightText = tone.prefersLightText;
  final Color targetText = useLightText ? _kLightText : _kDarkText;
  final Color representative = tone.representativeColor;
  final double currentContrast = contrastRatio(base.textColor, representative);
  final double targetContrast = contrastRatio(targetText, representative);

  final bool mustSwitch =
      currentContrast < 4.5 && targetContrast > currentContrast + 0.5;
  final bool mixed = tone.isMixed;

  // 背景本身明暗混杂时，无论主题是什么都加一层遮罩；否则只在确实
  // 看不清的时候切换主题。
  final bool needsScrim = mixed;
  final ThemeConfig effective = mustSwitch || (mixed && useLightText)
      ? base.copyWith(
          brightness: useLightText ? Brightness.dark : Brightness.light,
          textColor: targetText,
          backgroundColor: useLightText ? _kDarkBackground : _kLightBackground,
          surfaceColor: useLightText ? _kDarkSurface : _kLightSurface,
          navigationBarColor: useLightText ? _kDarkSurface : _kLightSurface,
          sidebarColor: useLightText ? _kDarkSurface : _kLightSurface,
        )
      : base;

  final Color scrimColor =
      useLightText ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  final double scrimOpacity = needsScrim
      ? (0.16 + (tone.maximum - tone.minimum) * 0.22).clamp(0.16, 0.36)
      : 0;

  return AdaptiveBackgroundTheme(
    config: effective,
    overlayColor: scrimColor,
    overlayOpacity: scrimOpacity,
    usesLightText: useLightText,
  );
}

/// 把 [Color] 以 [opacity] 叠到 [background] 上，得到真正会被看到的颜色。
Color compositeColor(
  Color color,
  Color background, {
  double opacity = 1,
  Color? overlay,
  double overlayOpacity = 0,
}) {
  final Color faded = color.withValues(
    alpha: color.a * opacity.clamp(0.0, 1.0),
  );
  final Color merged = Color.alphaBlend(faded, background);
  final Color? shade = overlay;
  if (shade == null || overlayOpacity <= 0) return merged;
  return Color.alphaBlend(
    shade.withValues(
      alpha: shade.a * overlayOpacity.clamp(0.0, 1.0),
    ),
    merged,
  );
}

/// 解析一个渐变在 9 个采样点上的明暗。
BackgroundTone toneOfGradient(
  List<Color> colors, {
  required Color background,
  Color? overlay,
  double overlayOpacity = 0,
}) {
  if (colors.isEmpty) return BackgroundTone.fromColor(background);
  if (colors.length == 1) {
    return BackgroundTone.fromColor(
      compositeColor(
        colors.first,
        background,
        overlay: overlay,
        overlayOpacity: overlayOpacity,
      ),
    );
  }
  final List<Color> samples = <Color>[];
  for (var i = 0; i <= 8; i++) {
    final double t = i / 8;
    final double position = t * (colors.length - 1);
    final int lower = position.floor();
    final int upper = math.min(lower + 1, colors.length - 1);
    final Color color =
        Color.lerp(colors[lower], colors[upper], position - lower)!;
    samples.add(
      compositeColor(
        color,
        background,
        overlay: overlay,
        overlayOpacity: overlayOpacity,
      ),
    );
  }
  return BackgroundTone.fromColors(samples);
}

/// 采样一张图片（32×32）并计算明暗统计。
///
/// 图片会按 [imageOpacity] 与 [background] 合成，再按遮罩参数合成，
/// 这样统计的是用户实际看到的颜色，而不是原图里孤立的高光 / 暗部。
Future<BackgroundTone?> sampleImageTone(
  ImageProvider provider, {
  required Color background,
  double imageOpacity = 1,
  Color overlay = const Color(0xFF000000),
  double overlayOpacity = 0,
}) async {
  final Completer<ui.Image?> completer = Completer<ui.Image?>();
  final ImageStream stream = provider.resolve(const ImageConfiguration());
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool _) {
      if (!completer.isCompleted) completer.complete(info.image);
    },
    onError: (Object error, StackTrace? stackTrace) {
      if (!completer.isCompleted) completer.complete(null);
    },
  );
  stream.addListener(listener);

  final ui.Image? image;
  try {
    image = await completer.future.timeout(const Duration(seconds: 5));
  } on TimeoutException {
    stream.removeListener(listener);
    return null;
  }
  if (image == null) {
    stream.removeListener(listener);
    return null;
  }

  try {
    const int width = 32;
    const int height = 32;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final ui.Picture picture = recorder.endRecording();
    final ui.Image scaled = await picture.toImage(width, height);
    picture.dispose();
    final ByteData? data =
        await scaled.toByteData(format: ui.ImageByteFormat.rawRgba);
    scaled.dispose();
    if (data == null) return null;

    final Uint8List bytes = data.buffer.asUint8List();
    final int backgroundR = (background.r * 255).round();
    final int backgroundG = (background.g * 255).round();
    final int backgroundB = (background.b * 255).round();
    final int overlayR = (overlay.r * 255).round();
    final int overlayG = (overlay.g * 255).round();
    final int overlayB = (overlay.b * 255).round();
    final double safeImageOpacity = imageOpacity.clamp(0.0, 1.0);
    final double safeOverlayOpacity = overlayOpacity.clamp(0.0, 1.0);
    final List<double> luminances = <double>[];

    for (var i = 0; i + 3 < bytes.length; i += 4) {
      final double alpha = (bytes[i + 3] / 255) * safeImageOpacity;
      double red = bytes[i] * alpha + backgroundR * (1 - alpha);
      double green = bytes[i + 1] * alpha + backgroundG * (1 - alpha);
      double blue = bytes[i + 2] * alpha + backgroundB * (1 - alpha);
      red = red * (1 - safeOverlayOpacity) + overlayR * safeOverlayOpacity;
      green = green * (1 - safeOverlayOpacity) + overlayG * safeOverlayOpacity;
      blue = blue * (1 - safeOverlayOpacity) + overlayB * safeOverlayOpacity;
      luminances.add(
        _luminanceFromRgb(red / 255, green / 255, blue / 255),
      );
    }
    return BackgroundTone.fromLuminances(luminances);
  } finally {
    stream.removeListener(listener);
    image.dispose();
  }
}

double _luminanceFromRgb(double red, double green, double blue) {
  double linear(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue);
}
