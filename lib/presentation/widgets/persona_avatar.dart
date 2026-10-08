import 'package:flutter/material.dart';

import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/ai_persona.dart';
import 'image_source.dart';

/// 「纯聊天」小徽标：关掉日历助手（[AiPersona.calendarAssistantEnabled]）时，
/// 在人设列表和切换菜单里标一下，避免以为它还在读写日程。
class PersonaChatOnlyBadge extends StatelessWidget {
  const PersonaChatOnlyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.chat_bubble_outline, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          context.l10n.aiPersonaChatOnly,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 人设头像。
///
/// 支持三种写法（按优先级）：
/// * `http(s)://...` → 网络图片
/// * 含路径分隔符或图片后缀 → 本地文件
/// * 其它短文本（emoji / 1-2 个字）→ 直接显示
///
/// 图片加载失败时自动回落到文字头像，不会出现裂图。
class PersonaAvatar extends StatelessWidget {
  const PersonaAvatar({super.key, required this.persona, this.radius = 14});

  final AiPersona persona;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 人设可以给自己的头像挑底色；没选就跟随主题。
    final background = persona.avatarColor == null
        ? theme.colorScheme.primary.withValues(alpha: 0.14)
        : Color(persona.avatarColor!);
    final avatar = persona.avatar?.trim() ?? '';

    final image = resolveImageProvider(avatar);

    if (image != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: background,
        foregroundImage: image,
        onForegroundImageError: (_, __) {},
        child: Text(
          persona.avatarInitial,
          style: _textStyle(theme, radius),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        avatar.isEmpty ? persona.avatarInitial : avatar,
        style: _textStyle(theme, radius),
      ),
    );
  }

  TextStyle? _textStyle(ThemeData theme, double radius) {
    final base = radius >= 22
        ? theme.textTheme.titleMedium
        : radius >= 18
            ? theme.textTheme.titleSmall
            : theme.textTheme.labelMedium;
    return base?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
  }
}
