# Toki

本地优先的 AI 日历 / 倒计时 / 提醒应用，Android 与 Windows 双端共用一套 Flutter 代码。

> 当前状态：**Phase 10（聊天自定义）已完成**：聊天背景（纯色 / 渐变 / 图片 + 模糊 / 透明度 / 遮罩）、
> 头像、气泡、字号、消息动画都可自定义；主题编辑器 / 备份等后续阶段待做。

平台验证状态（2026-10-06）：

| 平台 | analyze | test | 构建 | 运行 |
| --- | --- | --- | --- | --- |
| Android | ✅ | ✅ 171/171 | ✅ `flutter build apk --debug` / `--release` | ✅ 模拟器实测：日程 / 倒计时增删改、拖拽排序、通知投递、闹钟跨进程存活、AI 流式聊天、人设 CRUD、AI 真实创建日程、上下文注入、聊天外观 |
| Windows | ✅ | ✅ 171/171 | ✅ `flutter build windows` | ✅ 运行实测（桌面鼠标拖动排序）；系统 Toast 可见性待你空闲时确认 |

## 项目介绍

Toki 的目标是把「日历 + 倒计时 + 提醒 + 可自定义人设的 AI 助手」放在同一个本地应用里，
数据默认只存在本机，AI 通过结构化工具（Tool Calling）操作日历数据，而不是让模型直接改数据库。

## 功能

已实现（Phase 1-2）

- 三档响应式布局：手机底部导航 / 平板 NavigationRail / 桌面可折叠 Sidebar
- 五个一级页面：首页、日历、倒计时、AI 助手、设置
- 主题系统：`ThemeConfig` 模型 + Default / Light / Dark 三套预设 + 跟随系统 + 字号 / 圆角微调
- 玻璃拟态层与 `ThemeData` 解耦（`GlassStyle` / `GlassCard`）
- 中英双语（`zh` / `en`），默认跟随系统、系统语言不受支持时回退中文
- 倒计时统一节拍源（`CountdownController`），秒级只重建叶子组件
- 设置持久化（语言 / 主题 / 微调）写入 shared_preferences
- **本地数据库（Drift + SQLite）**：9 张表 + 8 个仓储 + 迁移快照与迁移测试
- 首页 / 日历 / 倒计时改为读取数据库，并提供加载中与空状态；debug 构建首次启动写入示例数据
- **日历交互**：月 / 周 / 日三种视图、新建 / 编辑 / 删除日程（二次确认）、全天事件、日期与时间选择器、
  事件颜色、分类、提醒预设（准时 / 5 / 10 / 30 / 60 分钟 / 1 天），保存事件时同步提醒行
- **倒计时交互**：新建 / 编辑 / 删除、置顶开关、拖动排序（移动端长按手柄、桌面直接拖）、
  两种显示样式（大数字 / 完整文本）、颜色与目标时间选择器，每秒实时刷新
- **通知提醒**：`NotificationService` 抽象 + Android 本地通知 / Windows Toast（同一插件两端实现）、
  提醒自动排期与取消、通知权限与"精确提醒"入口、测试通知，设置页可视状态
- **AI Provider**：`AiProvider` 抽象 + OpenAI Compatible 实现（含 SSE 流式）、服务商配置界面
  （预设 / Base URL / API Key 脱敏 / 模型 / 温度 / 最大 token / 流式开关 / 测试连接）、
  真实聊天与逐字输出，会话与消息落库
- **AI 人设**：人设 CRUD（名称 / 身份 / 头像 / 性格 / 说话方式 / 称呼 / 系统提示词 / 温度）、
  聊天页切换人设、头像支持 emoji / 单字 / 图片路径或 URL
- **AI Tool Calling**：15 个工具（时间 / 日程查询与增删改 / 倒计时 / 提醒 / 搜索 / 汇总）、
  工具权限开关（查询 / 创建 / 修改 / 删除，删除默认关闭）、危险操作二次确认、
  工具结果回灌给模型（绝不"嘴上说创建成功"）
- **AI 上下文**：按问题解析时间范围（今天 / 明天 / 本周 / 下周 / 本月 / 具体日期）与提及的倒计时，
  只注入相关切片；条数与字符双重上限，历史裁剪不会截断工具调用对
