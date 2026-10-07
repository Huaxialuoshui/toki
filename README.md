# Toki

本地优先的 AI 日历 / 倒计时 / 提醒应用，Android 与 Windows 双端共用一套 Flutter 代码。

> 当前状态：**Phase 0–13 全部完成**，并在其之上补齐了三轮能力。
> 第一轮：AI 多会话 / 消息级操作 / Markdown 渲染、聊天页切换服务商、重复日程与重复提醒、
> 自定义提醒提前量、日历分类管理、天气（Open-Meteo，免密钥）、AI 每日计划与总结、
> SyncService 抽象、主题区域配色，以及质量专项。
> 第二轮（2026-10-07）：**应用级自定义背景（纯色 / 渐变 / 图片）**、**图标风格（描边 / 实心）**、
> **天气 GPS 定位 + 历史位置 + 逐小时 / 多日预报**、**头像编辑器（emoji / 单字 / 图片 + 底色）**、
> **Android 桌面小组件（自定义皮肤 / 图标 / 背景图 + 常驻后台）**、思考内容（`reasoning_content`）
> 入库与回传。
> 第三轮（2026-10-07）：**自定义应用图标（用自己的图片）**、**调用系统自带的图片编辑器改图**
> （背景 / 头像 / 应用图标 / 小组件背景的图片都能改）。全部为本地能力，**不引入服务器**。

| 平台 | analyze | test | 构建 | 运行 |
| --- | --- | --- | --- | --- |
| Android | ✅ | ✅ 321/321 | ✅ `flutter build apk --debug` / `--release`（28.6 MB） | ✅ 模拟器实测（debug + **release**）：日程 / 倒计时增删改、拖拽排序、通知投递、闹钟跨进程存活、AI 流式聊天、人设 CRUD、AI 工具调用建日程、上下文注入、聊天外观、主题编辑器、备份导出与恢复、**小米 MiMo 真实 API**（对话 / 工具调用 / 远程拉取模型）、**天气真实接入**、**AI 每日计划生成**、**桌面小组件**（钉到桌面 + 随数据自动刷新；「常驻后台」开关为代码已配置、未点按验证）、**应用背景与图标风格**（见下）、**天气 GPS 定位**（取当前位置 → 存进历史位置 → 首页按坐标显示真实天气与逐小时 / 多日预报） |
| Windows | ✅ | ✅ 321/321 | ✅ `flutter build windows --release`（VS 2026 + C++ 桌面工作负载，`toki.exe`） | ⚠️ 构建产物已生成、单测全绿；**桌面鼠标交互、任务栏图标切换与系统 Toast 可见性还没人工点过**（自动化会抢占你正在使用的桌面，所以留给你空闲时确认） |

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
- **主题编辑器**：可视化调整主色 / 次要色 / 背景 / 卡片 / 文字、明暗、圆角、卡片透明度、背景模糊、
  阴影强度、字号、过渡动画；编辑期间**整个应用**实时跟随预览，可保存为用户主题 / 另存为新主题 /
  导出导入 JSON / 删除，用户主题存在数据库、当前主题 id 存在 shared_preferences
- **备份与恢复**：整库（10 张表）导出为一个带 `formatVersion` / `schemaVersion` 的 JSON 文件，
  API Key 默认脱敏；恢复时可「覆盖」或「合并」，格式不对或数据损坏只提示、不写坏现有数据
- **AI 会话与消息**：多会话（新建 / 切换 / 删除、首条消息自动起标题、最近的在最前）、
  单条消息操作（复制 / 编辑并重发 / 重新生成 / 删除）、聊天页直接切换服务商、
  助手回复按 Markdown 渲染（标题 / 列表 / 引用 / 代码块 + 一键复制）
- **重复日程与提醒**：日程支持每天 / 每周 / 每月 / 每年 + 可选结束日期，月 / 周 / 日视图与首页
  都会按次展开；提醒会按重复规则把未来 30 天内的每一次都排进系统通知（幂等、有上限）
- **提醒与分类**：提醒除预设外可自定义提前量（分钟 / 小时 / 天）；日历分类可在设置页增删改，
  删除分类会把事件摘成"无分类"而不是连带删除
- **天气**：Open-Meteo（**不需要 API Key**），设置里填城市即可，首页显示温度 / 状况 / 今日高低温，
  30 分钟缓存 + 失败回落旧数据；**支持 GPS 定位取当前位置**（Android 原生 `LocationManager`，
  不依赖 Google Play 服务），**自动保存历史位置**（去重置顶、最多 8 条、可切换 / 删除），
  首页天气卡点开有**逐小时（24h）+ 多日（5 天）预报**
