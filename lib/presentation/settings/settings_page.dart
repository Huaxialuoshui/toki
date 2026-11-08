import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/ai/tool_permissions.dart';
import '../../application/notification/notification_providers.dart';
import '../../application/settings/settings_controller.dart';
import '../../application/theme/theme_controller.dart';
import '../../application/theme/theme_presets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/theme_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/brand_icon.dart';
import '../widgets/page_scaffold.dart';
import 'ai_persona_section.dart';
import 'ai_provider_section.dart';
import 'app_appearance_section.dart';
import 'app_icon_section.dart';
import 'backup_section.dart';
import 'calendar_category_section.dart';
import 'chat_appearance_section.dart';
import 'digest_section.dart';
import 'holiday_section.dart';
import 'sync_section.dart';
import 'weather_section.dart';
import 'widget_section.dart';

/// Settings home: a compact, category-first menu.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = <_SettingsMenuGroup>[
      _SettingsMenuGroup(
        title: l10n.settingsGroupPersonalize,
        items: <_SettingsMenuItem>[
          _SettingsMenuItem(
            keyName: 'settings-menu-appearance',
            route: '/settings/appearance',
            icon: Icons.palette_outlined,
            title: l10n.settingsAppearance,
            subtitle: l10n.settingsAppearanceMenuHint,
          ),
          _SettingsMenuItem(
            keyName: 'settings-menu-ai',
            route: '/settings/ai',
            icon: Icons.auto_awesome_outlined,
            title: l10n.settingsAiMenuTitle,
            subtitle: l10n.settingsAiMenuHint,
          ),
        ],
      ),
      _SettingsMenuGroup(
        title: l10n.settingsGroupSchedule,
        items: <_SettingsMenuItem>[
          _SettingsMenuItem(
            keyName: 'settings-menu-schedule',
            route: '/settings/schedule',
            icon: Icons.event_note_outlined,
            title: l10n.settingsScheduleMenuTitle,
            subtitle: l10n.settingsScheduleMenuHint,
          ),
          _SettingsMenuItem(
            keyName: 'settings-menu-time',
            route: '/settings/time',
            icon: Icons.wb_sunny_outlined,
            title: l10n.settingsTimeMenuTitle,
            subtitle: l10n.settingsTimeMenuHint,
          ),
          _SettingsMenuItem(
            keyName: 'settings-menu-widget',
            route: '/settings/widget',
            icon: Icons.widgets_outlined,
            title: l10n.widgetSection,
            subtitle: l10n.settingsWidgetMenuHint,
          ),
        ],
      ),
      _SettingsMenuGroup(
        title: l10n.settingsGroupSystem,
        items: <_SettingsMenuItem>[
          _SettingsMenuItem(
            keyName: 'settings-menu-data',
            route: '/settings/data',
            icon: Icons.storage_outlined,
            title: l10n.settingsDataMenuTitle,
            subtitle: l10n.settingsDataMenuHint,
          ),
          _SettingsMenuItem(
            keyName: 'settings-menu-about',
            route: '/settings/about',
            icon: Icons.info_outline,
            title: l10n.settingsAbout,
            subtitle: l10n.settingsAboutMenuHint,
          ),
        ],
      ),
    ];

    return PageScaffold(
      title: l10n.navSettings,
      subtitle: l10n.settingsMenuSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SettingsIdentityCard(),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final columns = constraints.maxWidth >= 840 ? 2 : 1;
              final gap = columns == 1 ? 0.0 : 14.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: 14,
                children: <Widget>[
                  for (final group in groups)
                    SizedBox(
                        width: width, child: _SettingsMenuGroupCard(group)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

enum SettingsCategory { appearance, ai, schedule, time, data }

class SettingsCategoryPage extends StatelessWidget {
  const SettingsCategoryPage({super.key, required this.category});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, subtitle, items) = switch (category) {
      SettingsCategory.appearance => (
          l10n.settingsAppearance,
          l10n.settingsAppearanceSubtitle,
          <_SettingsMenuItem>[
            _SettingsMenuItem(
              keyName: 'settings-appearance-theme',
              route: '/settings/appearance/theme',
              icon: Icons.palette_outlined,
              title: l10n.settingsTheme,
              subtitle: l10n.settingsThemeMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-appearance-background',
              route: '/settings/appearance/background',
              icon: Icons.wallpaper_outlined,
              title: l10n.settingsVisualSection,
              subtitle: l10n.settingsBackgroundMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-appearance-app-icon',
              route: '/settings/appearance/app-icon',
              icon: Icons.apps_outlined,
              title: l10n.appIcon,
              subtitle: l10n.settingsAppIconMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-appearance-language',
              route: '/settings/appearance/language',
              icon: Icons.translate_outlined,
              title: l10n.settingsLanguage,
              subtitle: l10n.settingsLanguageMenuHint,
            ),
          ],
        ),
      SettingsCategory.ai => (
          l10n.settingsAiMenuTitle,
          l10n.settingsAiSubtitle,
          <_SettingsMenuItem>[
            _SettingsMenuItem(
              keyName: 'settings-ai-providers',
              route: '/settings/ai/providers',
              icon: Icons.hub_outlined,
              title: l10n.settingsAiSection,
              subtitle: l10n.settingsProviderMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-ai-personas',
              route: '/settings/ai/personas',
              icon: Icons.face_retouching_natural_outlined,
              title: l10n.aiPersonaSectionTitle,
              subtitle: l10n.settingsPersonaMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-ai-permissions',
              route: '/settings/ai/permissions',
              icon: Icons.verified_user_outlined,
              title: l10n.aiPermissionSection,
              subtitle: l10n.settingsPermissionMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-ai-chat',
              route: '/settings/ai/chat',
              icon: Icons.chat_bubble_outline,
              title: l10n.chatAppearanceSection,
              subtitle: l10n.settingsChatAppearanceMenuHint,
            ),
          ],
        ),
      SettingsCategory.schedule => (
          l10n.settingsScheduleMenuTitle,
          l10n.settingsScheduleSubtitle,
          <_SettingsMenuItem>[
            _SettingsMenuItem(
              keyName: 'settings-schedule-notifications',
              route: '/settings/schedule/notifications',
              icon: Icons.notifications_active_outlined,
              title: l10n.settingsNotificationSection,
              subtitle: l10n.settingsNotificationMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-schedule-categories',
              route: '/settings/schedule/categories',
              icon: Icons.category_outlined,
              title: l10n.calendarCategorySection,
              subtitle: l10n.settingsCalendarCategoryMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-schedule-holidays',
              route: '/settings/schedule/holidays',
              icon: Icons.wb_sunny_outlined,
              title: l10n.calendarHolidaySection,
              subtitle: l10n.settingsHolidayMenuHint,
            ),
          ],
        ),
      SettingsCategory.time => (
          l10n.settingsTimeMenuTitle,
          l10n.settingsTimeSubtitle,
          <_SettingsMenuItem>[
            _SettingsMenuItem(
              keyName: 'settings-time-weather',
              route: '/settings/time/weather',
              icon: Icons.wb_cloudy_outlined,
              title: l10n.weatherSection,
              subtitle: l10n.settingsWeatherMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-time-digest',
              route: '/settings/time/digest',
              icon: Icons.auto_awesome_outlined,
              title: l10n.digestSection,
              subtitle: l10n.settingsDigestMenuHint,
            ),
          ],
        ),
      SettingsCategory.data => (
          l10n.settingsDataMenuTitle,
          l10n.settingsDataSubtitle,
          <_SettingsMenuItem>[
            _SettingsMenuItem(
              keyName: 'settings-data-backup',
              route: '/settings/data/backup',
              icon: Icons.save_alt_outlined,
              title: l10n.settingsBackupSection,
              subtitle: l10n.settingsBackupMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-data-sync',
              route: '/settings/data/sync',
              icon: Icons.cloud_sync_outlined,
              title: l10n.syncSection,
              subtitle: l10n.settingsSyncMenuHint,
            ),
            _SettingsMenuItem(
              keyName: 'settings-data-about',
              route: '/settings/about',
              icon: Icons.info_outline,
              title: l10n.settingsAbout,
              subtitle: l10n.settingsAboutMenuHint,
            ),
          ],
        ),
    };

    return _SettingsSubpage(
      title: title,
      subtitle: subtitle,
      child: _SettingsMenuGroupCard(
        _SettingsMenuGroup(title: title, items: items, showTitle: false),
      ),
    );
  }
}

enum SettingsLeaf {
  theme,
  background,
  appIcon,
  language,
  providers,
  personas,
  permissions,
  chat,
  notifications,
  categories,
  holidays,
  weather,
  digest,
  widget,
  backup,
  sync,
  about,
}

class SettingsLeafPage extends StatelessWidget {
  const SettingsLeafPage({super.key, required this.leaf});

  final SettingsLeaf leaf;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, subtitle, child) = switch (leaf) {
      SettingsLeaf.theme => (
          l10n.settingsTheme,
          l10n.settingsThemeMenuHint,
          const _ThemeSettingsCard(),
        ),
      SettingsLeaf.background => (
          l10n.settingsVisualSection,
          l10n.settingsBackgroundMenuHint,
          const AppAppearanceSection(),
        ),
      SettingsLeaf.appIcon => (
          l10n.appIcon,
          l10n.settingsAppIconMenuHint,
          const AppIconSection(),
        ),
      SettingsLeaf.language => (
          l10n.settingsLanguage,
          l10n.settingsLanguageMenuHint,
          const _LanguageCard(),
        ),
      SettingsLeaf.providers => (
          l10n.settingsAiSection,
          l10n.settingsProviderMenuHint,
          const AiProviderSection(),
        ),
      SettingsLeaf.personas => (
          l10n.aiPersonaSectionTitle,
          l10n.settingsPersonaMenuHint,
          const AiPersonaSection(),
        ),
      SettingsLeaf.permissions => (
          l10n.aiPermissionSection,
          l10n.settingsPermissionMenuHint,
          const _AiPermissionCard(),
        ),
      SettingsLeaf.chat => (
          l10n.chatAppearanceSection,
          l10n.settingsChatAppearanceMenuHint,
          const ChatAppearanceSection(),
        ),
      SettingsLeaf.notifications => (
          l10n.settingsNotificationSection,
          l10n.settingsNotificationMenuHint,
          const _NotificationCard(),
        ),
      SettingsLeaf.categories => (
          l10n.calendarCategorySection,
          l10n.settingsCalendarCategoryMenuHint,
          const CalendarCategorySection(),
        ),
      SettingsLeaf.holidays => (
          l10n.calendarHolidaySection,
          l10n.settingsHolidayMenuHint,
          const HolidaySection(),
        ),
      SettingsLeaf.weather => (
          l10n.weatherSection,
          l10n.settingsWeatherMenuHint,
          const WeatherSection(),
        ),
      SettingsLeaf.digest => (
          l10n.digestSection,
          l10n.settingsDigestMenuHint,
          const DigestSection(),
        ),
      SettingsLeaf.widget => (
          l10n.widgetSection,
          l10n.settingsWidgetMenuHint,
          const WidgetSection(),
        ),
      SettingsLeaf.backup => (
          l10n.settingsBackupSection,
          l10n.settingsBackupMenuHint,
          const BackupSection(),
        ),
      SettingsLeaf.sync => (
          l10n.syncSection,
          l10n.settingsSyncMenuHint,
          const SyncSection(),
        ),
      SettingsLeaf.about => (
          l10n.settingsAbout,
          l10n.settingsAboutMenuHint,
          const _AboutCard(),
        ),
    };

    return _SettingsSubpage(
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}

class _SettingsSubpage extends StatelessWidget {
  const _SettingsSubpage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      subtitle: subtitle,
      leading: IconButton(
        key: const ValueKey<String>('settings-back'),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/settings');
          }
        },
        icon: const Icon(Icons.arrow_back),
      ),
      child: child,
    );
  }
}

