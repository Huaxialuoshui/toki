import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/device/device_providers.dart';
import 'package:toki/application/weather/weather_providers.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/domain/entities/weather.dart';
import 'package:toki/domain/services/weather_service.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/device/device_channel.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

/// 天气位置：添加 / 去重 / 上限 / 删除 / GPS 定位。
void main() {
  const MethodChannel channel = MethodChannel('toki/device');

  late ProviderContainer container;
  late List<String> calls;

  Future<void> setUpContainer({
    Map<String, Object> preferences = const <String, Object>{},
    bool permission = true,
    Map<Object?, Object?>? location,
  }) async {
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = await SharedPreferences.getInstance();
    calls = <String>[];
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'hasLocationPermission':
        case 'requestLocationPermission':
          return permission;
        case 'getLocation':
          return location;
        default:
          return true;
      }
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 7, 9))),
        deviceChannelProvider.overrideWithValue(
          DeviceChannel(channel: channel, supported: true),
        ),
      ],
    );
    addTearDown(container.dispose);
  }

  test('添加城市：最近使用的在前，重复城市会去重', () async {
    await setUpContainer();
    final controller = container.read(weatherLocationsProvider.notifier);

    await controller.rememberCity('上海');
    await controller.rememberCity('北京');
    await controller.rememberCity('上海');

    final locations = container.read(weatherLocationsProvider);
    expect(locations.map((WeatherLocation l) => l.label), <String>['上海', '北京']);
  });

  test('最多保留 8 个位置', () async {
    await setUpContainer();
    final controller = container.read(weatherLocationsProvider.notifier);

    for (var i = 0; i < 12; i++) {
      await controller.rememberCity('城市$i');
    }

    expect(container.read(weatherLocationsProvider),
        hasLength(maxWeatherLocations));
    expect(container.read(weatherLocationsProvider).first.label, '城市11');
  });

  test('删除位置', () async {
    await setUpContainer();
    final controller = container.read(weatherLocationsProvider.notifier);
    await controller.rememberCity('上海');
    await controller.rememberCity('北京');

    await controller.forget('city-上海');

    final labels = container
        .read(weatherLocationsProvider)
        .map((WeatherLocation l) => l.label)
        .toList();
    expect(labels, <String>['北京']);
  });

  test('GPS 定位成功后会记成"当前位置"', () async {
    await setUpContainer(
      location: <Object?, Object?>{
        'latitude': 31.22,
        'longitude': 121.46,
        'accuracy': 12.0,
      },
    );
    final controller = container.read(weatherLocationsProvider.notifier);

    final location = await controller.useCurrentLocation();

    expect(location.isGps, isTrue);
    expect(location.latitude, closeTo(31.22, 0.001));
    expect(container.read(activeWeatherLocationProvider)?.id, 'gps-current');
    expect(calls, contains('getLocation'));
  });

  test('没有定位权限时给出可读错误，不会记位置', () async {
    await setUpContainer(permission: false);
    final controller = container.read(weatherLocationsProvider.notifier);

    await expectLater(
      controller.useCurrentLocation(),
      throwsA(
        isA<WeatherLocationException>().having(
          (WeatherLocationException e) => e.message,
          'message',
          contains('权限'),
        ),
      ),
    );
    expect(container.read(weatherLocationsProvider), isEmpty);
    expect(calls, contains('requestLocationPermission'));
  });

  test('拿不到坐标时也会报错', () async {
    await setUpContainer(location: null);
    final controller = container.read(weatherLocationsProvider.notifier);

    await expectLater(
      controller.useCurrentLocation(),
      throwsA(isA<WeatherLocationException>()),
    );
  });

  test('老版本单个城市设置会被迁移成历史位置', () async {
    await setUpContainer(
      preferences: <String, Object>{'settings.weatherCity': '上海'},
    );

    final locations = container.read(weatherLocationsProvider);
    expect(locations, hasLength(1));
    expect(locations.single.city, '上海');
    expect(container.read(activeWeatherLocationProvider)?.label, '上海');
  });

  test('位置去重：同名城市只留一条', () async {
    await setUpContainer();
    final controller = container.read(weatherLocationsProvider.notifier);

    await controller.rememberCity('上海');
    await controller.rememberCity('上海');

    expect(container.read(weatherLocationsProvider), hasLength(1));
  });
}
