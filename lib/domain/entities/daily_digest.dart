import 'package:flutter/foundation.dart';

/// 每日计划的种类（规格 §14）。
enum DailyDigestKind {
  /// 早间计划：今天有什么安排。
  morning,

  /// 晚间总结：今天做完 / 还剩什么。
  evening,
}

/// AI 生成的"今日计划 / 今日总结"。
///
/// 一天一条，用户可以分别关闭（见设置页的开关），关掉后不再生成，
/// 已经生成的记录保留。
@immutable
class DailyDigest {
  const DailyDigest({
    required this.id,
    required this.kind,
    required this.dayKey,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final DailyDigestKind kind;

  /// 本地日期，格式 `yyyy-MM-dd`。
  final String dayKey;

  /// Markdown 正文。
  final String content;
  final DateTime createdAt;

  /// 把本地时间格式化成 `yyyy-MM-dd`。
  static String keyFor(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyDigest &&
        other.id == id &&
        other.kind == kind &&
        other.dayKey == dayKey &&
        other.content == content &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, kind, dayKey, content, createdAt);
}
