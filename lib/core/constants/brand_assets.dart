/// Bundled brand artwork.
///
/// The finished set is the current default. The original set stays in the
/// bundle so users can switch back without losing their custom choices.
abstract final class BrandAssets {
  static const String _newRoot = 'assets/brand/new';
  static const String _classicRoot = 'assets/brand/classic';

  static const Map<String, String> newNavigationIcons = <String, String>{
    '/home': '$_newRoot/nav_home.png',
    '/calendar': '$_newRoot/nav_calendar.png',
    '/countdown': '$_newRoot/nav_countdown.png',
    '/ai': '$_newRoot/nav_ai.png',
    '/settings': '$_newRoot/nav_settings.png',
  };

  static const Map<String, String> classicNavigationIcons = <String, String>{
    '/home': '$_classicRoot/nav_home.png',
    '/calendar': '$_classicRoot/nav_calendar.png',
    '/countdown': '$_classicRoot/nav_countdown.png',
    '/ai': '$_classicRoot/nav_ai.png',
    '/settings': '$_classicRoot/nav_settings.png',
  };

  static const String newAppIcon = '$_newRoot/app_icon.png';
  static const String classicAppIcon = '$_classicRoot/app_icon.png';

  static const String newAssistantAvatar1 = '$_newRoot/assistant_avatar_1.png';
  static const String newAssistantAvatar2 = '$_newRoot/assistant_avatar_2.png';
  static const String classicAssistantAvatar1 =
      '$_classicRoot/assistant_avatar_1.png';
  static const String classicAssistantAvatar2 =
      '$_classicRoot/assistant_avatar_2.png';

  /// Values stored by settings use this prefix so they survive app upgrades
  /// and do not depend on a cache path.
  static String assetValue(String assetPath) => 'asset:$assetPath';

  static String navigationAsset(String? storedPath, String route) {
    final value = storedPath?.trim();
    if (value != null && value.isNotEmpty) return value;
    return newNavigationIcons[route] ?? newAppIcon;
  }
}