class _SettingsIdentityCard extends StatelessWidget {
  const _SettingsIdentityCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        children: <Widget>[
          const BrandAppIcon(size: 62, radius: 17),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.settingsAboutDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'v${AppConstants.appVersion}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuGroup {
  const _SettingsMenuGroup({
    required this.title,
    required this.items,
    this.showTitle = true,
  });

  final String title;
  final List<_SettingsMenuItem> items;
  final bool showTitle;
}

class _SettingsMenuItem {
  const _SettingsMenuItem({
    required this.keyName,
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String keyName;
  final String route;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _SettingsMenuGroupCard extends StatelessWidget {
  const _SettingsMenuGroupCard(this.group);

  final _SettingsMenuGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (group.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                group.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          for (final item in group.items)
            _SettingsMenuTile(
              key: ValueKey<String>(item.keyName),
              item: item,
            ),
        ],
      ),
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({super.key, required this.item});

  final _SettingsMenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);
    return GlassCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          ChoiceChip(
            label: Text(l10n.settingsLanguageFollowSystem),
            selected: locale == null,
            onSelected: (_) =>
                ref.read(localeControllerProvider.notifier).followSystem(),
          ),
          ChoiceChip(
            label: Text(l10n.settingsLanguageChinese),
            selected: locale?.languageCode == 'zh',
            onSelected: (_) => ref
                .read(localeControllerProvider.notifier)
                .setLocale(const Locale('zh')),
          ),
          ChoiceChip(
            label: Text(l10n.settingsLanguageEnglish),
            selected: locale?.languageCode == 'en',
            onSelected: (_) => ref
                .read(localeControllerProvider.notifier)
                .setLocale(const Locale('en')),
          ),
        ],
      ),
    );
  }
}