- **聊天自定义**：背景（纯色 / 渐变 / 图片，图片支持相册或文件选择、透明度、模糊、暗色遮罩）、
  我的头像、气泡透明度与圆角、聊天字号、消息动画，设置页实时预览

计划中（尚未实现，按阶段推进）

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| Phase 0 | 环境 + 项目脚手架 | ✅ |
| Phase 1 | App Shell / 响应式 / 主题 / i18n | ✅ |
| Phase 2 | Drift + SQLite、Repository CRUD、迁移测试 | ✅ |
| Phase 3 | 日历增删改、全天 / 时间选择器、颜色、周 / 日视图 | ✅ |
| Phase 4 | 倒计时 CRUD、置顶、拖动排序、跨天/跨月/跨年/时区/夏令时测试 | ✅ |
| Phase 5 | Android 本地通知 / Windows Toast、提醒排期 | ✅ |
| Phase 6 | AI Provider（OpenAI Compatible）+ 流式聊天 | ✅ |
| Phase 7 | AI 人设 CRUD 与聊天页切换 | ✅ |
| Phase 8 | AI Tool Calling + 工具权限 + 危险操作确认 | ✅ |
| Phase 9 | ContextService：动态上下文与 Token 控制 | ✅ |
| Phase 10 | 聊天自定义：背景 / 头像 / 气泡 / 字号 / 动画 | ✅ |
| Phase 6-8 | AI Provider、Persona、Tool Calling + 权限 | ⏳ |
| Phase 9-13 | Context、聊天自定义、主题编辑器、备份、质量优化 | ⏳ |

## 技术栈

| 用途 | 选型 |
| --- | --- |
| UI / 跨端 | Flutter 3.27.2 (stable) · Dart 3.6.1 |
| 状态管理 | flutter_riverpod 2.x |
| 路由 | go_router 14.x（`StatefulShellRoute.indexedStack`） |
| 轻量设置存储 | shared_preferences（仅应用级设置，见下） |
| 本地数据库 | drift 2.28 + sqlite3（Android/Windows 原生库由 sqlite3_flutter_libs 提供） |
| 国际化 | flutter_localizations + intl（ARB → `lib/l10n/generated`） |

暂未引入（按阶段添加）：Dio、json_serializable / freezed、timezone、通知插件。

> 版本说明：drift 2.29+ 需要 `build` 3.x，而使用 `build` 3.x 的 `build_runner` 要求 Dart 3.7+；
> 本机是 Flutter 3.27.2 / Dart 3.6.1，因此固定在 `drift 2.28.x + drift_dev 2.28.0 + build_runner 2.4.15`。

### 存储边界

`shared_preferences` 只保存**应用级轻量设置**：语言、当前主题 id、是否跟随系统、字号 / 圆角微调、首次启动标记。

领域数据（日程、倒计时、提醒、人设、会话）以及用户自建 / 导入导出的主题都在数据库里，两类数据互不迁移。

## 目录结构

```
lib/
├── main.dart                     # 启动：初始化 shared_preferences 后运行 App
├── app/
│   ├── app.dart                  # MaterialApp.router（主题 / i18n / GlassTheme）
│   └── router.dart               # go_router：五个 branch
├── core/
│   ├── clock.dart                # 可注入时钟（测试用 FixedClock）
│   ├── constants/                # 断点、版本等常量
│   ├── errors/                   # AppException
│   ├── extensions/               # context.l10n 等
│   └── utils/                    # 日期格式化
├── domain/entities/              # ThemeConfig / GlassStyle / CalendarEvent / CountdownItem / AiPersona / Chat*
├── domain/repositories/          # 仓储抽象（上层只依赖接口）
├── data/
│   ├── repositories/             # Drift 实现 + 行↔实体映射 + Provider 装配
│   └── demo/demo_seed.dart       # debug 构建的示例数据
├── application/
│   ├── countdown/                # CountdownController（唯一 1Hz 节拍）
│   ├── calendar/                 # 数据库 StreamProvider + 写操作（CalendarActions）
│   ├── ai/                       # 人设 / 服务商 Provider + ChatController（流式聊天）
│   ├── notification/             # ReminderScheduler：提醒 → 系统通知
│   ├── theme/                    # 预设、ThemeConfig → ThemeData、主题控制器
│   └── settings/                 # 语言、首次启动、启动初始化
├── infrastructure/
│   ├── database/                 # Drift 表定义、AppDatabase、连接、转换器
│   ├── ai/                       # OpenAI Compatible 实现（Dio + SSE）
│   ├── notification/             # Android 通知 / Windows Toast 实现
│   ├── storage/                  # shared_preferences 封装
│   └── mock/                     # 仅剩 AI 演示会话 + 兜底人设
├── presentation/
│   ├── shell/                    # 响应式 Shell 与三档布局
│   ├── home/ calendar/ countdown/ ai/ settings/
│   └── widgets/                  # PageScaffold、SectionHeader、EventTile、CountdownCard
├── shared/widgets/               # GlassTheme / GlassCard
└── l10n/                         # app_zh.arb / app_en.arb + generated/
```