- **AI 每日简报**：可分别开关「早间计划 / 晚间总结」，到点自动生成（每天一次），也能手动生成 /
  重新生成；结果按天存库，首页用 Markdown 展示
- **同步抽象**：`SyncService` 接口 + 仅本地实现（第一版不建服务器），设置页如实标注"仅本机"
- **主题区域配色**：导航栏 / 侧边栏 / 日历事件 / 倒计时可以分别指定颜色（留空则跟随主题）
- **应用级自定义背景**：设置 → 应用背景，可换纯色 / 渐变 / 本地图片（相册或路径），
  带透明度 / 模糊 / 暗色遮罩；三档布局的 Scaffold 都是透明壳，所以背景铺满整个应用，
  和「聊天页背景」互不影响
- **图标风格**：设置 → 图标风格，描边 / 实心两档，导航栏、侧边栏与所有区块标题同步切换
- **头像编辑器**：我的人设头像不再是一个输入框——emoji 面板（56 个）/ 单字（最多 2 字）/
  图片（相册选择或填路径 / URL）三种形态 + 底色色板，用户头像与人设头像共用同一套编辑器
- **Android 桌面小组件**：自定义皮肤（纯色 / 渐变 / 图片）、图标风格（描边 / 实心）、圆角、
  文字色与强调色、显示倒计时 / 最近日程；数据变化自动刷新，另有「立即刷新」与「添加到桌面」；
  可选**常驻后台**（前台服务 + 电池优化白名单）以避免被系统回收
- **自定义应用图标**：用自己的图片换图标——Android 会换掉「最近任务」里的图标，并生成一个
  **带这张图的桌面快捷方式**（系统弹一次确认）；Windows 换窗口 / 任务栏图标（exe 自身图标是
  打包资源，需要重新构建）。设置页有预览、应用、恢复默认
- **调用系统图片编辑器**：背景 / 头像 / 应用图标 / 小组件背景，凡是选了本地图片的地方都有
  「用系统工具编辑」。Android 走 `ACTION_EDIT`（相册、文件管理器、Google Photos 的编辑功能），
  Windows 打开系统画图；改完自动换上新图（编辑结果另存为新文件，避开图片缓存）

阶段进度

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
| Phase 11 | 主题编辑器：可视化调色 / 保存为用户主题 / JSON 导入导出 | ✅ |
| Phase 12 | 备份与恢复：整库 JSON 导出 / 覆盖或合并导入 / 版本校验 | ✅ |
| Phase 13 | 质量优化：Timer / 订阅释放、数据库开关、通知幂等、超时与错误映射、跨年与时区 | ✅ |
| 补充一轮 | AI 多会话 / 消息操作 / Markdown、切换服务商、重复日程与提醒、自定义提前量、分类管理、天气、每日简报、SyncService、区域配色 | ✅ |
| 补充二轮 | 应用级自定义背景（含背景图片）+ 图标风格、天气 GPS 定位 / 历史位置 / 逐小时与多日预报、头像编辑器、Android 桌面小组件（皮肤 / 图标 / 背景图 + 常驻后台）、思考内容入库与回传 | ✅ |
| 补充三轮 | 自定义应用图标（自己的图片 → 最近任务图标 + 桌面快捷方式；Windows 窗口 / 任务栏图标）、调用系统图片编辑器改背景 / 头像 / 图标图片、选来的图片统一搬进应用私有目录 | ✅ |

目前**仍未做**的（如实列出，避免"看起来全做完了"的错觉）：

* WebDAV / 自建服务器 / 云同步——只有 `SyncService` 接口，实现是"仅本地"；
* AI 音乐 / 语音 / 图片识别等规格之外的能力；
* 应用背景 / 聊天背景只支持「本地路径 + URL」，没有内置图片素材库与裁剪；
* Android 的**桌面应用图标本身**改不了（那是启动器的资源）：能改的是「最近任务图标」和一个
  带自定义图标的**桌面快捷方式**；想连桌面图标一起换，需要打包时换 `ic_launcher`；
* 「用系统工具编辑」依赖设备上装了编辑器：Google Photos 这类编辑器是**异步保存**的，
  目前能在设备上验证到"打开编辑器 + 无改动时如实提示"，"改动后自动收回到应用"这一步
  在模拟器上没跑通（环境里 SystemUI 反复无响应），代码里已按"回调后最多重读 4 次"处理；
* 小组件的刷新精度受系统限制（`AlarmManager` 最快 15 分钟一次，秒级跳动还是要在应用内看）；
* Windows 端的鼠标交互、任务栏图标切换与系统 Toast 可见性仍未人工确认（构建与单测是通过的）。

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

