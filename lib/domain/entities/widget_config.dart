import 'package:flutter/foundation.dart';

/// 桌面小组件的背景类型。
enum WidgetSkin {
  solid('solid'),
  gradient('gradient'),
  image('image');

  const WidgetSkin(this.storageValue);
  final String storageValue;

  static WidgetSkin parse(Object? raw) {
    for (final skin in WidgetSkin.values) {
      if (skin.storageValue == raw) return skin;
    }
    return WidgetSkin.solid;
  }
}

/// 小组件图标风格（和主题里的"图标风格"共用一套语义）。
enum WidgetIconStyle {
  outlined('outlined'),
  filled('filled');

  const WidgetIconStyle(this.storageValue);
  final String storageValue;

  static WidgetIconStyle parse(Object? raw) =>
      raw == 'filled' ? WidgetIconStyle.filled : WidgetIconStyle.outlined;
}

/// 小组件外观（皮肤 / 图标 / 背景图片 / 圆角 / 配色）。
@immutable
class WidgetConfig {
  const WidgetConfig({
    this.skin = WidgetSkin.solid,
    this.backgroundColor = 0xFF171A24,
    this.gradientStart = 0xFF1F2440,
    this.gradientEnd = 0xFF101320,
    this.imagePath,
    this.imageOverlay = 0x66000000,
    this.textColor = 0xFFECF0F8,
    this.accentColor = 0xFF12B5A5,
    this.iconStyle = WidgetIconStyle.outlined,
    this.cornerRadius = 24,
    this.transparent = false,
    this.showCountdown = true,
    this.showEvent = true,
    this.autoRefresh = true,
    this.refreshIntervalMinutes = 15,
    this.dailyRefreshHour = 7,
    this.dailyRefreshMinute = 0,
  });

  final WidgetSkin skin;
  final int backgroundColor;
  final int gradientStart;
  final int gradientEnd;

  /// 背景图片在本机文件系统里的路径（由应用复制到私有目录）。
  final String? imagePath;
  final int imageOverlay;

  final int textColor;
  final int accentColor;
  final WidgetIconStyle iconStyle;
  final int cornerRadius;

  /// 半透明背景（保留圆角外的透明区域）。
  final bool transparent;

  /// 小组件上显示的内容。
  final bool showCountdown;
  final bool showEvent;

  /// 是否由 Android 的 AlarmManager 自动重绘小组件。
  final bool autoRefresh;

  /// 自动刷新间隔；1440 表示每天一次。
  final int refreshIntervalMinutes;

  /// 每天一次模式下的本地刷新时间。
  final int dailyRefreshHour;
  final int dailyRefreshMinute;

  bool get refreshesDaily => refreshIntervalMinutes >= 24 * 60;

  /// 可选刷新频率（分钟）。15 分钟是 Android 的合理下限。
  static const List<int> refreshIntervalOptions = <int>[
    15,
    30,
    60,
    180,
    360,
    720,
    1440,
  ];