## 环境安装

本机已验证可用的环境：

| 组件 | 位置 / 版本 |
| --- | --- |
| Flutter SDK | `D:\Flutter\flutter`（3.27.2 stable，已加入用户级 PATH） |
| Dart | 3.6.1（随 Flutter SDK） |
| Android SDK | `D:\androidSDK`（platform 33/34/35、build-tools 35.0.0、cmdline-tools latest） |
| JDK（Gradle 使用） | `D:\Program Files\Java\jdk-17.0.12`（`flutter config --jdk-dir=...`） |
| Android Studio | `D:\Program Files\Android\Android Studio`（2024.2） |
| 模拟器 | AVD `toki_api34`（Android 14 / google_apis_playstore / x86_64） |
| Windows 工具链 | Visual Studio Community 2026 18.10.3（`D:\Program Files\vscode`）+ MSVC 14.51.36231 + Windows SDK 10.0.28000.0 |

首次配置命令（换机器时参考）：

```powershell
$env:Path = "D:\Flutter\flutter\bin;" + $env:Path
flutter config --android-sdk D:\androidSDK
flutter config --jdk-dir="D:\Program Files\Java\jdk-17.0.12"
flutter doctor -v
```

## Windows 运行 / 构建

前置条件：**Visual Studio +「使用 C++ 的桌面开发」工作负载**（含 MSVC 工具集与 Windows 10/11 SDK）。

```powershell
flutter run -d windows
flutter build windows
# 产物：build\windows\x64\runner\Release\toki.exe
```

本机已用 **Visual Studio Community 2026（版本 18.x）** 验证通过。

> ⚠️ 版本注意：Flutter 3.27.2 的 `visual_studio.dart` 只映射 VS 16(2019) / 17(2022) 的 CMake 生成器，
> 遇到 VS 18(2026) 会回落到 `Visual Studio 16 2019` 并报 `could not find any instance of Visual Studio`。
> 本机在 Flutter SDK 内补了一行映射 `18 => 'Visual Studio 18 2026'`（见「常见问题」）。
> 升级 Flutter 后如果上游已支持 VS 2026，可用同样方式把这行改动还原。

## Android 运行 / 构建

```powershell
# 启动模拟器（已有 AVD）
D:\androidSDK\emulator\emulator.exe -avd toki_api34

flutter devices
flutter run -d android

# 只产出调试包
flutter build apk --debug
# 产物：build\app\outputs\flutter-apk\app-debug.apk
```

## AI 配置 / Provider 配置（规划）

Phase 6 起提供「OpenAI Compatible」Provider 配置（Base URL / API Key / Model / Temperature / Max Tokens / 流式开关），
Phase 7 起提供人设管理，Phase 8 起提供工具调用与工具权限。API Key 只保存在本机、不写日志、不进 Git。

## 数据库说明

Drift + SQLite，`schemaVersion = 1`，共 9 张表：

| 表 | 说明 |
| --- | --- |
| `calendar_categories` | 日历分类（颜色 / 图标 / 排序） |
| `calendar_events` | 日程（时间、全天、地点、分类、颜色、重复规则、提前提醒） |
| `countdowns` | 倒计时（目标时间、置顶、显示样式、拖动排序位） |
| `reminders` | 提醒（关联日程、触发时间、重复规则、启用开关） |
| `ai_personas` | AI 人设（性格、语气、称呼、系统提示词、可用工具 JSON、温度） |
| `ai_providers` | OpenAI Compatible 服务商（Base URL / 模型 / 温度 / 最大 token / 流式 / 默认标记 / API Key） |
| `chat_sessions` | 会话（关联人设） |
| `chat_messages` | 消息（role、内容、工具名 / 参数 / 结果） |
| `theme_configs` | 用户自建 / 导入的主题 |