`shared_preferences` 只保存**应用级轻量设置**：语言、当前主题 id、是否跟随系统、字号 / 圆角微调、
首次启动标记、聊天外观、**应用背景与图标风格**、天气缓存与历史位置、小组件配置、已排期通知 id。
（外加 **`settings.appIcon`**：自定义应用图标用的图片路径。）

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
│   ├── backup/                   # 整库读出 / 写回（BackupStore + 备份专用 ValueSerializer）
│   ├── repositories/             # Drift 实现 + 行↔实体映射 + Provider 装配
│   └── demo/demo_seed.dart       # debug 构建的示例数据
├── application/
│   ├── countdown/                # CountdownController（唯一 1Hz 节拍）
│   ├── calendar/                 # 数据库 StreamProvider + 写操作（CalendarActions）
│   ├── ai/                       # 人设 / 服务商 Provider + ChatController（流式聊天）
│   ├── notification/             # ReminderScheduler：提醒 → 系统通知
│   ├── backup/                   # 备份 JSON 编解码、版本校验、恢复策略
│   ├── theme/                    # 预设、ThemeConfig → ThemeData、主题控制器（含编辑器实时预览草稿）
│   └── settings/                 # 语言、首次启动、启动初始化
├── infrastructure/
│   ├── database/                 # Drift 表定义、AppDatabase、连接、转换器
│   ├── ai/                       # OpenAI Compatible 实现（Dio + SSE）
│   ├── backup/                   # 备份文件目录解析与读写（BackupFileStore）
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

## 打包安装包（双端）

### 一键打包：`package.bat`（推荐）

双击仓库根目录的 `package.bat`，或者在终端里：

```bat
package.bat                 :: APK + Windows 免安装包 + Windows 安装包
package.bat apk             :: 只打 Android
package.bat windows         :: 只打 Windows
package.bat check           :: 打之前先跑 flutter analyze + flutter test
package.bat check nopause   :: 组合使用；nopause = 结束不等待按键（适合脚本/CI）
```

它做的事：找 Flutter（PATH 或 `FLUTTER_ROOT` 或 `D:\Flutter\flutter`）→ 读 `pubspec.yaml` 里的版本号
→ `flutter pub get` → 打 APK → 打 Windows release → 复制/压缩 → 生成安装包 → 打印带体积的产物清单。
任一步失败会**停下来并提示常见原因**（签名缺失、没装 VS C++ 工作负载、网络问题），不会产出半个包。

实现上：`package.bat` 只是一层**纯 ASCII 启动器**（避免中文/代码页把批处理解析搞崩），
真正的逻辑在 `tool/package.ps1`。全过程**实时打屏 + 同时写进 `package.log`**，
结束后窗口会停在「PACKAGING DONE / PACKAGING FAILED」那一屏（不想停就加 `nopause`）。

> 双击没反应 / 窗口一闪而过？先看同目录的 `package.log`（它一定会被写出来，能看到卡在哪一步）；
> 也可以打开 cmd 手动跑 `cd /d <项目目录> && package.bat`，这样报错会留在窗口里。
> 想直接跑核心脚本：`powershell -ExecutionPolicy Bypass -File tool\package.ps1`。

产物（`dist/` **不进版本库**，已在 `.gitignore` 排除）：

| 平台 | 文件 | 说明 |
| --- | --- | --- |
| Android | `Toki-<版本>-android.apk` | 用 `android/toki-release.jks` 正式签名；手机直接安装（需允许"未知来源"） |
| Windows（免安装） | `Toki-<版本>-windows-x64/` 与 `Toki-<版本>-windows-x64.zip` | 解压后运行 `toki.exe`。**必须整个目录一起解压**，只拷 exe 会缺 DLL 与 `data\` |
| Windows（安装包） | `Toki-<版本>-windows-x64-setup.exe` | 单文件安装程序：解压到安装目录 + 桌面/开始菜单快捷方式 + 「设置 → 应用」里的卸载项 |

### Windows 安装包说明

安装包**不需要 Inno Setup / NSIS 等第三方工具**：源码是 `tool/installer/setup.cs.in`，
`package.bat` 用系统自带的 .NET Framework 编译器（`csc.exe`）把 release 目录压进去编译成一个 exe。

* 默认装到 `%LOCALAPPDATA%\Programs\Toki`（**不需要管理员权限**）；装的时候可以改路径；
* 会创建桌面与开始菜单快捷方式（可关），并写一条 HKCU 卸载信息（出现在「设置 → 应用 → 已安装的应用」）；
* 升级安装会先清掉旧程序文件；**用户数据不在安装目录**（数据库在 `%APPDATA%\com.toki\toki`，
  设置在那边的 shared_preferences 里），所以升级不会丢数据；
* 卸载：开始菜单 /「设置 → 应用」里点卸载，或直接跑安装目录里的 `uninstall.exe`
  （会把快捷方式、注册表项和整个安装目录一起清掉）；
* 命令行参数（适合自动化）：

```bat
Toki-0.1.0-windows-x64-setup.exe /silent                        :: 静默装到默认目录
Toki-0.1.0-windows-x64-setup.exe /silent /dir=D:\Apps\Toki      :: 静默装到指定目录
Toki-0.1.0-windows-x64-setup.exe /silent /noshortcuts /noregistry :: 不建快捷方式、不写卸载项
Toki-0.1.0-windows-x64-setup.exe /uninstall /silent             :: 静默卸载
```

### 手工打包（不想用脚本时）

```powershell
# Android：正式签名 APK（28 MB 左右）
flutter build apk --release
# 产物：build\app\outputs\flutter-apk\app-release.apk

