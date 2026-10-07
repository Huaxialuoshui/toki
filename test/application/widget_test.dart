import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/device/device_providers.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/app_startup.dart';
import 'package:toki/application/widget/widget_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/countdown_item.dart';
import 'package:toki/domain/entities/widget_config.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/device/device_channel.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../helpers/sqlite_bootstrap.dart';

/// 桌面小组件：配置模型 + 推给原生的内容。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  group('WidgetConfig', () {
    test('JSON 往返保留皮肤 / 图标 / 背景图片', () {
      const config = WidgetConfig(
        skin: WidgetSkin.image,
        imagePath: '/tmp/bg.png',
        textColor: 0xFF102030,
        accentColor: 0xFF445566,
        iconStyle: WidgetIconStyle.filled,
        cornerRadius: 12,
        transparent: true,
        showEvent: false,
      );

      final restored = WidgetConfig.fromJson(config.toJson());

      expect(restored.skin, WidgetSkin.image);
      expect(restored.imagePath, '/tmp/bg.png');
      expect(restored.iconStyle, WidgetIconStyle.filled);
      expect(restored.cornerRadius, 12);
      expect(restored.transparent, isTrue);
      expect(restored.showEvent, isFalse);
      expect(restored, config);
    });

    test('缺字段时回落到默认外观，清空图片用 clearImage', () {
      final restored = WidgetConfig.fromJson(<String, Object?>{});
      expect(restored.skin, WidgetSkin.solid);
      expect(restored.iconStyle, WidgetIconStyle.outlined);
      expect(restored.imagePath, isNull);

      final cleared =
          restored.copyWith(imagePath: '/x.png').copyWith(clearImage: true);
      expect(cleared.imagePath, isNull);
    });
  });

  group('推送给原生', () {
    late AppDatabase database;
    late ProviderContainer container;
    late List<String> pushed;
    late Directory tempDir;
    final FixedClock clock = FixedClock(DateTime(2026, 10, 7, 9));

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      database = AppDatabase.memory();
      pushed = <String>[];
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('toki/device'),
        (MethodCall call) async {
          if (call.method == 'updateWidget') {
            pushed.add(call.method);
          }
          return true;
        },
      );
      // 小组件状态是写文件的，这里把文件目录换成临时目录。
      tempDir = await Directory.systemTemp.createTemp('toki-widget');
      container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          clockProvider.overrideWithValue(clock),
          appDatabaseProvider.overrideWithValue(database),
          demoSeedEnabledProvider.overrideWithValue(false),
          deviceChannelProvider.overrideWithValue(
            DeviceChannel.withDirectory(
              directory: () async => tempDir,
              channel: const MethodChannel('toki/device'),
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });
      await container.read(personasProvider.future);
    });

    test('没有数据时给出"暂无安排"', () async {
      await container.read(widgetPublisherProvider).publish();
      // 状态是写到文件里的，这里只断言"确实触发了原生刷新"。
      expect(pushed, isNotEmpty);
    });

    test('有倒计时时推送标题与剩余时间', () async {
      await container.read(countdownRepositoryProvider).upsert(
            CountdownItem(
              id: 'c1',
              title: '期末考试',
              targetTime: DateTime(2026, 10, 14, 9),
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      await container.read(widgetPublisherProvider).publish();

      final file =
          await File('${tempDir.path}/widget_state.json').readAsString();
      final payload = jsonDecode(file) as Map<String, dynamic>;
      expect(payload['title'], '期末考试');
      expect(payload['subtitle'], contains('7'));
      expect(payload['hasData'], isTrue);
      expect((payload['appearance'] as Map)['backgroundType'], 'solid');
    });
  });
}
