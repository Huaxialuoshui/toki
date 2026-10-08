import '../../domain/entities/ai_persona.dart';

/// 人设的「作为日历助手」开关（规格 §3 / §13）。
///
/// * 打开（默认）：把与问题相关的日程 / 倒计时作为上下文发给模型，
///   并允许它调用日程、倒计时、提醒工具；
/// * 关闭：纯聊天 / 扮演——**不注入任何日程数据、不给任何工具**，
///   只使用用户自己写的系统提示词（没写就完全不注入系统提示词）。
///   "提到日程只当聊天与提醒"是提示词层面的约定，所以它仍然可以聊日程。
///
/// 人设为空（应用里还没建过任何人设）时按默认的"是"处理，
/// 让内置的兜底人设保持原来的日历助手行为。
///
/// 这个判断只放在这里：聊天主循环、工具注册表、每日计划都从这里取值，
/// 避免"某一条链路忘了屏蔽日历"。
abstract final class PersonaPrompt {
  /// 是否作为日历助手。
  static bool isCalendarAssistant(AiPersona? persona) =>
      persona?.calendarAssistantEnabled ?? true;

  /// 注入日程上下文、暴露日程工具的前提。
  ///
  /// 语义上就是 [isCalendarAssistant]，单独起名是为了让调用点读起来是
  /// "这条链路要不要碰日历"，而不是"这个人设是不是助手"。
  static bool usesCalendar(AiPersona? persona) => isCalendarAssistant(persona);

  /// 发给模型的系统提示词；没有就返回 null（一条 system 消息都不加）。
  ///
  /// 纯聊天人设只用用户自己写的那一条——界面上的默认日程助手文案
  /// 由编辑器在保存时决定要不要写进 [AiPersona.systemPrompt]。
  static String? systemPromptOf(AiPersona? persona) {
    final prompt = persona?.systemPrompt?.trim() ?? '';
    return prompt.isEmpty ? null : prompt;
  }
}