# Windows：release 可执行目录（约 32 MB，压缩后 14 MB）
flutter build windows --release
# 产物：build\windows\x64\runner\Release\（toki.exe + DLL + data\）
```

签名与注意事项：

* 签名配置在 `android/key.properties`（**不进版本库**），密钥库是 `android/toki-release.jks`。
  **这两个文件要自己备份**——丢了就无法用同一个签名更新应用，只能卸载重装。
* 换了签名后覆盖安装会失败（`INSTALL_FAILED_UPDATE_INCOMPATIBLE`），需要先卸载旧版；
  `pm uninstall -k` 想保留数据也不行，安卓会拦住签名不一致的安装。
* Windows 的 exe **没有代码签名**，首次运行可能被 SmartScreen 拦一下（"更多信息 → 仍要运行"）。
* release 包不会写入示例数据，装完是空库，从零开始。

## AI 配置 / Provider 配置

Phase 6 起提供「OpenAI Compatible」Provider 配置（Base URL / API Key / Model / Temperature / Max Tokens / 流式开关），
Phase 7 起提供人设管理，Phase 8 起提供工具调用与工具权限。API Key 只保存在本机、不写日志、不进 Git。
模型字段**不需要手打**：向 `GET {baseUrl}/models` 拉取列表后点选（见下文「配置 AI 服务商」）。

## 数据库说明

Drift + SQLite，`schemaVersion = 6`，共 10 张表：

| 表 | 说明 |
| --- | --- |
| `calendar_categories` | 日历分类（颜色 / 图标 / 排序） |
| `calendar_events` | 日程（时间、全天、地点、分类、颜色、重复规则 + 结束日期、提前提醒） |
| `countdowns` | 倒计时（目标时间、置顶、显示样式、拖动排序位、卡片背景色） |
| `reminders` | 提醒（关联日程、触发时间、重复规则、启用开关） |
| `ai_personas` | AI 人设（性格、语气、称呼、系统提示词、可用工具 JSON、温度、头像底色） |
| `ai_providers` | OpenAI Compatible 服务商（Base URL / 模型 / 温度 / 最大 token / 流式 / 默认标记 / API Key） |
| `chat_sessions` | 会话（关联人设、可指定服务商） |
| `chat_messages` | 消息（role、内容、工具名 / 参数 / 结果、思考内容 `reasoning_content`） |
| `theme_configs` | 用户自建 / 导入的主题（颜色、圆角、卡片透明度、模糊、阴影强度、字号、动画、区域配色） |
| `daily_digests` | AI 每日计划 / 总结（`kind` + `dayKey`，一天一条） |

迁移历史：

| 版本 | 变更 |
| --- | --- |
| v1 → v2 | `chat_messages.tool_call_id`（Phase 8：工具调用结果与请求配对） |
| v2 → v3 | `theme_configs.shadow_strength`（Phase 11：主题阴影强度） |
| v3 → v4 | `chat_sessions.provider_id`、`countdowns.background_color`、`calendar_events.repeat_until`、新增 `daily_digests` 表 |
| v4 → v5 | `theme_configs` 的区域配色列（导航栏 / 侧边栏 / 日历 / 倒计时） |
| v5 → v6 | `chat_messages.reasoning_content`（思考模型的思考片段）、`ai_personas.avatar_color`（头像底色） |

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
* 已知范围限制：视图是"月网格 + 议程式周 / 日列表"，真正的按小时排布的"时间网格"留到后续按需再做。
  （分类管理与重复日程（每天 / 每周 / 每月 / 每年 + 结束日期）已在补充轮次开放，见上文「功能」与
  设置页的「日历分类」区块。）

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

**模型不用手打**：模型字段默认只读，点它（或右侧的列表图标）会向服务商请求
`GET {baseUrl}/models`，把返回的模型列出来点选；带关键字筛选。拿不到列表时可以点
「手动输入」切回手动填写（例如服务商没实现 `/models`）。

「测试连接」会用当前表单发一条最小请求（非流式），成功时把模型回复的前 40 字显示出来，
失败时显示可读原因（HTTP 状态 + 提示，例如 401 → Key 可能无效、404 → 检查 Base URL）。

「快速填充」内置预设：DeepSeek / **小米 MiMo** / OpenAI / Qwen / Moonshot / 智谱 / Ollama。
小米 MiMo 走 OpenAI 兼容协议，Base URL 必须带 `/v1`（`https://api.xiaomimimo.com/v1`），
模型填 `mimo-v2.6-pro`。

