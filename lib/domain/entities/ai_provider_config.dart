import 'package:flutter/foundation.dart';

/// AI 服务商配置（规格 §2，OpenAI Compatible）。
///
/// `apiKey` 只存在本机数据库，禁止写日志、禁止提交 Git。
/// Phase 6 会补上脱敏 UI 与真实请求逻辑。
@immutable
class AiProviderConfig {
  const AiProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.apiKey,
    this.temperature = 0.7,
    this.maxTokens,
    this.streamingEnabled = true,
    this.isDefault = false,
  });

  final String id;
  final String name;

  /// 例如 `https://api.deepseek.com` 或 `http://127.0.0.1:11434/v1`。
  final String baseUrl;

  final String? apiKey;
  final String model;
  final double temperature;
  final int? maxTokens;
  final bool streamingEnabled;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 给日志/UI 用的脱敏形式，永远不要把 [apiKey] 原样打印出来。
  String get maskedApiKey {
    final key = apiKey;
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}****${key.substring(key.length - 4)}';
  }

  AiProviderConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? streamingEnabled,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 注意：不要把返回值写进日志（包含 API Key）。
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiProviderConfig &&
        other.id == id &&
        other.name == name &&
        other.baseUrl == baseUrl &&
        other.apiKey == apiKey &&
        other.model == model &&
        other.temperature == temperature &&
        other.maxTokens == maxTokens &&
        other.streamingEnabled == streamingEnabled &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        baseUrl,
        apiKey,
        model,
        temperature,
        maxTokens,
        streamingEnabled,
        isDefault,
        createdAt,
        updatedAt,
      );

  /// 刻意不打印 apiKey。
  @override
  String toString() =>
      'AiProviderConfig($id, $name, $baseUrl, $model, key: $maskedApiKey)';
}