约定：

* 时间列用 drift 的 `dateTime()`，以 **Unix 时间戳（秒）** 保存绝对时刻，读回成本地时间（精度到秒）；
* 颜色以 ARGB int 存储，数据库层不依赖 Flutter；
* 打开数据库时执行 `PRAGMA foreign_keys = ON`，外键（分类 / 人设 / 会话）真实生效；
* 数据库文件：Android `files/toki.sqlite`（应用私有目录）、Windows `%APPDATA%\com.toki\toki\toki.sqlite`；
* **示例数据只在 debug 构建、且数据库为空时写入**（`lib/data/demo/demo_seed.dart`），release 从空库开始；
* `api_providers.api_key` 只保存在本机，禁止写日志；Phase 6 会加脱敏 UI，必要时改为系统安全存储。

### 改表结构时的流程

```powershell
# 1. 改 lib/infrastructure/database/tables/*.dart，并在 AppDatabase.migration 里补 onUpgrade
# 2. 重新生成代码
dart run build_runner build --delete-conflicting-outputs
# 3. 导出新版本 schema 并生成迁移测试骨架
dart run drift_dev schema dump lib/infrastructure/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
# 4. 在 test/data/migration_test.dart 里补 vN → vN+1 的用例
flutter test test/data/migration_test.dart
```

## 日历交互说明（Phase 3）

* **视图**：月视图是 7 列网格（宽屏限制在 560px 内，避免格子被撑成巨大方块）；周 / 日视图是
"议程式"列表（按天分组、可单日添加）——真正的"时间网格"排布留到后续按需再做。
* **新建 / 编辑**：点顶部或区块的「新建日程」、周 / 日视图里每天的「+」都可以新建；点事件卡片看详情，
详情里「编辑」进入表单。
* **表单字段**：标题（必填）、全天开关、开始 / 结束（日期 + 时间选择器）、地点、描述、分类、颜色（8 色 + 默认）、
提醒（准时 / 5 / 10 / 30 / 60 分钟 / 1 天）。
* **校验**：标题不能为空；结束时间必须晚于开始时间（不满足时表单内红字提示，不落库）。
* **全天事件**：开始为当天 00:00、结束为次日 00:00（半开区间），月历格子与列表都按"覆盖到这一天"判定。
* **提醒**：保存事件时按 `reminderMinutes` 同步 `reminders` 表（同一事件只保留一条，改时间会跟着走，
取消提醒会删除）；删除事件会先删提醒再删事件，避免外键约束报错。真正的通知调度在 Phase 5。
* **删除**：编辑器底部「删除」→ 二次确认 → 删除。
* 已知范围限制：分类目前只能在示例数据里出现，管理分类（增删改）不在本阶段；`repeatRule`
（重复日程）字段已入库但界面未开放，留到后续阶段。

## 倒计时说明（Phase 4）

* **列表**：倒计时页本身就是滚动容器（`PageScaffold(scrollable: false)` + `ReorderableListView`），
  否则拖动手势会被外层滚动抢走。
* **拖动排序**：移动端是"长按手柄 → 拖动"（触摸设备上"按下即拖"会被列表滚动抢走手势）；
  桌面端是"直接拖手柄"。排序结果写回 `countdowns.sort_order`。
  跨分组拖动（置顶 ↔ 未置顶）会被忽略，改分组请用图钉按钮。
* **置顶**：卡片右侧图钉按钮切换，置顶项进入「已置顶」分组。
* **显示样式**：大数字（大号天数 + `hh:mm:ss`）或完整文本（`距离「X」还有 13天 08小时 21分钟 45秒`）。
* **实时刷新**：所有卡片共用 `CountdownController` 的唯一 1Hz 节拍，秒级只重建秒数叶子组件。
* **时间处理**：剩余量始终是 `targetTime - now` 的**绝对时长**（epoch 相减），
  因此时区、夏令时都不会让它多算/少算一小时（`test/domain/countdown_time_zones_test.dart` 覆盖：
  跨天、跨月、跨年、UTC/本地混用、春季拨快（当天 23 小时）、秋季拨回（当天 25 小时）、目标时间已过去）。

