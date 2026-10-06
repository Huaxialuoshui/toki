import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/entities/chat_appearance.dart';
import 'image_source.dart';

/// 聊天背景层（规格 §10）：纯色 / 渐变 / 图片 + 透明度 + 模糊 + 暗色遮罩。
///
/// 图片加载失败时自动回落到纯色背景，不会出现裂图或崩溃。
class ChatBackground extends StatelessWidget {
  const ChatBackground({
    super.key,
    required this.config,
    required this.child,
  });

  final ChatBackgroundConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget layer = switch (config.type) {
      ChatBackgroundType.solid => ColoredBox(color: config.solid),
      ChatBackgroundType.gradient => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: config.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ChatBackgroundType.image => _imageLayer(context),
    };

    if (config.blurAmount > 0) {
      layer = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: config.blurAmount,
          sigmaY: config.blurAmount,
        ),
        child: layer,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        layer,
        if (config.overlayOpacity > 0)
          ColoredBox(
            color: config.overlay.withValues(
              alpha: config.overlayOpacity.clamp(0.0, 1.0),
            ),
          ),
        child,
      ],
    );
  }

  Widget _imageLayer(BuildContext context) {
    final provider = resolveImageProvider(config.imagePath);
    if (provider == null) return ColoredBox(color: config.solid);
    return Image(
      image: provider,
      fit: BoxFit.cover,
      opacity: AlwaysStoppedAnimation<double>(
        config.imageOpacity.clamp(0.0, 1.0),
      ),
      errorBuilder: (_, __, ___) => ColoredBox(color: config.solid),
    );
  }
}
