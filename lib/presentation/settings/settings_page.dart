import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/settings/settings_controller.dart';
import '../../application/notification/notification_providers.dart';
import '../../application/theme/theme_controller.dart';
import '../../application/theme/theme_presets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/theme_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import 'ai_provider_section.dart';
import 'ai_persona_section.dart';
import 'backup_section.dart';
import 'chat_appearance_section.dart';
import '../../application/ai/tool_permissions.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';

/// 设置页：外观、语言、关于，以及后续阶段的功能占位。
///
/// 这里的选择只写入 shared_preferences（应用级轻量设置），不涉及数据库。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final themeState = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final controllers = ref.read(themeControllerProvider.notifier);
    final userThemes =
        ref.watch(userThemesProvider).valueOrNull ?? const <ThemeConfig>[];
    final currentIsUserTheme =
        userThemes.any((ThemeConfig item) => item.id == themeState.themeId);
    final effectiveRadius =
        themeState.borderRadius ?? themeState.preset.borderRadius;

    return PageScaffold(
      title: l10n.navSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(
            title: l10n.settingsAppearance,
            icon: Icons.palette_outlined,
          ),
          GlassCard(
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
                    // 用户自建 / 导入的主题（存在数据库里）。
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
                        onSelected: (_) =>
                            controllers.selectTheme(userTheme.id),
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
                        editingId:
                            currentIsUserTheme ? themeState.themeId : null,
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
                // 用户主题列表：逐条删除（内置预设不可删除）。
                if (userThemes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  _FieldLabel(text: l10n.themeMyThemes),
                  for (final userTheme in userThemes)
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.bookmark_outline,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
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
                          key: ValueKey<String>('delete-theme-${userTheme.id}'),
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
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: l10n.settingsLanguage,
            icon: Icons.translate_outlined,
          ),
          GlassCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(l10n.settingsLanguageFollowSystem),
                  selected: locale == null,
                  onSelected: (_) => ref
                      .read(localeControllerProvider.notifier)
                      .followSystem(),
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
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: l10n.settingsAiSection,
            icon: Icons.smart_toy_outlined,
          ),
          const AiProviderSection(),
          const SizedBox(height: 16),
          SectionHeader(
            title: l10n.aiPersonaSectionTitle,
            icon: Icons.face_retouching_natural_outlined,
          ),
          const AiPersonaSection(),
          const SizedBox(height: 16),
          SectionHeader(
            title: l10n.aiPermissionSection,
            icon: Icons.verified_user_outlined,
          ),
          const _AiPermissionCard(),
          const SizedBox(height: 16),
          SectionHeader(
            title: l10n.chatAppearanceSection,
            icon: Icons.chat_bubble_outline,
          ),
          const ChatAppearanceSection(),
          const SizedBox(height: 16),
          SectionHeader(
            title: l10n.settingsNotificationSection,
            icon: Icons.notifications_active_outlined,
          ),
          const _NotificationCard(),
          const SizedBox(height: 16),
          SectionHeader(
            title: l10n.settingsBackupSection,
            icon: Icons.save_alt_outlined,
          ),
          const BackupSection(),
          const SizedBox(height: 24),
          SectionHeader(
            title: l10n.settingsAbout,
            icon: Icons.info_outline,
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoRow(
                  label: l10n.settingsVersion,
                  value: AppConstants.appVersion,
                ),
                _InfoRow(
                  label: l10n.settingsFlutterVersion,
                  value: AppConstants.flutterSdkVersion,
                ),
                _InfoRow(
                  label: l10n.settingsDartVersion,
                  value: Platform.version.split(' ').first,
                ),
                _InfoRow(
                  label: l10n.settingsProjectPath,
                  value: Directory.current.path,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsPhaseNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
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

  /// 打开主题编辑器；[editingId] 为空表示"基于当前主题新建"。
  void _openThemeEditor(BuildContext context, {String? editingId}) {
    final String query = editingId == null
        ? ''
        : '?editingId=${Uri.encodeQueryComponent(editingId)}';
    context.push('/settings/theme-editor$query');
  }

  /// 删除一个用户主题；若当前正选中它，回落到默认预设。
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
      ref.read(themeControllerProvider.notifier).selectTheme(
            ThemePresets.defaultId,
          );
    }
    messenger?.showSnackBar(SnackBar(content: Text(l10n.themeDeleted)));
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

/// 通知设置：权限状态 + 请求权限 + 发送测试通知。
/// AI 工具权限开关（查询 / 创建 / 修改 / 删除）。
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
