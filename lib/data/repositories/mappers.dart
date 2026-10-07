import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Brightness, Color;

import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../domain/entities/calendar_category.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/theme_config.dart';
import '../../infrastructure/database/app_database.dart';

/// `Color` ↔ ARGB int。
///
/// Flutter 3.27 里 `Color.value` 已废弃、`toARGB32()` 还不存在，
/// 因此统一用分量访问器换算（数据库层不依赖 Flutter）。
int argbFromColor(Color color) =>
    ((color.a * 255).round() << 24) |
    ((color.r * 255).round() << 16) |
    ((color.g * 255).round() << 8) |
    (color.b * 255).round();

Color colorFromArgb(int argb) => Color.fromARGB(
      (argb >> 24) & 0xFF,
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
    );

/// 数据库行 ↔ 领域实体 的映射。
///
/// 颜色在数据库里是 ARGB int，领域层是 `Color`，转换只在这里发生，
/// 数据库层因此不依赖 Flutter。
extension CalendarEventRowMapper on CalendarEventRow {
  CalendarEvent toDomain() => CalendarEvent(
        id: id,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        allDay: allDay,
        location: location,
        categoryId: categoryId,
        color: color == null ? null : colorFromArgb(color!),
        repeatRule: repeatRule,
        repeatUntil: repeatUntil,
        reminderMinutes: reminderMinutes,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

CalendarEventsCompanion calendarEventToCompanion(CalendarEvent event) =>
    CalendarEventsCompanion(
      id: Value<String>(event.id),
      title: Value<String>(event.title),
      description: Value<String?>(event.description),
      startTime: Value<DateTime>(event.startTime),
      endTime: Value<DateTime>(event.endTime),
      allDay: Value<bool>(event.allDay),
      location: Value<String?>(event.location),
      categoryId: Value<String?>(event.categoryId),
      color:
          Value<int?>(event.color == null ? null : argbFromColor(event.color!)),
      repeatRule: Value<String?>(event.repeatRule),
      repeatUntil: Value<DateTime?>(event.repeatUntil),
      reminderMinutes: Value<int?>(event.reminderMinutes),
      status: Value<EventStatus>(event.status),
      createdAt: Value<DateTime>(event.createdAt),
      updatedAt: Value<DateTime>(event.updatedAt),
    );

extension CalendarCategoryRowMapper on CalendarCategoryRow {
  CalendarCategory toDomain() => CalendarCategory(
        id: id,
        name: name,
        color: colorFromArgb(color),
        icon: icon,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

CalendarCategoriesCompanion calendarCategoryToCompanion(
  CalendarCategory category,
) =>
    CalendarCategoriesCompanion(
      id: Value<String>(category.id),
      name: Value<String>(category.name),
      color: Value<int>(argbFromColor(category.color)),
      icon: Value<String?>(category.icon),
      sortOrder: Value<int>(category.sortOrder),
      createdAt: Value<DateTime>(category.createdAt),
      updatedAt: Value<DateTime>(category.updatedAt),
    );

extension CountdownRowMapper on CountdownRow {
  CountdownItem toDomain() => CountdownItem(
        id: id,
        title: title,
        targetTime: targetTime,
        description: description,
        color: color == null ? null : colorFromArgb(color!),
        backgroundColor:
            backgroundColor == null ? null : colorFromArgb(backgroundColor!),
        icon: icon,
        isPinned: isPinned,
        displayStyle: displayStyle,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

CountdownsCompanion countdownToCompanion(CountdownItem item) =>
    CountdownsCompanion(
      id: Value<String>(item.id),
      title: Value<String>(item.title),
      targetTime: Value<DateTime>(item.targetTime),
      description: Value<String?>(item.description),
      color:
          Value<int?>(item.color == null ? null : argbFromColor(item.color!)),
      backgroundColor: Value<int?>(
        item.backgroundColor == null
            ? null
            : argbFromColor(item.backgroundColor!),
      ),
      icon: Value<String?>(item.icon),
      isPinned: Value<bool>(item.isPinned),
      displayStyle: Value<CountdownDisplayStyle>(item.displayStyle),
      sortOrder: Value<int>(item.sortOrder),
      createdAt: Value<DateTime>(item.createdAt),
      updatedAt: Value<DateTime>(item.updatedAt),
    );

extension ReminderRowMapper on ReminderRow {
  Reminder toDomain() => Reminder(
        id: id,
        eventId: eventId,
        title: title,
        triggerTime: triggerTime,
        repeatRule: repeatRule,
        enabled: enabled,
        createdAt: createdAt,
      );
}

RemindersCompanion reminderToCompanion(Reminder reminder) => RemindersCompanion(
      id: Value<String>(reminder.id),
      eventId: Value<String?>(reminder.eventId),
      title: Value<String>(reminder.title),
      triggerTime: Value<DateTime>(reminder.triggerTime),
      repeatRule: Value<String?>(reminder.repeatRule),
      enabled: Value<bool>(reminder.enabled),
      createdAt: Value<DateTime>(reminder.createdAt),
    );

extension AiPersonaRowMapper on AiPersonaRow {
  AiPersona toDomain() => AiPersona(
        id: id,
        name: name,
        avatar: avatar,
        description: description,
        personality: personality,
        speakingStyle: speakingStyle,
        userNickname: userNickname,
        systemPrompt: systemPrompt,
        enabledTools: enabledTools,
        temperature: temperature,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

AiPersonasCompanion aiPersonaToCompanion(AiPersona persona) =>
    AiPersonasCompanion(
      id: Value<String>(persona.id),
      name: Value<String>(persona.name),
      avatar: Value<String?>(persona.avatar),
      description: Value<String?>(persona.description),
      personality: Value<String?>(persona.personality),
      speakingStyle: Value<String?>(persona.speakingStyle),
      userNickname: Value<String?>(persona.userNickname),
      systemPrompt: Value<String?>(persona.systemPrompt),
      enabledTools: Value<List<String>>(persona.enabledTools),
      temperature: Value<double>(persona.temperature),
      createdAt: Value<DateTime>(persona.createdAt),
      updatedAt: Value<DateTime>(persona.updatedAt),
    );

extension AiProviderRowMapper on AiProviderRow {
  AiProviderConfig toDomain() => AiProviderConfig(
        id: id,
        name: name,
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        streamingEnabled: streamingEnabled,
        isDefault: isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

AiProvidersCompanion aiProviderToCompanion(AiProviderConfig config) =>
    AiProvidersCompanion(
      id: Value<String>(config.id),
      name: Value<String>(config.name),
      baseUrl: Value<String>(config.baseUrl),
      apiKey: Value<String?>(config.apiKey),
      model: Value<String>(config.model),
      temperature: Value<double>(config.temperature),
      maxTokens: Value<int?>(config.maxTokens),
      streamingEnabled: Value<bool>(config.streamingEnabled),
      isDefault: Value<bool>(config.isDefault),
      createdAt: Value<DateTime>(config.createdAt),
      updatedAt: Value<DateTime>(config.updatedAt),
    );

extension ChatSessionRowMapper on ChatSessionRow {
  ChatSession toDomain() => ChatSession(
        id: id,
        title: title,
        personaId: personaId ?? '',
        providerId: providerId ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

ChatSessionsCompanion chatSessionToCompanion(ChatSession session) =>
    ChatSessionsCompanion(
      id: Value<String>(session.id),
      title: Value<String>(session.title),
      personaId:
          Value<String?>(session.personaId.isEmpty ? null : session.personaId),
      providerId: Value<String?>(
          session.providerId.isEmpty ? null : session.providerId),
      createdAt: Value<DateTime>(session.createdAt),
      updatedAt: Value<DateTime>(session.updatedAt),
    );

extension ChatMessageRowMapper on ChatMessageRow {
  ChatMessage toDomain() => ChatMessage(
        id: id,
        sessionId: sessionId,
        role: role,
        content: content,
        toolCallId: toolCallId,
        requestedToolCalls: role == ChatRole.assistant
            ? ChatToolCall.parseList(toolArguments)
            : const <ChatToolCall>[],
        toolResult: toolResult,
        toolCall: toolName == null
            ? null
            : ToolCallInfo(
                toolName: toolName!,
                // 结果 JSON 里带 error 字段说明工具执行失败（见 AiToolResult）。
                status: _toolResultFailed(toolResult)
                    ? ToolCallStatus.failed
                    : ToolCallStatus.succeeded,
                summary: toolResult == null ? content : null,
              ),
        createdAt: createdAt,
      );
}

bool _toolResultFailed(String? raw) {
  if (raw == null || raw.trim().isEmpty) return false;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map && decoded.containsKey('error');
  } on FormatException {
    return false;
  }
}

ChatMessagesCompanion chatMessageToCompanion(ChatMessage message) =>
    ChatMessagesCompanion(
      id: Value<String>(message.id),
      sessionId: Value<String>(message.sessionId),
      role: Value<ChatRole>(message.role),
      content: Value<String>(message.content),
      toolName: Value<String?>(message.toolCall?.toolName),
      toolCallId: Value<String?>(message.toolCallId),
      toolArguments: Value<String?>(
        message.requestedToolCalls.isEmpty
            ? null
            : ChatToolCall.encodeList(message.requestedToolCalls),
      ),
      toolResult: Value<String?>(message.toolResult),
      createdAt: Value<DateTime>(message.createdAt),
    );

extension ThemeConfigRowMapper on ThemeConfigRow {
  ThemeConfig toDomain() => ThemeConfig(
        id: id,
        name: name,
        brightness: brightness == 'dark' ? Brightness.dark : Brightness.light,
        primaryColor: colorFromArgb(primaryColor),
        secondaryColor: colorFromArgb(secondaryColor),
        backgroundColor: colorFromArgb(backgroundColor),
        surfaceColor: colorFromArgb(surfaceColor),
        textColor: colorFromArgb(textColor),
        borderRadius: borderRadius,
        cardOpacity: cardOpacity,
        blurAmount: blurAmount,
        fontScale: fontScale,
        animationEnabled: animationEnabled,
        shadowStrength: shadowStrength,
      );
}

ThemeConfigsCompanion themeConfigToCompanion(
  ThemeConfig config, {
  required DateTime createdAt,
  required DateTime updatedAt,
}) =>
    ThemeConfigsCompanion(
      id: Value<String>(config.id),
      name: Value<String>(config.name),
      brightness: Value<String>(config.isDark ? 'dark' : 'light'),
      primaryColor: Value<int>(argbFromColor(config.primaryColor)),
      secondaryColor: Value<int>(argbFromColor(config.secondaryColor)),
      backgroundColor: Value<int>(argbFromColor(config.backgroundColor)),
      surfaceColor: Value<int>(argbFromColor(config.surfaceColor)),
      textColor: Value<int>(argbFromColor(config.textColor)),
      borderRadius: Value<double>(config.borderRadius),
      cardOpacity: Value<double>(config.cardOpacity),
      blurAmount: Value<double>(config.blurAmount),
      fontScale: Value<double>(config.fontScale),
      animationEnabled: Value<bool>(config.animationEnabled),
      shadowStrength: Value<double>(config.shadowStrength),
      createdAt: Value<DateTime>(createdAt),
      updatedAt: Value<DateTime>(updatedAt),
    );
