import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../application/theme/theme_controller.dart';
import '../../application/theme/theme_mapper.dart';
import '../../application/theme/theme_presets.dart';
import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/glass_style.dart';
import '../../domain/entities/theme_config.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';

/// 主题编辑器（规格 §11 / Phase 11）。
///
/// 打开期间用 [themeDraftProvider] 让**整个应用**实时跟随草稿预览；
/// 保存后写入 `theme_configs`（用户主题）并选中它。退出时清除草稿。
class ThemeEditorPage extends ConsumerStatefulWidget {
  const ThemeEditorPage({super.key, this.editingId});

  /// 要编辑的用户主题 id；为空时表示"基于当前主题新建"。
  final String? editingId;

  @override
  ConsumerState<ThemeEditorPage> createState() => _ThemeEditorPageState();
}

class _ThemeEditorPageState extends ConsumerState<ThemeEditorPage> {
  late ThemeConfig _draft;
  bool _isUserTheme = false;

  @override
  void initState() {
    super.initState();
    final userThemes =
        ref.read(userThemesProvider).valueOrNull ?? const <ThemeConfig>[];
    final editingId = widget.editingId;

    ThemeConfig? existing;
    if (editingId != null) {
      for (final theme in userThemes) {
        if (theme.id == editingId) existing = theme;
      }
    }
    final selected = ref.read(themeControllerProvider);
    _draft = existing ?? selected.lookupPreset(userThemes);
    _isUserTheme = existing != null;

    // 进入编辑器即开始实时预览。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(themeDraftProvider.notifier).state = _draft;
    });
  }

  void _updateDraft(ThemeConfig next) {
    setState(() => _draft = next);
    ref.read(themeDraftProvider.notifier).state = next;
  }

  void _clearDraft() {
    ref.read(themeDraftProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // 系统返回键 / 手势也要撤销实时预览，否则草稿会残留在全局 provider 里。
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) _clearDraft();
      },
      child: PageScaffold(
        title: l10n.themeEditorTitle,
        subtitle: _draft.name,
        actions: <Widget>[
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close),
            tooltip: l10n.calendarClose,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(title: l10n.themeEditorColors, icon: Icons.palette),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ColourField(
                    fieldKey: 'primary',
                    label: l10n.themeColorPrimary,
                    value: _draft.primaryColor,
                    onPick: (Color color) =>
                        _updateDraft(_draft.copyWith(primaryColor: color)),
                  ),
                  _ColourField(
                    fieldKey: 'secondary',
                    label: l10n.themeColorSecondary,
                    value: _draft.secondaryColor,
                    onPick: (Color color) =>
                        _updateDraft(_draft.copyWith(secondaryColor: color)),
                  ),
                  _ColourField(
                    fieldKey: 'background',
                    label: l10n.themeColorBackground,
                    value: _draft.backgroundColor,
                    onPick: (Color color) =>
                        _updateDraft(_draft.copyWith(backgroundColor: color)),
                  ),
                  _ColourField(
                    fieldKey: 'surface',
                    label: l10n.themeColorSurface,
                    value: _draft.surfaceColor,
                    onPick: (Color color) =>
                        _updateDraft(_draft.copyWith(surfaceColor: color)),
                  ),
                  _ColourField(
                    fieldKey: 'text',
                    label: l10n.themeColorText,
                    value: _draft.textColor,
                    onPick: (Color color) =>
                        _updateDraft(_draft.copyWith(textColor: color)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Text(
                        l10n.themeBrightness,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SegmentedButton<Brightness>(
                        segments: <ButtonSegment<Brightness>>[
                          ButtonSegment<Brightness>(
                            value: Brightness.light,
                            label: Text(l10n.themeBrightnessLight),
                          ),
                          ButtonSegment<Brightness>(
                            value: Brightness.dark,
                            label: Text(l10n.themeBrightnessDark),
                          ),
                        ],
                        selected: <Brightness>{_draft.brightness},
                        onSelectionChanged: (Set<Brightness> selection) =>
                            _updateDraft(
                          _draft.copyWith(brightness: selection.first),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: l10n.themeEditorShape,
              icon: Icons.rounded_corner,
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _DraftSlider(
                    label: l10n.settingsCornerRadius,
                    value: _draft.borderRadius,
                    min: 0,
                    max: 32,
                    onChanged: (double value) =>
                        _updateDraft(_draft.copyWith(borderRadius: value)),
                  ),
                  _DraftSlider(
                    label: l10n.themeFieldCardOpacity,
                    value: _draft.cardOpacity,
                    min: 0.3,
                    max: 1,
                    onChanged: (double value) =>
                        _updateDraft(_draft.copyWith(cardOpacity: value)),
                  ),
                  _DraftSlider(
                    label: l10n.themeFieldBlur,
                    value: _draft.blurAmount,
                    min: 0,
                    max: 30,
                    onChanged: (double value) =>
                        _updateDraft(_draft.copyWith(blurAmount: value)),
                  ),
                  _DraftSlider(
                    label: l10n.themeFieldShadow,
                    value: _draft.shadowStrength,
                    min: 0,
                    max: 1,
                    onChanged: (double value) =>
                        _updateDraft(_draft.copyWith(shadowStrength: value)),
                  ),
                  _DraftSlider(
                    label: l10n.settingsFontScale,
                    value: _draft.fontScale,
                    min: 0.85,
                    max: 1.4,
                    onChanged: (double value) =>
                        _updateDraft(_draft.copyWith(fontScale: value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.themeFieldAnimation),
                    value: _draft.animationEnabled,
                    onChanged: (bool value) =>
                        _updateDraft(_draft.copyWith(animationEnabled: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: l10n.themeEditorPreview,
              icon: Icons.preview_outlined,
            ),
            _Preview(config: _draft),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.themeSave),
                ),
                if (_isUserTheme)
                  OutlinedButton.icon(
                    onPressed: _saveAsNew,
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: Text(l10n.themeSaveAs),
                  ),
                OutlinedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(l10n.themeExport),
                ),
                OutlinedButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(l10n.themeImport),
                ),
                TextButton.icon(
                  onPressed: () => _updateDraft(
                    ThemePresets.byId(ThemePresets.defaultId),
                  ),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: Text(l10n.settingsReset),
                ),
                if (_isUserTheme)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.calendarDelete),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _close() {
    _clearDraft();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  /// 保存：编辑中的用户主题就地更新，否则把当前草稿另存为新用户主题。
  Future<void> _save() async {
    if (_isUserTheme) {
      await _persist(_draft);
      return;
    }
    final name = await _askName(initial: _draft.name);
    if (name == null || !mounted) return;
    final now = ref.read(clockProvider).now();
    await _persist(
      _draft.copyWith(id: generateId('user-theme', now: now), name: name),
    );
  }

  Future<void> _saveAsNew() async {
    final name = await _askName();
    if (name == null || !mounted) return;
    final now = ref.read(clockProvider).now();
    await _persist(
      _draft.copyWith(id: generateId('user-theme', now: now), name: name),
    );
  }

  Future<void> _persist(ThemeConfig config) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await ref.read(themeRepositoryProvider).upsert(config);
    ref.read(themeControllerProvider.notifier).selectTheme(config.id);
    _clearDraft();
    if (!mounted) return;
    setState(() {
      _draft = config;
      _isUserTheme = true;
    });
    messenger?.showSnackBar(SnackBar(content: Text(l10n.themeSaved)));
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.calendarDeleteConfirmTitle),
        content: Text(l10n.calendarDeleteConfirmBody),
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
    if (confirmed != true || !mounted) return;

    await ref.read(themeRepositoryProvider).deleteById(_draft.id);
    ref
        .read(themeControllerProvider.notifier)
        .selectTheme(ThemePresets.defaultId);
    _clearDraft();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(l10n.themeDeleted)));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  Future<String?> _askName({String? initial}) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: initial ?? _draft.name);
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.themeSaveName),
        content: TextField(controller: controller, autofocus: true),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.calendarSave),
          ),
        ],
      ),
    );
    return (name == null || name.isEmpty) ? null : name;
  }

  /// 导出为 JSON：写到应用文档目录并复制到剪贴板。
  Future<void> _export() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final json =
        const JsonEncoder.withIndent('  ').convert(_draftToJson(_draft));
    await Clipboard.setData(ClipboardData(text: json));
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, '${_draft.id}.json'));
      await file.writeAsString(json);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.themeExported(file.path))),
      );
    } catch (error) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.themeExportFailed('$error'))),
      );
    }
  }

  /// 从剪贴板/粘贴的 JSON 导入主题。
  Future<void> _import() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final controller = TextEditingController(text: clipboard?.text ?? '');

    final text = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.themeImport),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            decoration: InputDecoration(hintText: l10n.themeImportHint),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.calendarSave),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;

    final config = _configFromJson(text);
    if (config == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.themeImportFailed)),
      );
      return;
    }

    final now = ref.read(clockProvider).now();
    final imported = config.copyWith(id: generateId('user-theme', now: now));
    await ref.read(themeRepositoryProvider).upsert(imported);
    _updateDraft(imported);
    if (!mounted) return;
    setState(() => _isUserTheme = true);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.themeImported(imported.name))),
    );
  }
}

