import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/appearance/app_appearance_providers.dart';
import '../../shared/widgets/app_icon.dart';

/// 区块标题：左侧标题，右侧可选操作。
class SectionHeader extends ConsumerWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.icon,
  });

  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = ref.watch(appIconStyleProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              resolveAppIcon(icon!, style),
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