> **思考模型的行为**：MiMo 这类 reasoning 模型在流式返回时会先发很多
> `reasoning_content` 增量、之后才发 `content`，所以点击发送后会先有一段几秒的"空档"才逐字出字，
> 这是正常的。思考片段会**入库并随历史一起回传**（多轮对话里模型能看到自己上一步的推理，
> 工具调用的连续对话更稳），但界面上默认**折叠**显示——需要时点气泡里的「思考内容」才展开，
> 不打断阅读。

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
| 头像 | 点「更换头像」开编辑器：emoji 面板（56 个）/ 单字（最多 2 字）/ 图片（相册选择或路径、`http(s)` URL）+ 底色色板；图片加载失败自动回落到文字头像 |
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
用户自建主题（配色、玻璃参数等）存在数据库的 `theme_configs` 表，见下一节。
图片加载失败会自动回落到纯色背景，不会出现裂图。

### 应用级外观（背景 / 图标 / 头像）

设置页「应用背景」与「图标风格」两个区块，加上聊天外观里的头像编辑器：

| 项目 | 支持 |
| --- | --- |
| 应用背景 | 纯色 / 渐变（两色）/ 图片（相册选择，也能直接填路径或 `http(s)` URL），外加图片透明度、背景模糊（0-30）、暗色遮罩 |
| 图标风格 | 描边 / 实心两档；导航栏、侧边栏、区块标题同步切换 |
| 头像 | 用户头像与人设头像共用同一套编辑器：emoji 面板 / 单字 / 图片 + 底色 |

**应用背景 ≠ 聊天背景**：应用背景铺在所有页面之下（手机 / 平板 / 桌面三档布局的 `Scaffold`
都设成 `Colors.transparent`，背景才能透上来），聊天页背景只作用于聊天消息区。
两者都存在 shared_preferences，互不影响；没配过应用背景时沿用当前主题的背景色，
所以"没设置"与"设置过"之间的观感是连贯的。

### 主题编辑器（Phase 11）

设置 → 外观 →「新建主题」或「编辑当前主题」进入编辑器；**打开期间整个应用就是预览**（底部导航、
侧边栏、卡片、按钮会立刻跟着草稿变色），退出编辑器则撤销预览、回到已保存的主题。

| 项目 | 支持 |
| --- | --- |
| 颜色 | 主色 / 次要色 / 背景 / 卡片 / 文字，各 8 色板 + 黑 / 白 |
| 明暗 | 浅色 / 深色（决定 `ThemeData.brightness` 与跟随系统时的落点） |
| 形状 | 圆角（0-32）、阴影强度（0-1，0 为完全扁平） |
| 玻璃 | 卡片透明度（0.3-1）、背景模糊（0-30）——这两个参数**只走 `GlassStyle`，不进 `ThemeData`** |
| 文字 / 动效 | 字号缩放（0.85-1.4）、过渡动画开关 |
| 保存 | 「保存主题」（新建用户主题时会问名字）/「另存为新主题」/「重置」回到默认预设 |
| 导入导出 | 导出为 JSON（写入应用文档目录 + 复制到剪贴板）、从剪贴板或手动粘贴的 JSON 导入；格式不对只提示、不写库 |
| 删除 | 编辑器内的「删除」或设置页「我的主题」列表里的垃圾桶（二次确认）；删掉当前主题会回落到默认预设 |

JSON 结构（`schemaVersion: 1`）就是 `ThemeConfig` 的扁平化：`name` / `brightness` /
`primaryColor` 等（颜色是 ARGB int），缺字段按默认值补齐，因此手写一小段 JSON 也能导入。