Map<String, Object?> _draftToJson(ThemeConfig config) => <String, Object?>{
      'schemaVersion': 1,
      'id': config.id,
      'name': config.name,
      'brightness': config.isDark ? 'dark' : 'light',
      'primaryColor': _argb(config.primaryColor),
      'secondaryColor': _argb(config.secondaryColor),
      'backgroundColor': _argb(config.backgroundColor),
      'surfaceColor': _argb(config.surfaceColor),
      'textColor': _argb(config.textColor),
      'borderRadius': config.borderRadius,
      'cardOpacity': config.cardOpacity,
      'blurAmount': config.blurAmount,
      'fontScale': config.fontScale,
      'shadowStrength': config.shadowStrength,
      'animationEnabled': config.animationEnabled,
    };

int _argb(Color color) =>
    ((color.a * 255).round() << 24) |
    ((color.r * 255).round() << 16) |
    ((color.g * 255).round() << 8) |
    (color.b * 255).round();

Color _colorFrom(Object? value) =>
    Color((value as num?)?.toInt() ?? 0xFF000000);

/// 解析导入的主题 JSON；格式不对返回 null。
ThemeConfig? _configFromJson(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) return null;
    return ThemeConfig(
      id: decoded['id']?.toString() ?? 'imported',
      name: decoded['name']?.toString() ?? 'Imported',
      brightness:
          decoded['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
      primaryColor: _colorFrom(decoded['primaryColor']),
      secondaryColor: _colorFrom(decoded['secondaryColor']),
      backgroundColor: _colorFrom(decoded['backgroundColor']),
      surfaceColor: _colorFrom(decoded['surfaceColor']),
      textColor: _colorFrom(decoded['textColor']),
      borderRadius: (decoded['borderRadius'] as num?)?.toDouble() ?? 18,
      cardOpacity: (decoded['cardOpacity'] as num?)?.toDouble() ?? 1,
      blurAmount: (decoded['blurAmount'] as num?)?.toDouble() ?? 0,
      fontScale: (decoded['fontScale'] as num?)?.toDouble() ?? 1,
      shadowStrength: (decoded['shadowStrength'] as num?)?.toDouble() ?? 0.35,
      animationEnabled: decoded['animationEnabled'] as bool? ?? true,
    );
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

class _ColourField extends StatelessWidget {
  const _ColourField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onPick,
  });

  /// 用于测试定位调色板的稳定标识（`primary` / `secondary` / ...）。
  final String fieldKey;
  final String label;
  final Color value;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final (int index, Color color)
                    in EventPalette.colors.indexed)
                  InkWell(
                    key: ValueKey<String>('swatch-$fieldKey-$index'),
                    onTap: () => onPick(color),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _argb(color) == _argb(value)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.18),
                          width: _argb(color) == _argb(value) ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                InkWell(
                  key: ValueKey<String>('swatch-$fieldKey-white'),
                  onTap: () => onPick(const Color(0xFFFFFFFF)),
                  child: const _NeutralSwatch(color: Color(0xFFFFFFFF)),
                ),
                InkWell(
                  key: ValueKey<String>('swatch-$fieldKey-dark'),
                  onTap: () => onPick(const Color(0xFF10131C)),
                  child: const _NeutralSwatch(color: Color(0xFF10131C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeutralSwatch extends StatelessWidget {
  const _NeutralSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _DraftSlider extends StatelessWidget {
  const _DraftSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '$label · ${value.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// 预览区：用当前草稿渲染一小段界面。
class _Preview extends StatelessWidget {
  const _Preview({required this.config});

  final ThemeConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Theme(
      data: buildThemeData(config),
      child: Builder(
        builder: (BuildContext context) {
          final theme = Theme.of(context);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(config.borderRadius),
              boxShadow: config.shadowStrength <= 0
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: theme.shadowColor.withValues(
                          alpha: 0.25 * config.shadowStrength,
                        ),
                        blurRadius: 4 + 20 * config.shadowStrength,
                        offset: Offset(0, 3 * config.shadowStrength),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GlassCard(
                    style: GlassStyle.fromThemeConfig(config),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.themePreviewCardTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.themePreviewCardBody,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            FilledButton(
                              onPressed: () {},
                              child: Text(l10n.themePreviewAction),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () {},
                              child: Text(l10n.calendarCancel),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
