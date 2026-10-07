import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar/calendar_providers.dart';
import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_category.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「日历分类」区块（规格 §5 §6）：分类的增删改。
///
/// 删除分类时会把引用它的事件改成"无分类"，事件本身不会丢。
class CalendarCategorySection extends ConsumerWidget {
  const CalendarCategorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categories = ref.watch(calendarCategoriesProvider).valueOrNull ??
        const <CalendarCategory>[];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.calendarCategoryEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                ),
              ),
            )
          else
            for (final category in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.name,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: ValueKey<String>('category-edit-${category.id}'),
                      tooltip: l10n.calendarCategoryEdit,
                      onPressed: () => _edit(context, ref, category),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      key: ValueKey<String>('category-delete-${category.id}'),
                      tooltip: l10n.calendarDelete,
                      onPressed: () => _delete(context, ref, category),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey<String>('category-add'),
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.calendarCategoryAdd),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    CalendarCategory? existing,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: existing?.name ?? '');
    var color = existing?.color ?? EventPalette.colors.first;

    final result = await showDialog<({String name, Color color})>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) =>
            AlertDialog(
          title: Text(existing == null
              ? l10n.calendarCategoryAdd
              : l10n.calendarCategoryEdit),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration:
                      InputDecoration(labelText: l10n.calendarCategoryName),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.calendarCategoryColor,
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final (int index, Color option)
                        in EventPalette.colors.indexed)
                      InkWell(
                        key: ValueKey<String>('category-color-$index'),
                        onTap: () => setDialogState(() => color = option),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: option,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: option == color
                                  ? Theme.of(dialogContext).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.calendarCancel),
            ),
            FilledButton(
              key: const ValueKey<String>('category-save'),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.of(dialogContext).pop((name: name, color: color));
              },
              child: Text(l10n.calendarSave),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    final now = ref.read(clockProvider).now();
    await ref.read(calendarCategoryRepositoryProvider).upsert(
          CalendarCategory(
            id: existing?.id ?? generateId('category', now: now),
            name: result.name,
            color: result.color,
            icon: existing?.icon,
            sortOrder: existing?.sortOrder ?? 0,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.calendarCategorySaved)),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CalendarCategory category,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.calendarCategoryDeleteTitle),
        content: Text(l10n.calendarCategoryDeleteBody(category.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            key: const ValueKey<String>('category-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.calendarDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 先摘掉事件上的引用，再删分类，否则会撞外键约束。
    await ref
        .read(calendarRepositoryProvider)
        .clearCategoryFromEvents(category.id);
    await ref.read(calendarCategoryRepositoryProvider).deleteById(category.id);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.calendarCategoryDeleted)),
    );
  }
}
