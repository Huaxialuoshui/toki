import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/ai/ai_page.dart';
import '../presentation/calendar/calendar_page.dart';
import '../presentation/countdown/countdown_page.dart';
import '../presentation/home/home_page.dart';
import '../presentation/planning/plan_detail_page.dart';
import '../presentation/settings/settings_page.dart';
import '../presentation/settings/theme_editor_page.dart';
import '../presentation/shell/app_shell.dart';
import '../presentation/tasks/task_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// 五个一级页面各自是一个 branch：切换 tab 时保留各自的导航状态与滚动位置。
final goRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'tasks',
                    name: 'tasks',
                    builder: (context, state) => const TaskPage(),
                  ),
                  GoRoute(
                    path: 'plan',
                    name: 'plan',
                    builder: (context, state) => const PlanDetailPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/calendar',
                name: 'calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/countdown',
                name: 'countdown',
                builder: (context, state) => const CountdownPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/ai',
                name: 'ai',
                builder: (context, state) => const AiPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
                routes: <RouteBase>[
                  // 主题编辑器作为设置分支的子路由：手机端保留底部导航，
                  // 桌面端保留侧边栏，方便在编辑时观察整个应用的实时预览。
                  GoRoute(
                    path: 'theme-editor',
                    name: 'theme-editor',
                    builder: (context, state) => ThemeEditorPage(
                      editingId: state.uri.queryParameters['editingId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
