import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 工具类别：决定它需要哪种权限。
enum AiToolCategory { read, create, update, delete }

/// 工具执行结果（会以 JSON 回灌给模型）。
@immutable
class AiToolResult {
  const AiToolResult.success(this.payload) : isError = false;
  const AiToolResult.failure(this.payload) : isError = true;

  final Object? payload;
  final bool isError;

  String toJsonString() => jsonEncode(<String, Object?>{
        if (isError) 'error': payload else 'result': payload,
      });

  @override
  String toString() => 'AiToolResult(error: $isError, payload: $payload)';
}

typedef AiToolHandler = Future<AiToolResult> Function(
  Map<String, Object?> args,
);

/// 一个可以被 AI 调用的工具。
abstract class AiTool {
  const AiTool();

  String get name;
  String get description;
  AiToolCategory get category;

  /// JSON Schema 形式的参数定义。
  Map<String, Object?> get parameters;

  /// 危险操作需要用户二次确认（删除，以及批量修改）。
  bool get requiresConfirmation => category == AiToolCategory.delete;

  Future<AiToolResult> execute(Map<String, Object?> args);
}

/// 用闭包实现的工具，避免为 15 个工具写 15 个类。
class SimpleAiTool extends AiTool {
  const SimpleAiTool({
    required this.name,
    required this.description,
    required this.category,
    required this.parameters,
    required this.handler,
    this.confirm = false,
  });

  @override
  final String name;

  @override
  final String description;

  @override
  final AiToolCategory category;

  @override
  final Map<String, Object?> parameters;

  final AiToolHandler handler;
  final bool confirm;

  @override
  bool get requiresConfirmation =>
      confirm || category == AiToolCategory.delete;

  @override
  Future<AiToolResult> execute(Map<String, Object?> args) => handler(args);
}

/// 参数读取辅助：缺失/格式错误时返回 null，由工具自己给出可读错误。
extension AiToolArgs on Map<String, Object?> {
  String? optionalString(String key) {
    final value = this[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? requiredString(String key) => optionalString(key);

  int? optionalInt(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  bool optionalBool(String key, {bool fallback = false}) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) {
      final text = value.toLowerCase().trim();
      if (text == 'true' || text == '1') return true;
      if (text == 'false' || text == '0') return false;
    }
    return fallback;
  }

  /// 解析 ISO-8601 时间（例如 `2026-10-20T15:00:00+08:00`）。
  ///
  /// 规格 §20 要求时间解析必须明确，因此这里只接受 ISO 字符串，
  /// 解析失败返回 null，由工具提示模型重新给出明确时间。
  DateTime? optionalDateTime(String key) {
    final text = optionalString(key);
    if (text == null) return null;
    try {
      return DateTime.parse(text);
    } on FormatException {
      return null;
    }
  }
}

/// 把时间统一格式化为带时区偏移的 ISO 串（给模型看）。
String isoWithOffset(DateTime time) => time.toIso8601String();