class _ThemeSettingsCard extends ConsumerWidget {
  const _ThemeSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final themeState = ref.watch(themeControllerProvider);
    final controllers = ref.read(themeControllerProvider.notifier);
    final userThemes =
        ref.watch(userThemesProvider).valueOrNull ?? const <ThemeConfig>[];
    final currentIsUserTheme =
        userThemes.any((ThemeConfig item) => item.id == themeState.themeId);
    final effectiveRadius =
        themeState.borderRadius ?? themeState.preset.borderRadius;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _FieldLabel(text: l10n.settingsTheme),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(l10n.settingsThemeFollowSystem),
                selected: themeState.followSystem,
                onSelected: (_) => controllers.setFollowSystem(true),
              ),
              for (final preset in ThemePresets.all)
                ChoiceChip(
                  label: Text(_themeLabel(l10n, preset.id)),
                  selected: !themeState.followSystem &&
                      themeState.themeId == preset.id,
                  onSelected: (_) => controllers.selectTheme(preset.id),
                ),
              for (final userTheme in userThemes)
                ChoiceChip(
                  avatar: Icon(
                    Icons.bookmark_outline,
                    size: 16,
                    color: !themeState.followSystem &&
                            themeState.themeId == userTheme.id
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  label: Text(userTheme.name),
                  selected: !themeState.followSystem &&
                      themeState.themeId == userTheme.id,
                  onSelected: (_) => controllers.selectTheme(userTheme.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => _openThemeEditor(
                  context,
                  editingId: currentIsUserTheme ? themeState.themeId : null,
                ),
                icon: const Icon(Icons.tune_outlined, size: 18),
                label: Text(l10n.themeEditCurrent),
              ),
              OutlinedButton.icon(
                onPressed: () => _openThemeEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.themeNew),
              ),
            ],
          ),
          if (userThemes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _FieldLabel(text: l10n.themeMyThemes),
            for (final userTheme in userThemes)
              Row(
                children: <Widget>[
                  Icon(
                    Icons.bookmark_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userTheme.name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: ValueKey<String>(
                      'delete-theme-${userTheme.id}',
                    ),
                    tooltip: l10n.calendarDelete,
                    onPressed: () =>
                        _confirmDeleteTheme(context, ref, userTheme),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 20),
          _FieldLabel(
            text:
                '${l10n.settingsFontScale} · ${themeState.fontScale.toStringAsFixed(2)}×',
          ),
          Slider(
            value: themeState.fontScale,
            min: ThemeController.minFontScale,
            max: ThemeController.maxFontScale,
            divisions: 8,
            label: '${themeState.fontScale.toStringAsFixed(2)}×',
            onChanged: controllers.setFontScale,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _FieldLabel(
                  text:
                      '${l10n.settingsCornerRadius} · ${effectiveRadius.toStringAsFixed(0)}',
                ),
              ),
              TextButton(
                onPressed: controllers.resetBorderRadius,
                child: Text(l10n.settingsReset),
              ),
            ],
          ),
          Slider(
            value: effectiveRadius.clamp(
              ThemeController.minBorderRadius,
              ThemeController.maxBorderRadius,
            ),
            min: ThemeController.minBorderRadius,
            max: ThemeController.maxBorderRadius,
            divisions: 16,
            label: effectiveRadius.toStringAsFixed(0),
            onChanged: controllers.setBorderRadius,
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case ThemePresets.lightId:
        return l10n.settingsThemeLight;
      case ThemePresets.darkId:
        return l10n.settingsThemeDark;
      default:
        return l10n.settingsThemeDefault;
    }
  }

  void _openThemeEditor(BuildContext context, {String? editingId}) {
    final String query = editingId == null
        ? ''
        : '?editingId=${Uri.encodeQueryComponent(editingId)}';
    context.push('/settings/theme-editor$query');
  }

  Future<void> _confirmDeleteTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeConfig themeConfig,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final selected = ref.read(themeControllerProvider).themeId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.calendarDeleteConfirmTitle),
        content: Text(l10n.themeDeleteConfirmBody(themeConfig.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.calendarDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(themeRepositoryProvider).deleteById(themeConfig.id);
    if (selected == themeConfig.id) {
      ref
          .read(themeControllerProvider.notifier)
          .selectTheme(ThemePresets.defaultId);
    }
    messenger?.showSnackBar(SnackBar(content: Text(l10n.themeDeleted)));
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BrandAppIcon(size: 52, radius: 14),
              const SizedBox(width: 12),
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
                      l10n.settingsAboutDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _InfoRow(
            label: l10n.settingsVersion,
            value: AppConstants.appVersion,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsLocalDataNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: l10n.appName,
                applicationVersion: AppConstants.appVersion,
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text(l10n.settingsOpenSourceLicenses),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AiPermissionCard extends ConsumerWidget {
  const _AiPermissionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final permissions = ref.watch(toolPermissionsProvider);
    final controller = ref.read(toolPermissionsProvider.notifier);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiPermissionRead),
            value: permissions.allowRead,
            onChanged: controller.setRead,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiPermissionCreate),
            value: permissions.allowCreate,
            onChanged: controller.setCreate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiPermissionUpdate),
            value: permissions.allowUpdate,
            onChanged: controller.setUpdate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiPermissionDelete),
            subtitle: Text(
              l10n.aiPermissionHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: permissions.allowDelete,
            onChanged: controller.setDelete,
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerStatefulWidget {
  const _NotificationCard();

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool? _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final service = ref.read(notificationServiceProvider);
    final enabled = await service.areNotificationsEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  Future<void> _requestPermission() async {
    setState(() => _busy = true);
    await ref.read(notificationServiceProvider).requestPermission();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _sendTestNotification() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    final service = ref.read(notificationServiceProvider);
    await service.initialize();
    await service.scheduleNotification(
      id: 1,
      title: l10n.appName,
      body: l10n.notificationDefaultBody,
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.settingsNotificationTestSent)),
    );
  }

  Future<void> _requestExactAlarm() async {
    setState(() => _busy = true);
    await ref.read(notificationServiceProvider).requestExactAlarmPermission();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final allowed = _enabled ?? false;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.settingsNotificationSectionSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                l10n.settingsNotificationPermission,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allowed
                      ? theme.colorScheme.primary.withValues(alpha: 0.14)
                      : theme.colorScheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  allowed
                      ? l10n.settingsNotificationPermissionGranted
                      : l10n.settingsNotificationPermissionDenied,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: allowed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _busy ? null : _requestPermission,
                icon: const Icon(Icons.notifications_none, size: 18),
                label: Text(l10n.settingsNotificationRequest),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _requestExactAlarm,
                icon: const Icon(Icons.alarm_on_outlined, size: 18),
                label: Text(l10n.settingsNotificationExactAlarm),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _sendTestNotification,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text(l10n.settingsNotificationTest),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.settingsNotificationExactAlarmHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
