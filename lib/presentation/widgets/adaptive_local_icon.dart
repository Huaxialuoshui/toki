import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 展示用户自己的抠图图标。
///
/// 与普通 `Image.file(..., fit: BoxFit.contain)` 的区别：
/// * 读取 alpha 通道并自动裁掉四周透明留白，小图标在导航栏里不会只剩一小点；
/// * 不铺白色底板，PNG / WebP 的透明区域会真正透出界面背景；
/// * 当浅色图标放在浅色主题上（或深色图标放在深色主题上）时，自动加一层
///   很轻的轮廓阴影，兼顾可见性而不改变原图颜色。
class AdaptiveLocalIcon extends StatefulWidget {
  const AdaptiveLocalIcon({
    super.key,
    required this.path,
    required this.fallbackIcon,
    required this.size,
    this.fallbackColor,
    this.selected = true,
  });

  final String? path;
  final IconData fallbackIcon;
  final double size;
  final Color? fallbackColor;
  final bool selected;

  @override
  State<AdaptiveLocalIcon> createState() => _AdaptiveLocalIconState();
}

class _AdaptiveLocalIconState extends State<AdaptiveLocalIcon> {
  ui.Image? _image;
  Rect? _alphaBounds;
  double? _meanLuminance;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AdaptiveLocalIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final oldImage = _image;
    _image = null;
    _alphaBounds = null;
    _meanLuminance = null;
    oldImage?.dispose();

    final path = widget.path?.trim();
    if (path == null || path.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        if (mounted && generation == _loadGeneration) setState(() {});
        return;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 512,
      );
      late final ui.FrameInfo frame;
      try {
        frame = await codec.getNextFrame();
      } finally {
        codec.dispose();
      }
      final decoded = await _analyze(frame.image);
      if (!mounted || generation != _loadGeneration) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _image = frame.image;
        _alphaBounds = decoded.bounds;
        _meanLuminance = decoded.meanLuminance;
      });
    } on Object {
      if (mounted && generation == _loadGeneration) setState(() {});
    }
  }

  Future<_IconAnalysis> _analyze(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) {
      return _IconAnalysis(
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        null,
      );
    }

    var left = image.width;
    var top = image.height;
    var right = 0;
    var bottom = 0;
    var luminanceSum = 0.0;
    var luminanceCount = 0;
    final bytes = data.buffer.asUint8List();
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final index = (y * image.width + x) * 4;
        final alpha = bytes[index + 3];
        if (alpha < 12) continue;
        left = math.min(left, x);
        top = math.min(top, y);
        right = math.max(right, x);
        bottom = math.max(bottom, y);
        final red = bytes[index] / alpha;
        final green = bytes[index + 1] / alpha;
        final blue = bytes[index + 2] / alpha;
        luminanceSum += 0.2126 * red + 0.7152 * green + 0.0722 * blue;
        luminanceCount++;
      }
    }

    if (right < left || bottom < top) {
      return _IconAnalysis(
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        null,
      );
    }
    return _IconAnalysis(
      Rect.fromLTRB(
        left.toDouble(),
        top.toDouble(),
        (right + 1).toDouble(),
        (bottom + 1).toDouble(),
      ),
      luminanceCount == 0 ? null : luminanceSum / luminanceCount / 255,
    );
  }

  @override
  void dispose() {
    _loadGeneration++;
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final bounds = _alphaBounds;
    if (image == null || bounds == null) {
      return SizedBox.square(
        dimension: widget.size,
        child: Icon(
          widget.fallbackIcon,
          size: widget.size,
          color: widget.fallbackColor,
        ),
      );
    }

    final brightness = Theme.of(context).brightness;
    final backgroundIsLight = brightness == Brightness.light;
    final mean = _meanLuminance;
    final needsContrastShadow = mean != null &&
        ((backgroundIsLight && mean > 0.72) ||
            (!backgroundIsLight && mean < 0.28));
    final shadow =
        backgroundIsLight ? const Color(0x99000000) : const Color(0x99FFFFFF);

    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(
        painter: _IconPainter(
          image: image,
          source: bounds,
          opacity: widget.selected ? 1 : 0.76,
          shadow: needsContrastShadow ? shadow : null,
        ),
      ),
    );
  }
}

class _IconAnalysis {
  const _IconAnalysis(this.bounds, this.meanLuminance);

  final Rect bounds;
  final double? meanLuminance;
}

class _IconPainter extends CustomPainter {
  const _IconPainter({
    required this.image,
    required this.source,
    required this.opacity,
    this.shadow,
  });

  final ui.Image image;
  final Rect source;
  final double opacity;
  final Color? shadow;

  Rect _destination(Size size) {
    final scale = math.min(
      size.width / source.width,
      size.height / source.height,
    );
    final width = source.width * scale;
    final height = source.height * scale;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final destination = _destination(size);
    if (shadow != null) {
      final shadowPaint = Paint()
        ..colorFilter = ColorFilter.mode(shadow!, BlendMode.srcIn)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(0.8, size.width * 0.055),
        );
      canvas.drawImageRect(
        image,
        source,
        destination.inflate(0.35),
        shadowPaint,
      );
    }

    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: opacity),
        BlendMode.modulate,
      );
    canvas.drawImageRect(image, source, destination, paint);
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.source != source ||
      oldDelegate.opacity != opacity ||
      oldDelegate.shadow != shadow;
}