### 备份与恢复（Phase 12）

设置 → 备份与恢复。

| 操作 | 说明 |
| --- | --- |
| 导出备份 | 10 张表 → 一个 JSON 文件，写到「备份目录」并同时复制到剪贴板（手机端可以直接粘到笔记 / 电脑上取走） |
| 导出时包含 API Key | **默认关闭**；打开后 `ai_providers.api_key` 会以明文写进文件，请自行保管 |
| 从文件恢复 | 列出备份目录里的 `toki-backup-*.json`（时间倒序），挑一个 → 看摘要 → 选「覆盖」或「合并」 |
| 粘贴 JSON | 从剪贴板预填或手动粘贴一份备份 JSON，同样先看摘要再恢复 |
| 覆盖 / 合并 | 覆盖＝先清空本机数据再整体写入；合并＝保留本机数据，同 id 覆盖、新 id 追加 |

备份目录：

* Android：`/storage/emulated/0/Android/data/com.toki.toki/files`（应用专属但可用 USB 直接拷出）
* Windows：系统「文档」目录

JSON 结构（`formatVersion: 1`）：

```json
{
  "format": "toki-backup",
  "formatVersion": 1,
  "schemaVersion": 6,
  "exportedAt": "2026-10-06T15:15:57.000",
  "appVersion": "0.1.0+1",
  "includesApiKeys": false,
  "counts": { "calendar_events": 9, "countdowns": 4, "...": 0 },
  "tables": { "calendar_events": [ { "id": "...", "startTime": "2026-10-06T09:00:00" } ] }
}
```

安全与健壮性约定：

* `format` 不是 `toki-backup`、`formatVersion` / `schemaVersion` 比当前应用新、JSON 不合法、
  某一行解析失败 → 一律**拒绝导入**并给出可读原因，不动现有数据；
* 写入放在一个事务里，中途失败会整体回滚（有专门的回归测试）；
* 恢复不会改动 shared_preferences 里的语言 / 当前主题 id 等应用级设置。

> 实现说明：`data/backup/backup_store.dart` 用的是 drift 数据类的 `toJson()` / `fromJson()`，
> 但配了一个自定义 `ValueSerializer`——drift 默认序列化器在 JSON 往返后无法还原
> `List<String>`（`ai_personas.enabled_tools`），直接用会在恢复时报类型转换错误。

## 应用图标与图片编辑说明

设置 → 「应用图标」。选一张自己的图片，可以先「用系统工具编辑」改好，再「应用到系统」。

| 平台 | 能做到什么 |
| --- | --- |
| Android | ① 换掉**最近任务**里的图标（`ActivityManager.TaskDescription`，重启后由原生自动恢复）；② 用 `requestPinShortcut` + `Icon.createWithAdaptiveBitmap` 生成**带这张图的桌面快捷方式**（系统弹一次确认，点「添加」）。桌面上的 `ic_launcher` 是打包资源，运行时改不了——想换那个请替换 `android/app/src/main/res/mipmap-*/ic_launcher.png` 重新打包 |
| Windows | 图片 → 256px PNG → `.ico`（ICO 里直接放 PNG，Vista+ 支持）→ `LoadImageW` + `WM_SETICON` 换掉窗口标题栏与任务栏图标；`toki.exe` 自身的图标是编译期资源，要用 `windows/runner/resources/app_icon.ico` 重新构建 |
| 其它 | 设置页会如实提示"当前平台不支持" |

「用系统工具编辑」出现在所有选了本地图片的地方（应用背景 / 聊天背景 / 头像 / 应用图标 /
小组件背景）：

| 入口 | 位置 |
| --- | --- |
| 我的头像 | ① 聊天页右上角「头像」菜单 → 我的头像（直接打开头像编辑器）；② 设置 → 聊天外观 → 我的头像 |
| 助手头像 | ① 聊天页「头像」菜单 → 助手头像（写回人设）；② 设置 → AI 人设 → 编辑人设 → 更换头像 |
| 背景图片 | 设置 → 应用背景 / 聊天外观 / 桌面小组件，选到「图片」那一档就有 |
| 应用图标 | 设置 → 应用图标 |

头像编辑器里的「用系统工具编辑」在**图片**那一档（表情 / 文字档没有本地文件可改，按钮会置灰）。
背景与应用图标的按钮始终可见，没选图时是灰的。

