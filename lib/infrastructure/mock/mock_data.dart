import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/chat_message.dart';
import '../../l10n/generated/app_localizations.dart';

/// Phase 2 之后这里只剩两样东西：
///
/// 1. AI 页面用的演示会话（Phase 6-8 接入真实 Provider 后删除）；
/// 2. 数据库里还没有人设时的兜底人设（文案来自 l10n，保证中英一致）。
///
/// 日程与倒计时的 mock 已经删除——它们现在来自 Drift 数据库，
/// 开发用的示例数据见 `lib/data/demo/demo_seed.dart`。
const String mockSessionId = 'session-mock-1';

AiPersona buildFallbackPersona({
  required DateTime now,
  required AppLocalizations l10n,
}) {
  return AiPersona(
    id: 'persona-fallback',
    name: l10n.mockPersonaName,
    description: l10n.mockPersonaDescription,
    personality: l10n.mockPersonaPersonality,
    speakingStyle: l10n.mockPersonaSpeakingStyle,
    userNickname: l10n.mockPersonaNickname,
    systemPrompt: '你是用户的私人日程助手。回答自然简洁，修改日程时必须使用工具操作。',
    temperature: 0.7,
    createdAt: now,
    updatedAt: now,
  );
}

/// 演示会话：一条用户消息 + 一次工具调用 + 一条助手回复。
///
/// 工具调用只展示人类可读的摘要（规格 §12：不要把复杂 JSON 摊给用户）。
List<ChatMessage> buildMockConversation({
  required DateTime now,
  required AppLocalizations l10n,
}) {
  return <ChatMessage>[
    ChatMessage(
      id: 'mock-msg-1',
      sessionId: mockSessionId,
      role: ChatRole.user,
      content: l10n.aiMockUser,
      createdAt: now.subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      id: 'mock-msg-2',
      sessionId: mockSessionId,
      role: ChatRole.tool,
      content: l10n.aiMockToolSummary,
      toolCall: const ToolCallInfo(
        toolName: 'get_events',
        status: ToolCallStatus.succeeded,
      ),
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
    ChatMessage(
      id: 'mock-msg-3',
      sessionId: mockSessionId,
      role: ChatRole.assistant,
      content: l10n.aiMockAssistant,
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
  ];
}
