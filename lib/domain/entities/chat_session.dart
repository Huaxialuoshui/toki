import 'package:flutter/foundation.dart';

/// 会话（规格 §5 的 `ChatSession`）。
@immutable
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.personaId,
    required this.createdAt,
    required this.updatedAt,
    this.providerId = '',
  });

  final String id;
  final String title;
  final String personaId;

  /// 这个会话用哪个服务商；空字符串表示"跟随默认服务商"。
  final String providerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession copyWith({
    String? title,
    String? personaId,
    String? providerId,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      personaId: personaId ?? this.personaId,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSession &&
        other.id == id &&
        other.title == title &&
        other.personaId == personaId &&
        other.providerId == providerId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, personaId, providerId, createdAt, updatedAt);
}