* Android：`FileProvider` + `ACTION_EDIT`。**先把图片插一份到相册**（`Pictures/Toki/`）再共享 —
  不这样做的话，Google Photos 这类编辑器会拒绝编辑应用私有目录里的文件（实测提示
  `Editing is not supported for this image`）。改完把内容读回、另存成应用私有目录里的新文件，
  再把相册里那份临时副本删掉；
* Windows：直接开系统画图（`mspaint`），退出后把结果另存为新文件；
* 两个平台都**一定返回一个新路径**，顺带绕开了 Flutter 的图片缓存（同一个路径换了内容不会刷新）；
* 拿不到编辑器 / 图片不存在 / 平台不支持，都会给可读提示，不会静默失败；
* 相册选来的图片（`image_picker` 给的是 cache 里的临时文件）会先复制进应用私有目录
  `images/`，避免被系统清理后图片变成裂图。

## 桌面小组件说明（Android）

设置 → 桌面小组件。「添加到桌面」会走系统的请求-固定流程（`requestPinAppWidget`），
不需要自己去桌面长按添加。小组件是 3×2 的可缩放卡片（最小 180×110dp）。

| 项目 | 支持 |
| --- | --- |
| 皮肤 | 纯色 / 渐变（两色）/ 图片（相册选择，拷进应用私有目录后原生读） |
| 图标 | 描边 / 实心两档（`ic_widget_timer_*` / `ic_widget_refresh_*` 视矢量资源） |
| 形状 / 文字 | 圆角（0-48）、文字色、强调色、半透明开关 |
| 内容 | 显示最近的倒计时、显示下一个日程（都可以单独关） |
| 后台 | 「常驻后台运行」开关 + 电池优化白名单入口 |

实现要点：

* 数据流是**单向**的：Dart 侧把「最近的倒计时 + 下一个日程 + 皮肤配置」写成
  `files/widget_state.json` 并通知原生（`toki/device` 通道），原生
  `TokiWidgetRenderer` 再把它画成 `RemoteViews`。日程 / 倒计时 / 外观一变就自动推送
  （400ms 防抖），不需要手动刷新；设置页也有「立即刷新」。
* 渐变背景在 `RemoteViews` 里没法直接画，所以渲染器先把背景（含圆角）画成一张 Bitmap
  再塞进 `ImageView`；图片背景同理。
* 刷新节拍：`AppWidgetProvider` 用 `AlarmManager.setInexactRepeating` 每 15 分钟自刷新一次
  （系统在低电模式下可能推迟，这是 Android 的限制），并注册了
  `TokiBootReceiver` 在开机 / 应用更新后重新登记。
* **防止被杀后台**（可选）：打开后启动一个 `IMPORTANCE_MIN` 的前台服务，通知静音折叠；
  Android 强制要求前台服务必须挂一条通知，这是系统约束、不是应用行为。服务本身不常驻轮询，
  只负责让进程与刷新逻辑不被优先回收。另外提供「忽略电池优化」白名单入口，
  这是系统设置页的跳转，授权与否由你决定。
