import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/nav_icon_config.dart';

void main() {
  test('导航图标配置只保存五个一级目的地', () {
    var config = const NavIconConfig();
    for (final route in NavIconConfig.routes) {
      config = config.withPath(route, '/tmp$route.png');
    }
    config = config.withPath('/unknown', '/tmp/unknown.png');

    expect(config.paths, hasLength(5));
    expect(config.pathFor('/home'), '/tmp/home.png');
    expect(config.pathFor('/unknown'), isNull);
  });

  test('导航图标配置可往返 JSON 并移除指定图标', () {
    final config = const NavIconConfig()
        .withPath('/calendar', '/tmp/calendar.png')
        .withPath('/settings', '/tmp/settings.png');
    final decoded = NavIconConfig.fromJson(config.toJson());

    expect(decoded, config);
    expect(decoded.withPath('/calendar', null).pathFor('/calendar'), isNull);
    expect(decoded.pathFor('/settings'), '/tmp/settings.png');
  });
}
