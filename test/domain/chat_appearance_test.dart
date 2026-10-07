import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/chat_appearance.dart';

void main() {
  group('ChatBackgroundConfig', () {
    test('JSON 往返保持所有字段', () {
      const config = ChatBackgroundConfig(
        type: ChatBackgroundType.gradient,
        solidColor: 0xFF102030,
        gradientColors: <int>[0xFF000001, 0xFF000002],
        imagePath: 'D:/Pictures/ai_bg.png',
        imageOpacity: 0.6,
        blurAmount: 12,
        overlayColor: 0xFF123456,
        overlayOpacity: 0.4,
      );

      final restored = ChatBackgroundConfig.fromJson(config.toJson());

      expect(restored, config);
      expect(restored.type, ChatBackgroundType.gradient);
      expect(restored.imagePath, 'D:/Pictures/ai_bg.png');
      expect(restored.blurAmount, 12);
      expect(restored.overlayOpacity, 0.4);
    });

    test('默认值：纯色 + 无模糊 + 无遮罩', () {
      const config = ChatBackgroundConfig();
      expect(config.type, ChatBackgroundType.solid);
      expect(config.blurAmount, 0);
      expect(config.overlayOpacity, 0);
      expect(config.hasImage, isFalse);
    });

    test('未知类型回落到纯色，缺字段用默认值', () {
      final restored = ChatBackgroundConfig.fromJson(<String, Object?>{
        'type': 'something-else',
      });
      expect(restored.type, ChatBackgroundType.solid);
      expect(restored.gradientColors, hasLength(2));
      expect(restored.imageOpacity, 1);
    });
  });

  group('ChatAppearanceConfig', () {
    test('encode / decode 往返', () {
      const config = ChatAppearanceConfig(
        background: ChatBackgroundConfig(
          type: ChatBackgroundType.image,
          imagePath: '/tmp/bg.jpg',
          blurAmount: 8,
        ),
        userAvatar: '🐱',
        bubbleOpacity: 0.8,
        bubbleRadius: 24,
        fontScale: 1.2,
        animationEnabled: false,
      );

      final restored = ChatAppearanceConfig.decode(config.encode());

      expect(restored, config);
    });

    test('空串 / 非法 JSON / 非对象都回落到默认值', () {
      expect(ChatAppearanceConfig.decode(null), ChatAppearanceConfig.defaults);
      expect(ChatAppearanceConfig.decode('  '), ChatAppearanceConfig.defaults);
      expect(ChatAppearanceConfig.decode('not json'),
          ChatAppearanceConfig.defaults);
      expect(ChatAppearanceConfig.decode('[1,2,3]'),
          ChatAppearanceConfig.defaults);
    });

    test('copyWith 可以清除头像但保留其它字段', () {
      const config = ChatAppearanceConfig(
        userAvatar: '🐱',
        bubbleRadius: 30,
      );
      final cleared = config.copyWith(clearUserAvatar: true);
      expect(cleared.userAvatar, isNull);
      expect(cleared.bubbleRadius, 30);
    });

    test('颜色值在模型里按 ARGB 保存', () {
      const config = ChatBackgroundConfig(solidColor: 0xFF5A6BF0);
      expect(config.solid, const Color(0xFF5A6BF0));
    });
  });
}
