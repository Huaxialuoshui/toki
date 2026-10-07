import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 轻量 Markdown 渲染（规格 §12 要求"支持 Markdown / 代码块"）。
///
/// 刻意不引第三方包：
/// * 当前网络下装不了新依赖（pub 归档下载失败）；
/// * 只需要聊天里最常见的子集，自己实现反而更好控制样式。
///
/// 支持：段落、`#` 标题、`-`/`*`/`+` 无序列表、`1.` 有序列表、`>` 引用、
/// `---` 分隔线、``` 代码块、`` `行内代码` ``、`**粗体**`、`*斜体*`、
/// `~~删除线~~`、`[文字](链接)`。

/// 块级元素。
sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.text);
  final int level;
  final String text;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.text);
  final String text;
}

class MdListItem extends MdBlock {
  const MdListItem(this.text, {required this.marker, this.depth = 0});
  final String text;

  /// 无序列表是 `•`，有序列表是 `1.` 这样的原文编号。
  final String marker;
  final int depth;
}

class MdQuote extends MdBlock {
  const MdQuote(this.text);
  final String text;
}

class MdCode extends MdBlock {
  const MdCode(this.code, {this.language});
  final String code;
  final String? language;
}

class MdDivider extends MdBlock {
  const MdDivider();
}

final RegExp _fencePattern = RegExp(r'^\s*```(.*)$');
final RegExp _headingPattern = RegExp(r'^(#{1,6})\s+(.*)$');
final RegExp _dividerPattern = RegExp(r'^\s*(?:-{3,}|\*{3,}|_{3,})\s*$');
final RegExp _quotePattern = RegExp(r'^\s*>\s?(.*)$');
final RegExp _bulletPattern = RegExp(r'^(\s*)[-*+]\s+(.*)$');
final RegExp _orderedPattern = RegExp(r'^(\s*)(\d{1,3})[.)]\s+(.*)$');

/// 把 Markdown 文本切成块。纯函数，方便单测。
List<MdBlock> parseMarkdown(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <MdBlock>[];
  final paragraph = StringBuffer();
  final code = StringBuffer();
  var inCode = false;
  String? language;

  void flushParagraph() {
    final text = paragraph.toString().trim();
    if (text.isNotEmpty) blocks.add(MdParagraph(text));
    paragraph.clear();
  }

  for (final raw in lines) {
    final line = raw.trimRight();
    final fence = _fencePattern.firstMatch(line);

    if (inCode) {
      if (fence != null) {
        blocks.add(
            MdCode(_trimTrailingNewline(code.toString()), language: language));
        code.clear();
        language = null;
        inCode = false;
      } else {
        code.writeln(raw);
      }
      continue;
    }

    if (fence != null) {
      flushParagraph();
      inCode = true;
      final declared = fence.group(1)?.trim() ?? '';
      language = declared.isEmpty ? null : declared;
      continue;
    }

    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      flushParagraph();
      blocks.add(MdHeading(heading.group(1)!.length, heading.group(2)!.trim()));
      continue;
    }

    if (_dividerPattern.hasMatch(line)) {
      flushParagraph();
      blocks.add(const MdDivider());
      continue;
    }

    final quote = _quotePattern.firstMatch(line);
    if (quote != null) {
      flushParagraph();
      blocks.add(MdQuote(quote.group(1)!.trim()));
      continue;
    }

    final bullet = _bulletPattern.firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      blocks.add(
        MdListItem(
          bullet.group(2)!.trim(),
          marker: '•',
          depth: bullet.group(1)!.length ~/ 2,
        ),
      );
      continue;
    }

    final ordered = _orderedPattern.firstMatch(line);
    if (ordered != null) {
      flushParagraph();
      blocks.add(
        MdListItem(
          ordered.group(3)!.trim(),
          marker: '${ordered.group(2)}.',
          depth: ordered.group(1)!.length ~/ 2,
        ),
      );
      continue;
    }

    paragraph.writeln(line.trim());
  }

  // 没闭合的代码块也按代码渲染，避免把 ``` 当正文显示出来。
  if (inCode && code.isNotEmpty) {
    blocks
        .add(MdCode(_trimTrailingNewline(code.toString()), language: language));
  }
  flushParagraph();
  return blocks;
}

String _trimTrailingNewline(String value) =>
    value.endsWith('\n') ? value.substring(0, value.length - 1) : value;

final RegExp _inlinePattern = RegExp(
  r'(\*\*[^\n]+?\*\*|\*[^\n]+?\*|`[^`\n]+`|~~[^\n]+?~~|\[[^\]\n]+\]\([^)\n]+\))',
);

