import 'dart:math';

/// 生成本地唯一 id。
///
/// 不引入 uuid 依赖：时间戳保证单调、随机后缀避免同一微秒内碰撞，
/// 前缀用于人工排查（`event-` / `countdown-` / ...）。
String generateId(String prefix, {DateTime? now, Random? random}) {
  final timestamp = (now ?? DateTime.now()).microsecondsSinceEpoch;
  final suffix = (random ?? Random()).nextInt(1 << 32).toRadixString(16);
  return '$prefix-$timestamp-$suffix';
}
