# Toki

本地优先的 AI 日历 / 倒计时 / 提醒应用，Android 与 Windows 双端共用一套 Flutter 代码。

> 当前状态：**Phase 2（本地数据库）已完成，Android 与 Windows 双端均已构建并实际运行验证**。
> 日程 / 倒计时 / 提醒已经存在本机 SQLite 里；AI、通知尚未接入。

平台验证状态（2026-10-06）：

| 平台 | analyze | test | 构建 | 运行 |
| --- | --- | --- | --- | --- |
| Android | ✅ | ✅ 57/57 | ✅ `flutter build apk --debug` | ✅ `flutter run -d android`（模拟器 toki_api34，数据库落盘） |
| Windows | ✅ | ✅ 57/57 | ✅ `flutter build windows` | ✅ `flutter run -d windows`（数据库落盘） |

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

计划中（尚未实现，按阶段推进）

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| Phase 0 | 环境 + 项目脚手架 | ✅ |
| Phase 1 | App Shell / 响应式 / 主题 / i18n | ✅ |
| Phase 2 | Drift + SQLite、Repository CRUD、迁移测试 | ✅ |
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
│   ├── calendar/ ai/             # 页面用的数据库 StreamProvider
│   ├── theme/                    # 预设、ThemeConfig → ThemeData、主题控制器
│   └── settings/                 # 语言、首次启动、启动初始化
├── infrastructure/
│   ├── database/                 # Drift 表定义、AppDatabase、连接、转换器
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

## 数据库说明（规划）

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

## 测试

```powershell
flutter analyze
flutter test
```

当前 57 个测试，覆盖：

* 领域：倒计时拆分（跨天 / 跨月 / 跨年 / 已过去）、日历事件命中判定
* 应用层：倒计时节拍（单 Timer、多订阅、释放）、主题解析、`ThemeData` 与玻璃层职责分离、字号缩放
* 数据层：8 个仓储的 CRUD / 排序 / 置顶 / 重排 / 默认服务商 / 外键级联、UTC 往返、示例数据幂等、迁移快照校验
* 界面：响应式断点（599/600/999/1000）、五个导航目的地可达、语言跟随系统与回退中文、语言持久化、
  倒计时卡片秒级刷新、空数据库的空状态

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