## AI 助手说明（Phase 6）

### 配置 AI 服务商

设置 → AI 与服务商 → 添加服务商。可以点「快速填充」选常见服务商（DeepSeek / OpenAI / Qwen /
Moonshot / 智谱 / Ollama），也可以手填：

| 字段 | 说明 |
| --- | --- |
| Base URL | 例如 `https://api.deepseek.com`、`https://api.deepseek.com/v1`、`http://127.0.0.1:11434/v1`；末尾会自动补 `/chat/completions` |
| API Key | 只保存本机数据库，界面默认隐藏、列表里只显示 `sk-x****abcd`，日志与异常里都不带原文 |
| 模型 | 例如 `deepseek-chat`、`gpt-4o-mini`、`qwen2.5:7b` |
| 温度 / 最大 Token / 流式输出 | 可选 |

「测试连接」会用当前表单发一条最小请求（非流式），成功时把模型回复的前 40 字显示出来，
失败时显示可读原因（HTTP 状态 + 提示，例如 401 → Key 可能无效、404 → 检查 Base URL）。

### 聊天与流式输出

* AI 页调用当前生效的服务商（默认项优先，否则列表第一个），逐块渲染回复——**用户能看到逐字输出**；
* 发送中按钮变成「停止」，中止后已收到的部分会保留并落库；
* 用户消息与助手回复都写入 `chat_messages`，会话写入 `chat_sessions`；
* 请求里会带上人设的 system prompt（来自 `ai_personas`）与历史消息；
* 出错时显示可读错误横幅，不会伪造助手回复。

### 没有 API Key 也能验证

仓库自带一个最小 OpenAI 兼容 mock 服务：

```powershell
python tool/mock_openai_server.py 11434
adb reverse tcp:11434 tcp:11434          # Android 模拟器/真机：把端口转发进设备
# 然后在 App 里添加服务商：Base URL http://127.0.0.1:11434/v1，模型随便填（如 qwen2.5:7b）
```

它支持非流式与 SSE 流式两种响应，用来验证整条链路（网络 → 解析 → 逐字渲染 → 落库）。

### 人设（Phase 7）

设置 → AI 人设：可以新建 / 编辑 / 删除多个 AI 人设，字段包括：

| 字段 | 说明 |
| --- | --- |
| 名称 | 显示在聊天页顶部与消息气泡旁 |
| 身份 | 一句话说明（例如「私人日程助手」） |
| 头像 | emoji / 单个字 / 图片路径 / `http(s)` 图片 URL；图片加载失败自动回落到文字头像 |
| 性格 / 说话方式 | 会拼进 system prompt 的补充说明 |
| 对你的称呼 | 例如「主人」 |
| 系统提示词 | 直接作为 `system` 消息发给模型；留空则用默认提示词 |
| 温度 | 该人设的默认采样温度 |

聊天页右上角的人设按钮可以切换（菜单里还有「管理人设」跳设置页）。切换只影响**后续请求**的
system prompt——`chat_sessions.persona_id` 记录当前会话选用的人设；删除人设前会先把引用它的会话置空，
否则会撞 `chat_sessions.persona_id` 的外键约束（这个坑有专门的回归测试）。

### AI 工具调用（Phase 8）

AI 不能碰数据库，只能通过工具层操作；工具执行结果会原样回灌给模型，模型再据此回答。

| 工具 | 类别 | 说明 |
| --- | --- | --- |
| `get_current_time` | 查询 | 当前时间 / 星期 / 时区偏移（推算"明天下午"前必须先调它） |
| `get_today_events` / `get_events` / `search_events` / `get_calendar_summary` | 查询 | 今日、范围、关键词、汇总 |
| `create_event` / `update_event` / `delete_event` | 创建 / 修改 / 删除 | 日程；带 `reminder_minutes` 时会同步提醒行 |
| `get_countdowns` / `create_countdown` / `update_countdown` / `delete_countdown` | 查询 / 创建 / 修改 / 删除 | 倒计时，查询结果含剩余天数 |
| `create_reminder` / `update_reminder` / `delete_reminder` | 创建 / 修改 / 删除 | 独立提醒 |

