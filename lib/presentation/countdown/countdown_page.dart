import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/countdown/countdown_actions.dart';
import '../../application/countdown/countdown_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/countdown_item.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/async_hint.dart';
import '../widgets/countdown_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';
import 'countdown_editor_dialog.dart';

/// 倒计时页：新建 / 编辑 / 删除 / 置顶 / 拖动排序 + 两种显示样式。
///
/// 列表本身就是这一页的滚动容器（`PageScaffold(scrollable: false)`），
/// 这样拖动排序的手势不会被外层滚动抢走。
class CountdownPage extends ConsumerWidget {
  const CountdownPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // 触屏上"按下即拖"会被列表自身的滚动手势抢走（实测 Android 会变成滚动），
    // 因此移动端用"长按手柄再拖"（平台惯例），桌面用"直接拖手柄"。
    final isDesktop = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
    final countdownsAsync = ref.watch(countdownsProvider);
    final items = countdownsAsync.valueOrNull ?? const <CountdownItem>[];
    final pinned = items
        .where((CountdownItem item) => item.isPinned)
        .toList(growable: false);
    final others = items
        .where((CountdownItem item) => !item.isPinned)
        .toList(growable: false);

    final entries = <_Entry>[
      if (pinned.isNotEmpty)
        _Entry.header(
          title: l10n.countdownPinned,
          icon: Icons.push_pin_outlined,
        ),
      for (final item in pinned) _Entry.card(item),
      if (others.isNotEmpty)
        _Entry.header(
          title: l10n.navCountdown,
          icon: Icons.timelapse_outlined,
        ),
      for (final item in others) _Entry.card(item),
    ];

    return PageScaffold(
      title: l10n.navCountdown,
      subtitle: l10n.appTagline,
      scrollable: false,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      isDesktop
                          ? l10n.countdownDragHint
                          : l10n.countdownDragHintLongPress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => showCountdownEditor(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.countdownNew),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildBody(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                  entries: entries,
                  items: items,
                  pinned: pinned,
                  others: others,
                  isLoading: countdownsAsync.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required List<_Entry> entries,
    required List<CountdownItem> items,
    required List<CountdownItem> pinned,
    required List<CountdownItem> others,
    required bool isLoading,
  }) {
    if (isLoading && items.isEmpty) {
      return const SingleChildScrollView(child: LoadingHint());
    }
    if (items.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(
              title: l10n.navCountdown,
              icon: Icons.timelapse_outlined,
            ),
            EmptyHint(
              text: l10n.countdownEmpty,
              icon: Icons.timelapse_outlined,
            ),
          ],
        ),
      );
    }

    final actions = ref.read(countdownActionsProvider);
    final isDesktop = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: entries.length,
      onReorder: (int oldIndex, int newIndex) => _handleReorder(
        entries: entries,
        pinned: pinned,
        others: others,
        actions: actions,
        oldIndex: oldIndex,
        newIndex: newIndex,
      ),
      itemBuilder: (BuildContext context, int index) {
        final entry = entries[index];
        final item = entry.item;
        if (item == null) {
          return Padding(
            key: ValueKey<String>('header-${entry.title}'),
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: SectionHeader(title: entry.title!, icon: entry.icon),
          );
        }

        return Padding(
          key: ValueKey<String>(item.id),
          padding: const EdgeInsets.only(bottom: 10),
          child: CountdownCard(
            item: item,
            onTap: () => showCountdownEditor(context, item: item),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: () => actions.setPinned(
                    id: item.id,
                    isPinned: !item.isPinned,
                  ),
                  icon: Icon(
                    item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 18,
                  ),
                  tooltip: l10n.countdownFieldPinned,
                  visualDensity: VisualDensity.compact,
                ),
                if (isDesktop)
                  ReorderableDragStartListener(
                    index: index,
                    child: _DragHandle(label: l10n.countdownDragHandle),
                  )
                else
                  ReorderableDelayedDragStartListener(
                    index: index,
                    child: _DragHandle(label: l10n.countdownDragHandle),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 把列表索引换算成"同一分组内的新顺序"。
  ///
  /// 拖到另一个分组（置顶 ↔ 未置顶）时忽略，改分组请用图钉按钮。
  void _handleReorder({
    required List<_Entry> entries,
    required List<CountdownItem> pinned,
    required List<CountdownItem> others,
    required CountdownActions actions,
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 || oldIndex >= entries.length) return;
    final dragged = entries[oldIndex].item;
    if (dragged == null) return;

    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (adjusted < 0 || adjusted >= entries.length) return;
    final target = entries[adjusted].item;
    if (target == null || target.isPinned != dragged.isPinned) return;
    if (target.id == dragged.id) return;

    final group = target.isPinned ? pinned : others;
    final ids =
        group.map((CountdownItem item) => item.id).toList(growable: true);
    final from = ids.indexOf(dragged.id);
    final to = ids.indexOf(target.id);
    if (from == -1 || to == -1) return;

    final moved = ids.removeAt(from);
    ids.insert(to, moved);
    actions.reorder(ids);
  }
}

/// 列表里的两种条目：分组标题或倒计时卡片。
class _Entry {
  const _Entry._({this.item, this.title, this.icon});

  factory _Entry.card(CountdownItem item) => _Entry._(item: item);

  factory _Entry.header({required String title, required IconData icon}) =>
      _Entry._(title: title, icon: icon);

  final CountdownItem? item;
  final String? title;
  final IconData? icon;
}

/// 拖动排序手柄（图标 + 无障碍标签）。
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Icon(Icons.drag_indicator, size: 20),
      ),
    );
  }
}
