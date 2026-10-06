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

List<ShellDestination> buildShellDestinations(AppLocalizations l10n) {
  return <ShellDestination>[
    ShellDestination(
      route: '/home',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: l10n.navHome,
    ),
    ShellDestination(
      route: '/calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: l10n.navCalendar,
    ),
    ShellDestination(
      route: '/countdown',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
      label: l10n.navCountdown,
    ),
    ShellDestination(
      route: '/ai',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      label: l10n.navAi,
    ),
    ShellDestination(
      route: '/settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: l10n.navSettings,
    ),
  ];
}
