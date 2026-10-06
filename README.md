# Toki

本地优先的 AI 日历 / 倒计时 / 提醒应用，Android 与 Windows 双端共用一套 Flutter 代码。

> 当前状态：**Phase 1（App Shell）已完成**。数据库、AI、通知尚未接入，页面上的数据是 mock 内容。

## 项目介绍

Toki 的目标是把「日历 + 倒计时 + 提醒 + 可自定义人设的 AI 助手」放在同一个本地应用里，
数据默认只存在本机，AI 通过结构化工具（Tool Calling）操作日历数据，而不是让模型直接改数据库。

## 功能

已实现（Phase 1）

- 三档响应式布局：手机底部导航 / 平板 NavigationRail / 桌面可折叠 Sidebar
- 五个一级页面：首页、日历、倒计时、AI 助手、设置
- 主题系统：`ThemeConfig` 模型 + Default / Light / Dark 三套预设 + 跟随系统 + 字号 / 圆角微调
- 玻璃拟态层与 `ThemeData` 解耦（`GlassStyle` / `GlassCard`）
- 中英双语（`zh` / `en`），默认跟随系统、系统语言不受支持时回退中文
- 倒计时统一节拍源（`CountdownController`），秒级只重建叶子组件
- 设置持久化（语言 / 主题 / 微调）写入 shared_preferences

计划中（尚未实现，按阶段推进）

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| Phase 0 | 环境 + 项目脚手架 | ✅ |
| Phase 1 | App Shell / 响应式 / 主题 / i18n | ✅ |
| Phase 2 | Drift + SQLite、Repository CRUD、迁移测试 | ⏳ |
| Phase 3 | 日历月视图增删改、周 / 日视图 | ⏳ |
| Phase 4 | 倒计时 CRUD、拖动排序、跨时区测试 | ⏳ |
| Phase 5 | Android 本地通知 / Windows Toast | ⏳ |
| Phase 6-8 | AI Provider、Persona、Tool Calling + 权限 | ⏳ |
| Phase 9-13 | Context、聊天自定义、主题编辑器、备份、质量优化 | ⏳ |

## 技术栈

| 用途 | 选型 |
| --- | --- |
| UI / 跨端 | Flutter 3.27.2 (stable) · Dart 3.6.1 |
| 状态管理 | flutter_riverpod 2.x |
| 路由 | go_router 14.x（`StatefulShellRoute.indexedStack`） |
| 轻量设置存储 | shared_preferences（仅应用级设置，见下） |
| 国际化 | flutter_localizations + intl（ARB → `lib/l10n/generated`） |

暂未引入（按阶段添加）：Drift、Dio、json_serializable / freezed、timezone、通知插件。

### 存储边界

`shared_preferences` 只保存**应用级轻量设置**：语言、当前主题 id、是否跟随系统、字号 / 圆角微调、首次启动标记。

领域数据（日程、倒计时、提醒、人设、会话）以及用户自建 / 导入导出的主题由 Phase 2 起的数据库负责，
两类数据互不迁移。

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
├── application/
│   ├── countdown/                # CountdownController（唯一 1Hz 节拍）
│   ├── theme/                    # 预设、ThemeConfig → ThemeData、主题控制器
│   └── settings/                 # 语言、首次启动
├── infrastructure/
│   ├── storage/                  # shared_preferences 封装
│   └── mock/                     # Phase 1 mock 数据（Phase 2 删除）
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

首次配置命令（换机器时参考）：

```powershell
$env:Path = "D:\Flutter\flutter\bin;" + $env:Path
flutter config --android-sdk D:\androidSDK
flutter config --jdk-dir="D:\Program Files\Java\jdk-17.0.12"
flutter doctor -v
```

## Windows 运行 / 构建

前置条件：**Visual Studio 2022 + "Desktop development with C++" 工作负载**（含 Windows 10/11 SDK）。

```powershell
flutter run -d windows
flutter build windows
```

> 本机当前**未安装** Visual Studio C++ 工作负载，因此 `flutter build windows` 会报
> `Unable to find suitable Visual Studio toolchain`。代码、工程与响应式桌面布局已就绪，
> 装好工作负载后即可直接运行验证。

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

## 数据库说明（规划）

Phase 2 引入 Drift + SQLite，建立 `CalendarEvent` / `Countdown` / `Reminder` / `AiPersona` / `AiProvider` /
`ChatSession` / `ChatMessage` / `ThemeConfig` 等表，并提供带 `schemaVersion` 的迁移与备份导入导出。

## 测试

```powershell
flutter analyze
flutter test
```

当前覆盖：倒计时拆分（跨天 / 跨月 / 跨年 / 已过去）、日历事件命中判定、倒计时节拍（单 Timer、多订阅、释放）、
主题解析与 `ThemeData` / 玻璃层职责分离、字号缩放、响应式断点（599/600/999/1000）、五个导航目的地可达、
语言跟随系统与回退中文、语言持久化、倒计时卡片秒级刷新。

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
安装 Visual Studio 2022 并勾选 "Desktop development with C++"（含 Windows SDK）后重试。

## 开发原则

1. 平台相关能力必须经过抽象层，业务层不直接调用 Android / Windows API。
2. AI 只能通过结构化工具修改数据，禁止"嘴上说创建成功"。
3. 依赖按阶段引入，不提前为架构完整性加包。
4. 每完成一个阶段都跑 `flutter analyze` + `flutter test`。
5. 未验证的能力不写"已完成"，区分「已验证 / 代码已就绪 / 未验证」。