* **权限**：设置 → AI 权限里有四个开关（查询 / 创建 / 修改 / 删除）。**删除默认关闭**；
  被拒绝的工具会返回"未授权"，模型必须如实告诉用户，而不是假装完成。
  人设的 `enabled_tools` 非空时会进一步收窄可用工具。
* **二次确认**：删除类工具（以及 `update_event` / `update_countdown` / `update_reminder` 这类可能改坏数据
  的操作）会先弹确认框，列出工具与参数；拒绝后工具返回"用户拒绝"，数据不动。
* **时间必须明确**：工具只接受 ISO-8601 时间；模型给模糊时间会被工具拒绝并提示重新给出明确时间
  （规格 §20 的"时间解析必须明确"）。
* **失败不掩盖**：工具异常 / 参数错误 / 找不到 id 都会以 `{"error": ...}` 回灌；聊天里显示
  "工具调用 · 修改日程 — 执行失败"。
* **循环上限**：一次用户输入最多 5 轮"模型 → 工具 → 模型"，避免模型反复调用停不下来。
* 调试：`tool/inspect_device_db.dart` 可以把设备数据库拉下来直接看 AI 到底写了什么。

### AI 上下文（Phase 9）

模型**不会**拿到整个数据库。每次用户发消息时 `ContextService` 先看问题里有什么线索：

| 问题里出现 | 注入内容 |
| --- | --- |
| 今天 / 明天 / 后天 / 昨天 | 对应那一天的日程 |
| 这周 / 本周 / 下周 | 周一到周日的日程 |
| 本月 / 下个月 | 那个月的日程 |
| 具体日期（`2026-10-20`、`10月20日`、`10/20`） | 那一天的日程 |
| 倒计时标题（例如"毕业答辩"） | 那一条倒计时 |
| 其它 | 今天起 7 天的日程 + 最近几条（或已提及的）倒计时 |

另外始终带上当前时间 / 星期 / 时区偏移。上限：最多 12 条日程、4 条倒计时、约 1600 字符；
超出会写明"共 N 条，其余已省略"或"上下文过长已截断"，避免模型误以为没有更多数据。

历史消息只带最近 40 条，并且**从一条 user 消息开始**——否则可能把 `assistant(tool_calls)` 或
`tool` 结果截断，OpenAI 兼容接口会直接报错；工具结果超过 2000 字符也会截断。

### 聊天自定义（Phase 10）

设置 → 聊天外观，改完立刻在下方预览区生效：

| 项目 | 支持 |
| --- | --- |
| 聊天背景 | 纯色（色板）、渐变（两色）、图片（相册 / 文件选择器，也支持直接填路径或 URL） |
| 图片参数 | 透明度、背景模糊（0-30）、暗色遮罩不透明度 |
| 我的头像 | emoji / 单个字 / 图片路径或 URL（AI 头像在 Phase 7 的人设里） |
| 气泡 | 不透明度（0.4-1）、圆角（0-32） |
| 字体 | 聊天区字号缩放（0.85-1.4） |
| 动画 | 消息入场动画开关 |

这些设置属于"应用级外观"，和主题 id 一样存在 shared_preferences（JSON）；
用户自建主题（把背景打包进主题）属于 Phase 11 的数据库表。
图片加载失败会自动回落到纯色背景，不会出现裂图。

## 通知说明（Phase 5）

* **抽象**：业务层只依赖 `NotificationService`（`initialize` / `requestPermission` /
  `areNotificationsEnabled` / `scheduleNotification` / `cancelNotification` / `cancelAll`，
  另有 Android 专用的 `requestExactAlarmPermission`）。
  实现放在 `infrastructure/notification`：Android 用系统本地通知、Windows 用系统 Toast，
  两者都来自 `flutter_local_notifications`（同一个包的两个平台实现）。
* **排期策略**（`ReminderScheduler`，幂等）：
  目标集合 = 已启用且触发时间在未来的 `reminders` 行；先取消"上次排过、这次不在集合里"的通知
  （覆盖提醒被删除 / 停用 / 改到过去），再重新排期；已排期的通知 id 记在 shared_preferences 里，
  用来精确取消而不是"清空所有通知"。
* **通知内容**：标题 = 事件标题；正文按提前量生成（`30 分钟后开始` / `2 小时后开始` /
  `1 天后开始` / `现在开始`），语言跟随应用语言设置，没有关联日程时用通用文案。
