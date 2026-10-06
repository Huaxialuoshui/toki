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
  });

  final String id;
  final String title;
  final String personaId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSession &&
        other.id == id &&
        other.title == title &&
        other.personaId == personaId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, title, personaId, createdAt, updatedAt);
}
