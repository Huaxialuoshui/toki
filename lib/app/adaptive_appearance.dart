import 'dart:async';

import 'package:flutter/material.dart';

import '../application/appearance/background_contrast.dart';
import '../application/theme/theme_mapper.dart';
import '../domain/entities/chat_appearance.dart';
import '../domain/entities/glass_style.dart';
import '../domain/entities/theme_config.dart';
import '../presentation/widgets/chat_background.dart';
import '../presentation/widgets/image_source.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/theme_config_scope.dart';

/// 应用背景 + 自动对比度 + 主题注入。
///
/// 纯色 / 渐变可以同步算出明暗；图片会异步采样一次（32×32），
/// 然后按实际显示出来的颜色决定文字、卡片与导航栏的深浅。
class AdaptiveAppearance extends StatefulWidget {
  const AdaptiveAppearance({
    super.key,
    required this.baseConfig,
    required this.background,
    required this.enabled,
    required this.child,
  });

  final ThemeConfig baseConfig;
  final ChatBackgroundConfig background;
  final bool enabled;
  final Widget child;

  @override
  State<AdaptiveAppearance> createState() => _AdaptiveAppearanceState();
}

class _AdaptiveAppearanceState extends State<AdaptiveAppearance> {
  BackgroundTone? _imageTone;
  String? _sampledKey;
  int _sampleToken = 0;

  @override
  void initState() {
    super.initState();
    _scheduleImageSample();
  }

  @override
  void didUpdateWidget(AdaptiveAppearance oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? key = _imageKey(widget);
    if (key != _sampledKey) {
      _imageTone = null;
      _scheduleImageSample();
    }
  }

  String? _imageKey(AdaptiveAppearance value) {
    if (!value.enabled ||
        value.background.type != ChatBackgroundType.image ||
        !value.background.hasImage) {
      return null;
    }
    final ChatBackgroundConfig config = value.background;
    return '${config.imagePath}|${config.imageOpacity}|'
        '${config.overlayColor}|${config.overlayOpacity}|'
        '${value.baseConfig.backgroundColor}';
  }

  void _scheduleImageSample() {
    final String? key = _imageKey(widget);
    _sampledKey = key;
    if (key == null) {
      _imageTone = null;
      return;
    }
    final ImageProvider? provider =
        resolveImageProvider(widget.background.imagePath);
    if (provider == null) return;
    final int token = ++_sampleToken;
    unawaited(_sample(provider, token));
  }

  Future<void> _sample(ImageProvider provider, int token) async {
    final BackgroundTone? tone = await sampleImageTone(
      provider,
      background: widget.baseConfig.backgroundColor,
      imageOpacity: widget.background.imageOpacity,
      overlay: widget.background.overlay,
      overlayOpacity: widget.background.overlayOpacity,
    );
    if (!mounted || token != _sampleToken) return;
    setState(() => _imageTone = tone);
  }

  BackgroundTone get _tone {
    if (!widget.enabled) {
      return BackgroundTone.fromColor(widget.baseConfig.backgroundColor);
    }
    switch (widget.background.type) {
      case ChatBackgroundType.solid:
        return BackgroundTone.fromColor(
          compositeColor(
            widget.background.solid,
            widget.baseConfig.backgroundColor,
            overlay: widget.background.overlay,
            overlayOpacity: widget.background.overlayOpacity,
          ),
        );
      case ChatBackgroundType.gradient:
        return toneOfGradient(
          widget.background.gradient,
          background: widget.baseConfig.backgroundColor,
          overlay: widget.background.overlay,
          overlayOpacity: widget.background.overlayOpacity,
        );
      case ChatBackgroundType.image:
        return _imageTone ??
            BackgroundTone.fromColor(widget.baseConfig.backgroundColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BackgroundTone tone = _tone;
    final AdaptiveBackgroundTheme resolution = resolveAdaptiveBackgroundTheme(
      base: widget.baseConfig,
      tone: tone,
      enabled: widget.enabled,
    );
    final ThemeConfig config = resolution.config;
    final ChatBackgroundConfig background = _effectiveBackground(resolution);

    return ChatBackground(
      key: const ValueKey<String>('app-background'),
      config: background,
      child: Theme(
        data: buildThemeData(config),
        child: ThemeConfigScope(
          config: config,
          child: GlassTheme(
            style: GlassStyle.fromThemeConfig(config),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(config.fontScale),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  ChatBackgroundConfig _effectiveBackground(
    AdaptiveBackgroundTheme resolution,
  ) {
    final ChatBackgroundConfig config = widget.background;
    if (resolution.overlayOpacity <= config.overlayOpacity) return config;
    return config.copyWith(
      overlayColor: ChatBackgroundConfig.argbOf(resolution.overlayColor),
      overlayOpacity: resolution.overlayOpacity,
    );
  }
}