/// 行内元素 → [InlineSpan]。
List<InlineSpan> buildInlineSpans(
  String text, {
  required TextStyle base,
  required TextStyle code,
  void Function(String url)? onLinkTap,
}) {
  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final match in _inlinePattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: base));
    }
    final token = match.group(0)!;
    switch (token) {
      case final String value when value.startsWith('**'):
        spans.add(
          TextSpan(
            text: value.substring(2, value.length - 2),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      case final String value when value.startsWith('~~'):
        spans.add(
          TextSpan(
            text: value.substring(2, value.length - 2),
            style: base.copyWith(decoration: TextDecoration.lineThrough),
          ),
        );
      case final String value when value.startsWith('`'):
        spans.add(
            TextSpan(text: value.substring(1, value.length - 1), style: code));
      case final String value when value.startsWith('*'):
        spans.add(
          TextSpan(
            text: value.substring(1, value.length - 1),
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      default:
        final label =
            RegExp(r'^\[([^\]]+)\]').firstMatch(token)?.group(1) ?? token;
        final url = RegExp(r'\(([^)]+)\)$').firstMatch(token)?.group(1) ?? '';
        spans.add(
          TextSpan(
            text: label,
            style: base.copyWith(
              color: base.color,
              decoration: TextDecoration.underline,
              decorationColor: base.color,
            ),
            recognizer: onLinkTap == null
                ? null
                : (TapGestureRecognizer()..onTap = () => onLinkTap(url)),
          ),
        );
    }
    cursor = match.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: base));
  }
  return spans;
}

/// 渲染一段 Markdown。聊天里助手回复、以及可能带格式的文本都用它。
class MarkdownText extends StatelessWidget {
  const MarkdownText(
    this.data, {
    super.key,
    this.style,
    this.onLinkTap,
    this.copyLabel,
    this.selectable = false,
    this.maxCodeHeight = 320,
  });

  final String data;
  final TextStyle? style;

  /// 点击链接的回调；不传则链接只做样式提示（本项目暂不引 url_launcher）。
  final void Function(String url)? onLinkTap;

  /// 代码块复制成功后的提示文案（由调用方传本地化字符串）。
  final String? copyLabel;

  /// 是否允许长按选择文字。
  ///
  /// 聊天气泡默认关掉：`SelectableText` 的长按会被它自己的选择手势吃掉，
  /// 外面那层"长按出消息菜单"就永远触发不了。要复制整条消息用菜单里的复制。
  final bool selectable;
  final double maxCodeHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final blocks = parseMarkdown(data);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final block in blocks)
          Padding(
            padding: EdgeInsets.only(
                top: block is MdParagraph || block is MdListItem ? 0 : 6),
            child: _block(context, theme, base, block),
          ),
      ],
    );
  }

  Widget _block(
    BuildContext context,
    ThemeData theme,
    TextStyle base,
    MdBlock block,
  ) {
    switch (block) {
      case MdHeading(:final int level, :final String text):
        final sizes = <double>[22, 19, 17, 16, 15, 15];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _rich(
            context,
            text,
            base.copyWith(
              fontSize: sizes[(level - 1).clamp(0, 5)],
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case MdParagraph(:final String text):
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _rich(context, text, base),
        );
      case MdListItem(
          :final String text,
          :final String marker,
          :final int depth
        ):
        return Padding(
          padding: EdgeInsets.only(left: 8.0 * depth, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: marker.length > 2 ? 28 : 18,
                child: Text(marker, style: base),
              ),
              Expanded(child: _rich(context, text, base)),
            ],
          ),
        );
      case MdQuote(:final String text):
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                width: 3,
              ),
            ),
          ),
          child: _rich(
            context,
            text,
            base.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      case MdDivider():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(color: theme.dividerColor, height: 1),
        );
      case MdCode(:final String code, :final String? language):
        return _CodeBlock(
          code: code,
          language: language,
          base: base,
          maxHeight: maxCodeHeight,
          copyLabel: copyLabel,
        );
    }
  }

  Widget _rich(BuildContext context, String text, TextStyle base) {
    final code = _codeStyle(Theme.of(context), base);
    final span = TextSpan(
      children: buildInlineSpans(
        text,
        base: base,
        code: code,
        onLinkTap: onLinkTap,
      ),
    );
    return selectable
        ? SelectableText.rich(span, style: base)
        : Text.rich(span, style: base);
  }
}

TextStyle _codeStyle(ThemeData theme, TextStyle base) => base.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['Consolas', 'Menlo', 'monospace'],
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
      fontSize: (base.fontSize ?? 14) * 0.95,
    );

/// 代码块：等宽字体 + 右上角复制按钮。
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.language,
    required this.base,
    required this.maxHeight,
    required this.copyLabel,
  });

  final String code;
  final String? language;
  final TextStyle base;
  final double maxHeight;
  final String? copyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = language ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    final label = copyLabel;
                    if (label == null || !context.mounted) return;
                    ScaffoldMessenger.maybeOf(context)
                        ?.showSnackBar(SnackBar(content: Text(label)));
                  },
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_all_outlined),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: SelectableText(
                code,
                style: base.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const <String>[
                    'Consolas',
                    'Menlo',
                    'monospace',
                  ],
                  fontSize: (base.fontSize ?? 14) * 0.95,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
