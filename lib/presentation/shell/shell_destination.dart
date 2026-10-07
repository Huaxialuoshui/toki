import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// 一个导航目的地（手机底栏 / 平板 Rail / 桌面 Sidebar 共用同一份定义）。
class ShellDestination {
  const ShellDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

List<ShellDestination> buildShellDestinations(
  AppLocalizations l10n, {
  bool filledIcons = false,
}) {
  ShellDestination of(
    String route,
    IconData outlined,
    IconData filled,
    String label,
  ) =>
      ShellDestination(
        route: route,
        // 实心风格：选不选中都是实心；描边风格：未选中描边、选中实心。
        icon: filledIcons ? filled : outlined,
        selectedIcon: filled,
        label: label,
      );

  return <ShellDestination>[
    of('/home', Icons.dashboard_outlined, Icons.dashboard, l10n.navHome),
    of('/calendar', Icons.calendar_month_outlined, Icons.calendar_month,
        l10n.navCalendar),
    of('/countdown', Icons.timer_outlined, Icons.timer, l10n.navCountdown),
    of('/ai', Icons.auto_awesome_outlined, Icons.auto_awesome, l10n.navAi),
    of('/settings', Icons.settings_outlined, Icons.settings, l10n.navSettings),
  ];
}
