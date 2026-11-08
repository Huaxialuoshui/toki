import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/constants/brand_assets.dart';
import 'package:toki/presentation/widgets/brand_icon.dart';
import 'package:toki/presentation/widgets/persona_avatar.dart';

import '../helpers/test_app.dart';

void main() {
  test('新版导航、头像和应用图标资源都已打包', () {
    for (final path in <String>[
      ...BrandAssets.newNavigationIcons.values,
      BrandAssets.newAppIcon,
      BrandAssets.newAssistantAvatar1,
      BrandAssets.newAssistantAvatar2,
      ...BrandAssets.classicNavigationIcons.values,
      BrandAssets.classicAppIcon,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  tokiWidgetTest('导航默认使用新版角色图标，原版仍可切换', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(1400, 1000),
      seedDatabase: false,
    );

    final homeIcon = tester.widget<BrandNavigationIcon>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey<String>('sidebar-tile-/home'),
            ),
            matching: find.byType(BrandNavigationIcon),
          )
          .first,
    );
    expect(homeIcon.storedPath, isNull);

    await openSettingsPath(
      tester,
      <String>[
        'settings-menu-appearance',
        'settings-appearance-background',
      ],
    );
    final classic = find.byKey(
      const ValueKey<String>('nav-icon-preset-classic'),
    );
    await tester.ensureVisible(classic);
    await tester.pumpAndSettle();
    await tester.tap(classic);
    await tester.pumpAndSettle();

    final originalIcon = tester.widget<BrandNavigationIcon>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey<String>('sidebar-tile-/home'),
            ),
            matching: find.byType(BrandNavigationIcon),
          )
          .first,
    );
    expect(originalIcon.storedPath, contains('/classic/'));
  });

  tokiWidgetTest('AI 助手未设置头像时使用新版默认头像', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(1400, 1000),
      seedDatabase: false,
    );
    await tester.tap(find.byKey(const ValueKey<String>('sidebar-tile-/ai')));
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find
          .descendant(
            of: find.byType(PersonaAvatar).first,
            matching: find.byType(CircleAvatar),
          )
          .first,
    );
    expect(
      (avatar.foregroundImage! as AssetImage).assetName,
      BrandAssets.newAssistantAvatar1,
    );
  });
}
