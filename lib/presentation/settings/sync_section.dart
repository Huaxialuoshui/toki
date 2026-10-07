import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/sync/sync_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/services/sync_service.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「数据同步」区块（规格 §15）。
///
/// 第一版只有本地实现，这里如实说明"数据只在本机"；接口已经按
/// `SyncService` 抽象留好，以后接 WebDAV / 云时在这里加选项即可。
class SyncSection extends ConsumerStatefulWidget {
  const SyncSection({super.key});

  @override
  ConsumerState<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends ConsumerState<SyncSection> {
  bool _busy = false;

  Future<void> _sync() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final service = ref.read(syncServiceProvider);
    setState(() => _busy = true);
    await service.initialize();
    final result = await service.sync();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.syncLocalDone(result.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final service = ref.watch(syncServiceProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                service.isLocalOnly ? l10n.syncLocalTitle : service.id,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.syncLocalSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey<String>('sync-now'),
              onPressed: _busy ? null : _sync,
              icon: const Icon(Icons.sync, size: 18),
              label: Text(l10n.syncNow),
            ),
          ),
        ],
      ),
    );
  }
}