* **应用关闭后仍能提醒**：提醒交给 Android 的 `AlarmManager`（`RTC_WAKEUP` + 通知接收器），
  进程结束后闹钟仍由系统持有。实测：`am crash` 杀掉进程后，`dumpsys alarm` 里
  `com.toki.toki` 的两条 RTC_WAKEUP 仍原样存在 ✅。清单里也注册了
  `ScheduledNotificationBootReceiver`，开机 / 应用更新后会重新登记。
* **精确提醒权限**：Android 12+ 的 `SCHEDULE_EXACT_ALARM` 默认不授予，插件会抛
  `exact_alarms_not_permitted`；实现里捕获后退回 `inexactAllowWhileIdle`（提醒仍会送达，
  可能被系统推迟几分钟），设置页提供"允许精确提醒"入口按需开启，不会一进应用就跳系统设置。
* **Windows 说明**：`flutter_local_notifications_windows` 用了 `<experimental/coroutine>`，
  VS 2026（MSVC 14.5x）默认视为错误，`windows/CMakeLists.txt` 里加了官方建议的
  `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` 才能编译通过。
  桌面端 Toast 的可见性验证留给你空闲时点一下设置页的"发送一条测试通知"确认
  （我这边自动化时会抢占你正在使用的桌面，就没有继续）。
* **调试工具**：`tool/seed_device_reminder.dart` 可以往设备数据库里写一条"马上要触发"的提醒，
  便于手工验证"关掉应用后仍能提醒"。

## 测试

```powershell
flutter analyze
flutter test
```

当前 171 个测试，覆盖：

* 领域：倒计时拆分（跨天 / 跨月 / 跨年 / 已过去）、日历事件命中判定
* 领域·时间：时区混用、夏令时（春季 23 小时 / 秋季 25 小时）、目标时间正好是现在
* 应用层：倒计时节拍（单 Timer、多订阅、释放）、主题解析、`ThemeData` 与玻璃层职责分离、字号缩放、
  事件保存时的提醒同步（新增 / 替换 / 清除 / 改时间）与"删除事件先删提醒"
* 应用层·倒计时：创建（id / 时间戳 / 排序位）、更新保留 createdAt、置顶分组切换、拖动顺序写回、删除
* 应用层·通知：只排期"启用且在未来"的提醒、提前量文案（分钟 / 小时 / 天 / 到点 / 无关联日程）、
  删除 / 停用 / 改到过去会取消排期、重复同步幂等、通知 id 稳定非负
* 数据层：8 个仓储的 CRUD / 排序 / 置顶 / 重排 / 默认服务商 / 外键级联、UTC 往返、示例数据幂等、迁移快照校验
* 界面：响应式断点（599/600/999/1000）、五个导航目的地可达、语言跟随系统与回退中文、语言持久化、
  倒计时卡片秒级刷新、空数据库的空状态、日历新建 / 编辑 / 删除 / 校验 / 全天开关 / 月周日视图切换
* 界面·倒计时：新建 / 编辑（含样式切换）/ 删除二次确认 / 置顶分组 / 拖动排序
* 界面·通知：权限状态展示、请求权限、发送测试通知
* AI 层：Base URL 规范化、请求体字段、Authorization 头（有/无 Key）、SSE 解析（含 keep-alive 注释、
  `data:` 无空格、UTF-8 跨分片）、`[DONE]` 与无 `[DONE]` 收尾、错误映射（401/404/连接失败）且不含 Key
* AI 应用层：发送后用户 + 助手消息落库、流式状态逐块更新、system prompt 与历史顺序、
  出错不写助手消息、中止保留已收到内容、清空对话
* 界面·AI：未配置时的提示与入口、发送后逐字显示回复、错误横幅、清空对话
* 人设：设置页新建 / 编辑 / 删除、删除时清理会话引用（外键回归）、
  聊天页切换人设并让后续请求带上新的 system prompt
* 工具层：15 个工具的注册与执行（创建/修改/删除/查询/搜索/汇总/倒计时/提醒）、
  非法时间与缺失参数的报错、id 不存在不抛异常、删除类工具标记为需确认
* 工具权限：默认关闭删除；关闭创建后不再暴露创建工具；人设 `enabled_tools` 收窄可用工具；
  工具定义是标准 function calling 结构
