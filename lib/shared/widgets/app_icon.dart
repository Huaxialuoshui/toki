import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/appearance/app_appearance_providers.dart';

/// 按"图标风格"（描边 / 实心）在两种 Material 图标之间切换。
///
/// 规格 §9 要求图标风格可配置；这里覆盖导航、区块标题、首页卡片这些
/// 用户最常看到的位置，其余位置仍用 Material 默认。
class AppIcon extends ConsumerWidget {
  const AppIcon(
    this.outlined,
    this.filled, {
    super.key,
    this.size,
    this.color,
  });

  final IconData outlined;
  final IconData filled;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appIconStyleProvider);
    return Icon(
      style == AppIconStyle.filled ? filled : outlined,
      size: size,
      color: color,
    );
  }
}

/// 描边图标 → 实心图标。只覆盖项目里真正用到的那些。
final Map<IconData, IconData> _filledVariants = <IconData, IconData>{
  Icons.dashboard_outlined: Icons.dashboard,
  Icons.calendar_month_outlined: Icons.calendar_month,
  Icons.timer_outlined: Icons.timer,
  Icons.auto_awesome_outlined: Icons.auto_awesome,
  Icons.settings_outlined: Icons.settings,
  Icons.palette_outlined: Icons.palette,
  Icons.translate_outlined: Icons.translate,
  Icons.smart_toy_outlined: Icons.smart_toy,
  Icons.face_retouching_natural_outlined: Icons.face_retouching_natural,
  Icons.verified_user_outlined: Icons.verified_user,
  Icons.chat_bubble_outline: Icons.chat_bubble,
  Icons.notifications_active_outlined: Icons.notifications_active,
  Icons.category_outlined: Icons.category,
  Icons.wb_cloudy_outlined: Icons.wb_cloudy,
  Icons.cloud_sync_outlined: Icons.cloud_sync,
  Icons.widgets_outlined: Icons.widgets,
  Icons.save_alt_outlined: Icons.save_alt,
  Icons.info_outline: Icons.info,
  Icons.today_outlined: Icons.today,
  Icons.timelapse_outlined: Icons.timelapse,
  Icons.event_outlined: Icons.event,
  Icons.event_note_outlined: Icons.event_note,
  Icons.event_busy_outlined: Icons.event_busy,
  Icons.view_week_outlined: Icons.view_week,
  Icons.tune_outlined: Icons.tune,
  Icons.image_outlined: Icons.image,
  Icons.folder_open_outlined: Icons.folder_open,
  Icons.content_paste_outlined: Icons.content_paste,
  Icons.save_as_outlined: Icons.save_as,
  Icons.auto_awesome_mosaic_outlined: Icons.auto_awesome_mosaic,
  Icons.timeline_outlined: Icons.timeline,
  Icons.forum_outlined: Icons.forum,
  Icons.memory: Icons.memory,
};

/// 按当前图标风格解析一个图标（没有对应实心版本时原样返回）。
IconData resolveAppIcon(IconData icon, AppIconStyle style) {
  if (style != AppIconStyle.filled) return icon;
  return _filledVariants[icon] ?? icon;
}
