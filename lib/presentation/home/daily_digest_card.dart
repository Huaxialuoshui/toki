import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/daily_digest_service.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/daily_digest.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/markdown_text.dart';

/// 首页的「今日计划 / 今日总结」卡片（规格 §14）。
///
/// 开关关掉时整张卡不显示；开着但还没生成时给一个生成按钮。
class DailyDigestCard extends ConsumerStatefulWidget {
  const DailyDigestCard({super.key, required this.kind});

  final DailyDigestKind kind;

  @override
  ConsumerState<DailyDigestCard> createState() => _DailyDigestCardState();
}

class _DailyDigestCardState extends ConsumerState<DailyDigestCard> {
  bool _busy = false;
  DailyDigest? _digest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final digest =
        await ref.read(dailyDigestServiceProvider).today(widget.kind);
    if (!mounted) return;
    setState(() => _digest = digest);
  }

  Future<void> _generate() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final digest =
          await ref.read(dailyDigestServiceProvider).generate(widget.kind);
      if (!mounted) return;
      setState(() {
        _digest = digest;
        _busy = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger?.showSnackBar(
        SnackBar(content: Text('${l10n.digestFailed}：$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final enabled =
        ref.watch(dailyDigestServiceProvider).isEnabled(widget.kind);
    if (!enabled) return const SizedBox.shrink();

    final title = widget.kind == DailyDigestKind.morning
        ? l10n.digestMorningTitle
        : l10n.digestEveningTitle;
    final digest = _digest;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  widget.kind == DailyDigestKind.morning
                      ? Icons.wb_twilight
                      : Icons.nightlight_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (digest != null)
                  IconButton(
                    tooltip: l10n.digestRegenerate,
                    onPressed: _busy ? null : _generate,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (_busy)
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.digestGenerating,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              )
            else if (digest == null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(l10n.digestGenerate),
                ),
              )
            else
              MarkdownText(digest.content, copyLabel: l10n.aiMessageCopied),
          ],
        ),
      ),
    );
  }
}
