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
                  GoRoute(
                    path: 'appearance',
                    name: 'settings-appearance',
                    builder: (context, state) => const SettingsCategoryPage(
                      category: SettingsCategory.appearance,
                    ),
                    routes: <RouteBase>[
                      for (final leaf in <SettingsLeaf>[
                        SettingsLeaf.theme,
                        SettingsLeaf.background,
                        SettingsLeaf.appIcon,
                        SettingsLeaf.language,
                      ])
                        GoRoute(
                          path: _settingsLeafPath(leaf),
                          name: 'settings-appearance-${leaf.name}',
                          builder: (context, state) =>
                              SettingsLeafPage(leaf: leaf),
                        ),
                    ],
                  ),
                  GoRoute(
                    path: 'ai',
                    name: 'settings-ai',
                    builder: (context, state) => const SettingsCategoryPage(
                      category: SettingsCategory.ai,
                    ),
                    routes: <RouteBase>[
                      for (final leaf in <SettingsLeaf>[
                        SettingsLeaf.providers,
                        SettingsLeaf.personas,
                        SettingsLeaf.permissions,
                        SettingsLeaf.chat,
                      ])
                        GoRoute(
                          path: _settingsLeafPath(leaf),
                          name: 'settings-ai-${leaf.name}',
                          builder: (context, state) =>
                              SettingsLeafPage(leaf: leaf),
                        ),
                    ],
                  ),
                  GoRoute(
                    path: 'schedule',
                    name: 'settings-schedule',
                    builder: (context, state) => const SettingsCategoryPage(
                      category: SettingsCategory.schedule,
                    ),
                    routes: <RouteBase>[
                      for (final leaf in <SettingsLeaf>[
                        SettingsLeaf.notifications,
                        SettingsLeaf.categories,
                        SettingsLeaf.holidays,
                      ])
                        GoRoute(
                          path: _settingsLeafPath(leaf),
                          name: 'settings-schedule-${leaf.name}',
                          builder: (context, state) =>
                              SettingsLeafPage(leaf: leaf),
                        ),
                    ],
                  ),
                  GoRoute(
                    path: 'time',
                    name: 'settings-time',
                    builder: (context, state) => const SettingsCategoryPage(
                      category: SettingsCategory.time,
                    ),
                    routes: <RouteBase>[
                      for (final leaf in <SettingsLeaf>[
                        SettingsLeaf.weather,
                        SettingsLeaf.digest,
                      ])
                        GoRoute(
                          path: _settingsLeafPath(leaf),
                          name: 'settings-time-${leaf.name}',
                          builder: (context, state) =>
                              SettingsLeafPage(leaf: leaf),
                        ),
                    ],
                  ),
                  GoRoute(
                    path: 'data',
                    name: 'settings-data',
                    builder: (context, state) => const SettingsCategoryPage(
                      category: SettingsCategory.data,
                    ),
                    routes: <RouteBase>[
                      for (final leaf in <SettingsLeaf>[
                        SettingsLeaf.backup,
                        SettingsLeaf.sync,
                      ])
                        GoRoute(
                          path: _settingsLeafPath(leaf),
                          name: 'settings-data-${leaf.name}',
                          builder: (context, state) =>
                              SettingsLeafPage(leaf: leaf),
                        ),
                    ],
                  ),
                  GoRoute(
                    path: 'widget',
                    name: 'settings-widget',
                    builder: (context, state) =>
                        const SettingsLeafPage(leaf: SettingsLeaf.widget),
                  ),
                  GoRoute(
                    path: 'about',
                    name: 'settings-about',
                    builder: (context, state) =>
                        const SettingsLeafPage(leaf: SettingsLeaf.about),
                  ),
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

String _settingsLeafPath(SettingsLeaf leaf) => switch (leaf) {
      SettingsLeaf.theme => 'theme',
      SettingsLeaf.background => 'background',
      SettingsLeaf.appIcon => 'app-icon',
      SettingsLeaf.language => 'language',
      SettingsLeaf.providers => 'providers',
      SettingsLeaf.personas => 'personas',
      SettingsLeaf.permissions => 'permissions',
      SettingsLeaf.chat => 'chat',
      SettingsLeaf.notifications => 'notifications',
      SettingsLeaf.categories => 'categories',
      SettingsLeaf.holidays => 'holidays',
      SettingsLeaf.weather => 'weather',
      SettingsLeaf.digest => 'digest',
      SettingsLeaf.backup => 'backup',
      SettingsLeaf.sync => 'sync',
      SettingsLeaf.widget || SettingsLeaf.about => leaf.name,
    };
