import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/l10n_extension.dart';
import 'shell_destination.dart';
import 'shell_layouts.dart';

/// App Shell：根据窗口宽度选择手机 / 平板 / 桌面三档布局。
///
/// 三档布局共用同一套页面组件与同一份导航定义，避免"手机 UI 硬套桌面"。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarCollapsed = false;

  void _select(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = buildShellDestinations(context.l10n);
    final currentIndex = widget.navigationShell.currentIndex;
    final body = widget.navigationShell;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < AppConstants.tabletBreakpoint) {
          return MobileShell(
            destinations: destinations,
            currentIndex: currentIndex,
            onSelect: _select,
            body: body,
          );
        }
        if (width < AppConstants.desktopBreakpoint) {
          return TabletShell(
            destinations: destinations,
            currentIndex: currentIndex,
            onSelect: _select,
            body: body,
          );
        }
        return DesktopShell(
          destinations: destinations,
          currentIndex: currentIndex,
          onSelect: _select,
          body: body,
          collapsed: _sidebarCollapsed,
          onToggleCollapsed: () =>
              setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        );
      },
    );
  }
}
