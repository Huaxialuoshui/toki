import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_theme_repository.dart';
import 'package:toki/domain/entities/theme_config.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftThemeRepository repository;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  const ThemeConfig config = ThemeConfig(
    id: 'my-theme',
    name: '我的主题',
    brightness: Brightness.dark,
    primaryColor: Color(0xFF8AB4FF),
    secondaryColor: Color(0xFFB48CFF),
    backgroundColor: Color(0xFF10131C),
    surfaceColor: Color(0xFF1B2030),
    textColor: Color(0xFFEDF1FA),
    borderRadius: 22,
    cardOpacity: 0.78,
    blurAmount: 18,
    fontScale: 1.1,
    animationEnabled: false,
  );

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftThemeRepository(database, clock: clock);
  });

  tearDown(() => database.close());

  test('保存 / 读取用户主题（颜色与玻璃参数完整往返）', () async {
    await repository.upsert(config);

    final loaded = (await repository.findById('my-theme'))!;
    expect(loaded, config);
    expect(loaded.isDark, isTrue);
    expect(loaded.cardOpacity, 0.78);
    expect(loaded.blurAmount, 18);
    expect(loaded.animationEnabled, isFalse);
  });

  test('再次保存时保留 createdAt，只更新 updatedAt', () async {
    await repository.upsert(config);
    final before = (await database.select(database.themeConfigs).get()).single;

    clock.advance(const Duration(days: 1));
    await repository.upsert(config.copyWith(name: '改名后的主题'));

    final rows = await database.select(database.themeConfigs).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, '改名后的主题');
    expect(rows.single.createdAt, before.createdAt);
    // 秒级精度：drift 以 Unix 秒存储。
    expect(
      rows.single.updatedAt.isAfter(rows.single.createdAt),
      isTrue,
    );
  });

  test('删除主题', () async {
    await repository.upsert(config);
    await repository.deleteById('my-theme');
    expect(await repository.getAll(), isEmpty);
  });
}
