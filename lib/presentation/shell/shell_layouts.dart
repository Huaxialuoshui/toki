import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import 'shell_destination.dart';

/// 测试用：三档布局的根 Key。
const Key kMobileShellKey = Key('shell-mobile');
const Key kTabletShellKey = Key('shell-tablet');
const Key kDesktopShellKey = Key('shell-desktop');
const Key kSidebarToggleKey = Key('shell-sidebar-toggle');

/// 手机布局：底部导航 + 内容。
class MobileShell extends StatelessWidget {
  const MobileShell({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
  });

  final List<ShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: kMobileShellKey,
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelect,
        destinations: <Widget>[
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

/// 平板布局：侧边 Rail（仅图标 + 标签）+ 内容。
class TabletShell extends StatelessWidget {
  const TabletShell({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
  });

  final List<ShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: kTabletShellKey,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// 桌面布局：可折叠 Sidebar + 内容。
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final List<ShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget body;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: kDesktopShellKey,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: AppConstants.layoutAnimation,
              width: collapsed
                  ? AppConstants.sidebarCollapsedWidth
                  : AppConstants.sidebarWidth,
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.event_available,
                          color: theme.colorScheme.primary,
                        ),
                        if (!collapsed) ...<Widget>[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.appName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  l10n.appTagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  for (var index = 0; index < destinations.length; index++)
                    _SidebarTile(
                      key: ValueKey<String>(
                        'sidebar-tile-${destinations[index].route}',
                      ),
                      destination: destinations[index],
                      selected: index == currentIndex,
                      collapsed: collapsed,
                      onTap: () => onSelect(index),
                    ),
                  const Spacer(),
                  const Divider(height: 1),
                  Align(
                    alignment: collapsed
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: IconButton(
                      key: kSidebarToggleKey,
                      onPressed: onToggleCollapsed,
                      icon: Icon(
                        collapsed
                            ? Icons.keyboard_double_arrow_right
                            : Icons.keyboard_double_arrow_left,
                      ),
                      tooltip: l10n.navSettings,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    super.key,
    required this.destination,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.78);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 20,
                  color: foreground,
                ),
                if (!collapsed) ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