* 权限：`FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_DATA_SYNC` /
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` / `RECEIVE_BOOT_COMPLETED`，
  以及天气定位用的 `ACCESS_COARSE_LOCATION` / `ACCESS_FINE_LOCATION`。

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
当前 327 个测试，覆盖：
* **调试工具**：`tool/seed_device_reminder.dart` 可以往设备数据库里写一条"马上要触发"的提醒，
  便于手工验证"关掉应用后仍能提醒"。

## 测试

```powershell
flutter analyze
flutter test
```

当前 321 个测试，覆盖：

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
  * 流式请求的错误体也要能读出来（`response.data` 是 `ResponseBody` 时不能只打印 `Instance of`）
* 模型列表：`/models` 地址规范化（含误填 `/chat/completions` 的兜底）、解析 `data[].id` /
  `models[].name` / 纯数组三种写法并排序去重、401 时给出可读原因且不泄漏 Key
* 界面·服务商：模型字段默认只读、拉取后点选写回表单、筛选、保存进库、获取失败可重试或切手动输入、
  Base URL 没填时不去请求
* Markdown：块级解析（标题 / 段落 / 列表 / 引用 / 分隔线 / 代码块 / 未闭合代码块）、行内 span
  （粗体 / 斜体 / 行内代码 / 删除线 / 链接）、组件渲染不残留标记符号
* 多会话：自动建默认会话、新建后互相隔离、列表按最近更新排序、首条消息自动起标题（超长截断）、
  删除会话连带消息、删光后自动重建、当前会话 id 持久化
* 消息操作：删除单条、重新生成（连同其后消息一起重跑）、编辑并重发、空内容不生效
* 重复日程：规则解析（含 `FREQ=` 兼容）、每天 / 每周 / 每月 / 每年展开、31 号落到月末、
  闰年 2/29、重复截止、跨年、很久以前的每日重复快速跳过、跨天事件边界
* 重复提醒：按次排期到未来 30 天、重复截止后停止、独立重复提醒、取消后清理排期、
  反复同步幂等（id 稳定）、单条上限 30 条
* 天气：WMO 编码归类、JSON 往返、缓存新鲜度、先查城市再查天气、城市不存在 / HTTP 失败 / 空城市名的错误
* 天气·位置：历史位置去重置顶、上限 8 条、删除、GPS 定位成功记成「当前位置」、
  没有权限 / 拿不到坐标 / 原生报错都转成可读错误、老版本单城市设置迁移
* 天气·预报：逐小时（24h）与多日（5 天）解析、可注入的"现在"（测试可确定化）
* 应用外观：没配过应用背景时沿用主题背景色、保存过的应用背景启动即生效、
  设置页切换背景立刻生效并写入 shared_preferences、切换图标风格后导航图标变实心并持久化
* 头像编辑器：表情 / 文字 / 图片三档（图片档有相册按钮 + 路径输入）、选表情 + 底色后保存写入设置、
  一键移除已有头像
* 思考内容：`reasoning_content` 的流式解析与回传（`toJson` 有值才带）、思考片段折叠展示
* 桌面小组件：`WidgetConfig` JSON 往返、背景写文件 + 通知原生、状态文件路径与测试用目录注入
* 应用图标：图片路径交给原生并带回「最近任务 + 桌面快捷方式」结果、图片不存在 / 空路径不调原生、
  平台不支持时给可读错误、恢复默认会通知原生清掉自定义图标、设置页无图时「应用到系统」禁用
* 图片编辑：平台判定（测出来是 Android 还是 Windows）、路径为空 / 文件不存在提前报错、
  编辑器改过返回新路径、没改动保持原路径、没有编辑器时把原生原因透给用户
* Windows 图标：ICO 容器结构（头部 / 条目 / PNG 偏移，256 尺寸写 0）、非 256 尺寸写真实像素
* 图片落盘：相册选来的图复制进 `images/` 且内容一致、可指定文件名、原文件不被搬走
* 编辑入口：我的头像 / 应用背景 / 聊天背景 / 应用图标 / 人设头像 / 聊天页「头像」菜单
  都能找到「用系统工具编辑」（没有本地图片时按钮置灰）；聊天页头像菜单能直接改
  我的头像与助手头像，并且打开的就是设置页那套编辑器
* 每日简报：默认关闭不请求、开关打开才生成、同一天只生成一次、手动重新生成覆盖不新增、
  没配服务商时报错且不写半条数据、空库也能生成
* 质量：倒计时 Timer 随订阅释放、聊天流中途释放容器会取消订阅、数据库关闭重开数据仍在、
  反复切换五个页面不残留 Timer、AI 超时 / 证书 / 取消 / 限流 / 非 JSON 的可读错误且不泄漏 Key
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
* 主题编辑器：草稿驱动全局主题并在清空后回到已保存主题、选中数据库里的用户主题后解析为该主题、
  改色实时生效 + 关闭撤销、保存写库并写入 shared_preferences、另存为新增第二条、
  导入合法 JSON 落库 / 非法 JSON 只提示不写库、删除用户主题后回落到默认预设、
  `shadow_strength` 迁移到 v3 后列存在且能往返
* 备份与恢复：导出落盘与元信息、API Key 默认脱敏 / 开关后才带上、覆盖恢复后内容一致、
  合并恢复（同 id 覆盖 + 新 id 追加 + 其余保留）、非 JSON / 非 Toki 备份 / 更高格式或结构版本
  被拒绝、损坏行动整次恢复失败且事务回滚、设置页导出落盘 + 复制剪贴板 + 粘贴恢复

> 数据库测试跑在 Dart VM 上，需要 sqlite3 动态库：第一次运行前先执行一次 `flutter build windows`
> （测试会自动把 `sqlite3.dll` 缓存到 `.dart_tool/`，`flutter clean` 不会删）。

## 常见问题

**release 包联网失败（AI / 天气）**
Flutter 模板只在 `android/app/src/debug` 与 `profile` 的清单里声明 `INTERNET` 权限，
**release 包默认没有网络权限**。本项目已在 `android/app/src/main/AndroidManifest.xml` 里显式声明
`INTERNET` / `ACCESS_NETWORK_STATE`，所以 AI 与天气在 release 下也能用；
如果你以后换模板重建工程，记得补这两行。

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
