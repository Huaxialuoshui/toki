import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/shared/widgets/markdown_text.dart';

/// 轻量 Markdown 渲染（规格 §12）：块级解析 + 行内 span。
void main() {
  group('块级解析', () {
    test('标题按层级解析', () {
      final blocks = parseMarkdown('# 一级\n## 二级\n###### 六级');

      expect(blocks, hasLength(3));
      expect((blocks[0] as MdHeading).level, 1);
      expect((blocks[0] as MdHeading).text, '一级');
      expect((blocks[1] as MdHeading).level, 2);
      expect((blocks[2] as MdHeading).level, 6);
    });

    test('段落与空行：连续行合并成一个段落，空行分段', () {
      final blocks = parseMarkdown('第一行\n第二行\n\n另起一段');

      expect(blocks, hasLength(2));
      expect((blocks[0] as MdParagraph).text, '第一行\n第二行');
      expect((blocks[1] as MdParagraph).text, '另起一段');
    });

    test('无序列表 / 有序列表 / 引用 / 分隔线', () {
      final blocks = parseMarkdown('- 甲\n* 乙\n+ 丙\n1. 一\n2) 二\n> 引用\n---');

      expect(blocks.whereType<MdListItem>(), hasLength(5));
      expect(blocks.whereType<MdListItem>().first.marker, '•');
      expect(blocks.whereType<MdListItem>().elementAt(3).marker, '1.');
      expect(blocks.whereType<MdListItem>().elementAt(4).marker, '2.');
      expect((blocks[5] as MdQuote).text, '引用');
      expect(blocks[6], isA<MdDivider>());
    });

    test('缩进列表记录层级', () {
      final blocks = parseMarkdown('- 顶层\n  - 子项');

      expect(blocks.whereType<MdListItem>().first.depth, 0);
      expect(blocks.whereType<MdListItem>().last.depth, 1);
    });

    test('代码块保留原始内容与语言标记', () {
      final blocks =
          parseMarkdown('说明\n\n```dart\nfinal a = 1;\nprint(a);\n```\n\n结束');

      expect(blocks, hasLength(3));
      final code = blocks[1] as MdCode;
      expect(code.language, 'dart');
      expect(code.code, 'final a = 1;\nprint(a);');
      expect((blocks[2] as MdParagraph).text, '结束');
    });

    test('未闭合的代码块也按代码渲染，不会漏出 ```', () {
      final blocks = parseMarkdown('```\nabc');

      expect(blocks, hasLength(1));
      expect((blocks.single as MdCode).code, 'abc');
    });

    test('空字符串返回空列表', () {
      expect(parseMarkdown('   \n\n'), isEmpty);
    });
  });

  group('行内解析', () {
    List<InlineSpan> spans(String text) => buildInlineSpans(
          text,
          base: const TextStyle(color: Color(0xFF000000)),
          code: const TextStyle(fontFamily: 'monospace'),
        );

    test('粗体 / 斜体 / 行内代码 / 删除线', () {
      final result = spans('普通 **粗** *斜* `码` ~~删~~');

      final texts = result
          .map((InlineSpan s) => (s as TextSpan).text)
          .whereType<String>()
          .toList();
      expect(texts, contains('粗'));
      expect(texts, contains('斜'));
      expect(texts, contains('码'));
      expect(texts, contains('删'));

      final bold = result.firstWhere(
        (InlineSpan s) => (s as TextSpan).text == '粗',
      ) as TextSpan;
      expect(bold.style?.fontWeight, FontWeight.w700);
      final italic = result.firstWhere(
        (InlineSpan s) => (s as TextSpan).text == '斜',
      ) as TextSpan;
      expect(italic.style?.fontStyle, FontStyle.italic);
      final strike = result.firstWhere(
        (InlineSpan s) => (s as TextSpan).text == '删',
      ) as TextSpan;
      expect(strike.style?.decoration, TextDecoration.lineThrough);
    });

    test('链接保留文字并带下划线，点击回调拿到 url', () {
      final tapped = <String>[];
      final result = buildInlineSpans(
        '见 [文档](https://example.com/a)',
        base: const TextStyle(),
        code: const TextStyle(),
        onLinkTap: tapped.add,
      );
      final link = result.firstWhere(
        (InlineSpan s) => (s as TextSpan).text == '文档',
      ) as TextSpan;
      expect(link.style?.decoration, TextDecoration.underline);
      expect(link.recognizer, isNotNull);

      (link.recognizer! as dynamic).onTap();
      expect(tapped, <String>['https://example.com/a']);
    });

    test('没有标记时原样返回一段文本', () {
      final result = spans('就是一句话');
      expect(result, hasLength(1));
      expect((result.single as TextSpan).text, '就是一句话');
    });
  });

  group('组件', () {
    testWidgets('渲染标题 / 列表 / 代码块，不残留标记符号', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownText('# 标题\n- 一项\n\n```dart\nfinal a = 1;\n```'),
          ),
        ),
      );

      expect(find.textContaining('标题'), findsWidgets);
      expect(find.text('一项'), findsOneWidget);
      expect(find.text('•'), findsOneWidget);
      expect(find.textContaining('final a = 1;'), findsOneWidget);
      // 标记符号不应该出现在界面上
      expect(find.textContaining('```'), findsNothing);
      expect(find.textContaining('# 标题'), findsNothing);
    });
  });
}