  WidgetConfig copyWith({
    WidgetSkin? skin,
    int? backgroundColor,
    int? gradientStart,
    int? gradientEnd,
    String? imagePath,
    bool clearImage = false,
    int? imageOverlay,
    int? textColor,
    int? accentColor,
    WidgetIconStyle? iconStyle,
    int? cornerRadius,
    bool? transparent,
    bool? showCountdown,
    bool? showEvent,
    bool? autoRefresh,
    int? refreshIntervalMinutes,
    int? dailyRefreshHour,
    int? dailyRefreshMinute,
  }) {
    return WidgetConfig(
      skin: skin ?? this.skin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      imageOverlay: imageOverlay ?? this.imageOverlay,
      textColor: textColor ?? this.textColor,
      accentColor: accentColor ?? this.accentColor,
      iconStyle: iconStyle ?? this.iconStyle,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      transparent: transparent ?? this.transparent,
      showCountdown: showCountdown ?? this.showCountdown,
      showEvent: showEvent ?? this.showEvent,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshIntervalMinutes:
          refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      dailyRefreshHour: dailyRefreshHour ?? this.dailyRefreshHour,
      dailyRefreshMinute: dailyRefreshMinute ?? this.dailyRefreshMinute,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'backgroundType': skin.storageValue,
        'backgroundColor': backgroundColor,
        'gradientStart': gradientStart,
        'gradientEnd': gradientEnd,
        'imagePath': imagePath ?? '',
        'imageOverlay': imageOverlay,
        'textColor': textColor,
        'accentColor': accentColor,
        'iconStyle': iconStyle.storageValue,
        'cornerRadius': cornerRadius,
        'opaqueBackground': !transparent,
        'transparent': transparent,
        'backgroundAlpha': transparent ? 200 : 255,
        'showCountdown': showCountdown,
        'showEvent': showEvent,
        'autoRefresh': autoRefresh,
        'refreshIntervalMinutes': refreshIntervalMinutes,
        'dailyRefreshHour': dailyRefreshHour,
        'dailyRefreshMinute': dailyRefreshMinute,
      };

  static WidgetConfig fromJson(Map<String, Object?> json) => WidgetConfig(
        skin: WidgetSkin.parse(json['backgroundType']),
        backgroundColor:
            (json['backgroundColor'] as num?)?.toInt() ?? 0xFF171A24,
        gradientStart: (json['gradientStart'] as num?)?.toInt() ?? 0xFF1F2440,
        gradientEnd: (json['gradientEnd'] as num?)?.toInt() ?? 0xFF101320,
        imagePath: (json['imagePath'] as String?)?.trim().isEmpty ?? true
            ? null
            : json['imagePath'] as String,
        imageOverlay: (json['imageOverlay'] as num?)?.toInt() ?? 0x66000000,
        textColor: (json['textColor'] as num?)?.toInt() ?? 0xFFECF0F8,
        accentColor: (json['accentColor'] as num?)?.toInt() ?? 0xFF12B5A5,
        iconStyle: WidgetIconStyle.parse(json['iconStyle']),
        cornerRadius: (json['cornerRadius'] as num?)?.toInt() ?? 24,
        transparent: json['transparent'] == true,
        showCountdown: json['showCountdown'] != false,
        showEvent: json['showEvent'] != false,
        autoRefresh: json['autoRefresh'] != false,
        refreshIntervalMinutes: _clampRefreshInterval(
          (json['refreshIntervalMinutes'] as num?)?.toInt(),
        ),
        dailyRefreshHour: ((json['dailyRefreshHour'] as num?)?.toInt() ?? 7)
            .clamp(0, 23)
            .toInt(),
        dailyRefreshMinute: ((json['dailyRefreshMinute'] as num?)?.toInt() ?? 0)
            .clamp(0, 59)
            .toInt(),
      );

  static int _clampRefreshInterval(int? raw) {
    if (raw == null) return 15;
    if (raw <= 15) return 15;
    if (raw <= 30) return 30;
    if (raw <= 60) return 60;
    if (raw <= 180) return 180;
    if (raw <= 360) return 360;
    if (raw <= 720) return 720;
    return 1440;
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetConfig &&
      other.skin == skin &&
      other.backgroundColor == backgroundColor &&
      other.gradientStart == gradientStart &&
      other.gradientEnd == gradientEnd &&
      other.imagePath == imagePath &&
      other.imageOverlay == imageOverlay &&
      other.textColor == textColor &&
      other.accentColor == accentColor &&
      other.iconStyle == iconStyle &&
      other.cornerRadius == cornerRadius &&
      other.transparent == transparent &&
      other.showCountdown == showCountdown &&
      other.showEvent == showEvent &&
      other.autoRefresh == autoRefresh &&
      other.refreshIntervalMinutes == refreshIntervalMinutes &&
      other.dailyRefreshHour == dailyRefreshHour &&
      other.dailyRefreshMinute == dailyRefreshMinute;

  @override
  int get hashCode => Object.hash(
        skin,
        backgroundColor,
        gradientStart,
        gradientEnd,
        imagePath,
        imageOverlay,
        textColor,
        accentColor,
        iconStyle,
        cornerRadius,
        transparent,
        showCountdown,
        showEvent,
        autoRefresh,
        refreshIntervalMinutes,
        dailyRefreshHour,
        dailyRefreshMinute,
      );
}
