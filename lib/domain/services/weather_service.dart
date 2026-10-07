import '../entities/weather.dart';

/// 天气数据来源（规格 §6 的"天气（暂时预留接口）"）。
///
/// 抽象出来是为了以后换数据源时不动 UI；默认实现用免密钥的 Open-Meteo。
abstract interface class WeatherService {
  /// 按城市名查当前天气；城市不存在或网络失败时抛 [Exception]。
  Future<WeatherSnapshot> fetch(String city);
}