* 工具循环：模型请求 `create_event` → 数据真的落库 + 消息序列 user/assistant/tool/assistant +
  第二次请求带上工具结果；未授权删除 → 数据不变且模型收到"未授权"；
  授权后用户拒绝确认 → 不删除；用户确认 → 真删除
* 上下文：按"今天 / 下周 / 具体日期"筛选日程、按提及筛选倒计时、条数与字符上限、
  空库不报错、请求里确实注入了上下文、超长历史裁剪后不留孤儿 tool 消息
* 聊天外观：模型 JSON 往返与非法值回落、控制器持久化到 shared_preferences 并能重新读出、
  数值范围限制、恢复默认、清除头像、聊天页使用配置的背景、默认外观下是纯色、
  设置页切换背景类型后预览同步

> 数据库测试跑在 Dart VM 上，需要 sqlite3 动态库：第一次运行前先执行一次 `flutter build windows`
> （测试会自动把 `sqlite3.dll` 缓存到 `.dart_tool/`，`flutter clean` 不会删）。

## 常见问题

**Gradle 发行包下载失败 / 连接被重置**
`android/gradle/wrapper/gradle-wrapper.properties` 已指向腾讯云镜像（版本仍是 Flutter 模板的 8.3）。
如需换回官方源，把 `distributionUrl` 改回 `https://services.gradle.org/distributions/gradle-8.3-all.zip`。

**`Undefined class 'Size'` / `dart:ui` 类型解析失败**
说明 Flutter SDK 缓存里的 `bin/cache/pkg/sky_engine` 不完整（缺少 `lib/ui/geometry.dart`）。
重新下载对应 engine revision 的 `sky_engine.zip` 覆盖该目录即可。

**Gradle 报 Java 版本不兼容**
Flutter 模板的 Gradle 8.3 需要 JDK 17；本机通过 `flutter config --jdk-dir` 指向 JDK 17，
不要用 Android Studio 自带的 JBR 21 直接跑该模板。

**Windows 构建失败**
按报错分两类处理：

1. `Unable to find suitable Visual Studio toolchain`：说明没装「使用 C++ 的桌面开发」工作负载，
   用 Visual Studio Installer 勾选安装（含 Windows SDK）。
2. `CMake Error ... Generator "Visual Studio 16 2019" could not find any instance`：
   Flutter 版本不认你安装的 VS 大版本。检查 `flutter doctor -v` 里显示的 VS 版本号，
   在 `packages/flutter_tools/lib/src/windows/visual_studio.dart` 的 `cmakeGenerator` 中补上对应分支，例如：

   ```dart
   return switch (_majorVersion) {
     18 => 'Visual Studio 18 2026',
     17 => 'Visual Studio 17 2022',
     _  => 'Visual Studio 16 2019',
   };
   ```

   改完删掉 `bin/cache/flutter_tools.stamp`（下次运行会自动重新编译 flutter_tools），再重新构建。
   如果之前用错误的生成器失败过，需要先删掉 `build/windows` 或执行 `flutter clean`，否则 CMake 会抱怨
   `generator does not match the generator used previously`。

   还原方式：`git -C <Flutter SDK> checkout -- packages/flutter_tools/lib/src/windows/visual_studio.dart`

**`flutter test` 报找不到 sqlite3 动态库**
数据库测试需要 `sqlite3.dll`。先跑一次 `flutter build windows`，或把 `sqlite3.dll` 放到 `.dart_tool/`。

**widget 测试报 `A Timer is still pending`**
drift 在取消查询流时会安排一个零延时 Timer 做缓存清理。测试请使用 `test/helpers/test_app.dart` 里的
`tokiWidgetTest(...)`：它会在测试体结束后卸载 App 并关闭数据库（drift 官方也是这么建议的）。

## 开发原则

1. 平台相关能力必须经过抽象层，业务层不直接调用 Android / Windows API。
2. AI 只能通过结构化工具修改数据，禁止"嘴上说创建成功"。
3. 依赖按阶段引入，不提前为架构完整性加包。
4. 每完成一个阶段都跑 `flutter analyze` + `flutter test`。
5. 未验证的能力不写"已完成"，区分「已验证 / 代码已就绪 / 未验证」。
