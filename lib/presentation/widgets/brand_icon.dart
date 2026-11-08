import 'package:flutter/material.dart';

import '../../core/constants/brand_assets.dart';
import 'adaptive_local_icon.dart';

/// Renders a bundled or user-selected navigation icon.
class BrandNavigationIcon extends StatelessWidget {
  const BrandNavigationIcon({
    super.key,
    required this.route,
    required this.storedPath,
    required this.fallbackIcon,
    this.size = 24,
    this.color,
    this.selected = true,
  });

  final String route;
  final String? storedPath;
  final IconData fallbackIcon;
  final double size;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final value = storedPath?.trim();
    final source = BrandAssets.navigationAsset(value, route);
    if (source.startsWith('asset:')) {
      return _BundledBrandImage(
        path: source.substring('asset:'.length),
        size: size,
        selected: selected,
        fallbackIcon: fallbackIcon,
        color: color,
      );
    }
    if (source.startsWith('assets/')) {
      return _BundledBrandImage(
        path: source,
        size: size,
        selected: selected,
        fallbackIcon: fallbackIcon,
        color: color,
      );
    }
    return AdaptiveLocalIcon(
      path: source,
      fallbackIcon: fallbackIcon,
      fallbackColor: color,
      size: size,
      selected: selected,
    );
  }
}

/// Square, rounded brand app icon used inside the app.
class BrandAppIcon extends StatelessWidget {
  const BrandAppIcon({
    super.key,
    this.assetPath = BrandAssets.newAppIcon,
    this.size = 48,
    this.radius = 12,
  });

  final String assetPath;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: theme.colorScheme.primaryContainer,
          alignment: Alignment.center,
          child: Icon(
            Icons.event_available,
            size: size * 0.55,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _BundledBrandImage extends StatelessWidget {
  const _BundledBrandImage({
    required this.path,
    required this.size,
    required this.selected,
    required this.fallbackIcon,
    this.color,
  });

  final String path;
  final double size;
  final bool selected;
  final IconData fallbackIcon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: selected ? 1 : 0.78,
      child: ClipOval(
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              Icon(fallbackIcon, size: size, color: color),
        ),
      ),
    );
  }
}
