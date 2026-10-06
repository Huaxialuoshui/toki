import 'package:flutter/material.dart';

/// 页面外壳：统一的标题区 + 内容区。
///
/// 手机 / 平板 / 桌面共用同一个页面组件，只由外层 Shell 决定导航形态。
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.scrollable = true,
    this.maxContentWidth = 1100,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool scrollable;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 600 ? 16.0 : 28.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            width < 600 ? 18 : 26,
            horizontalPadding,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.66),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(child: child)
                    : child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
