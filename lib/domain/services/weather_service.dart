import '../entities/weather.dart';

/// 天气数据来源（规格 §6 的"天气（暂时预留接口）"）。
///
/// 抽象出来是为了以后换数据源时不动 UI；默认实现用免密钥的 Open-Meteo。
abstract interface class WeatherService {
  /// 按城市名查当前天气；城市不存在或网络失败时抛 [Exception]。
  Future<WeatherSnapshot> fetch(String city);

  /// 按 GPS 坐标查天气（[label] 用来在界面上标识"当前位置"）。
  Future<WeatherSnapshot> fetchByCoordinates({
    required double latitude,
    required double longitude,
    String label = '当前位置',
  });
}

/// 最多保留几个历史位置。
const int maxWeatherLocations = 8;

/// 历史位置存储（应用级轻量数据，放 shared_preferences）。
abstract interface class WeatherLocationStore {
  /// 最近使用的在前。
  List<WeatherLocation> load();

  /// 记住一个位置：同一个位置去重置顶，最多保留 [maxWeatherLocations] 个。
  Future<List<WeatherLocation>> remember(WeatherLocation location);

  Future<List<WeatherLocation>> forget(String id);
}
