import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:sqlite3/open.dart';

/// 让 `flutter test`（跑在 Dart VM 上）能找到 sqlite3 动态库。
///
/// 背景：`sqlite3_flutter_libs` 只在 **App 构建** 时打包 sqlite3；
/// Dart VM 上的测试需要显式提供动态库。查找顺序：
///
/// 1. `.dart_tool/sqlite3.dll`（本函数会缓存一份，`flutter clean` 不会删它）
/// 2. Flutter 的 Windows 构建产物（`build/windows/x64/.../sqlite3.dll`）
/// 3. 系统 PATH 上的 `sqlite3.dll`
///
/// 因此第一次跑数据库测试前需要先执行一次 `flutter build windows`
/// （或直接跑一次 Windows 版应用）。
void ensureSqliteLibraryAvailable() {
  // 每个测试都会新建一个内存数据库（各自独立的 executor），
  // 因此关掉 drift 的"多次创建数据库类"提示噪音。
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  if (!Platform.isWindows) {
    // Linux / macOS 通常能找到系统 sqlite3；找不到时由 sqlite3 包自己报错。
    return;
  }

  final cached = File('${_dartToolPath()}${Platform.pathSeparator}sqlite3.dll');
  if (cached.existsSync()) {
    _use(cached.path);
    return;
  }

  for (final candidate in _buildOutputCandidates()) {
    if (candidate.existsSync()) {
      cached.parent.createSync(recursive: true);
      try {
        candidate.copySync(cached.path);
        _use(cached.path);
      } on FileSystemException {
        // 复制失败（例如权限问题）时直接用构建产物。
        _use(candidate.path);
      }
      return;
    }
  }

  // 最后尝试系统 PATH；找不到会由 sqlite3 包在首次查询时抛出明确错误。
  _use('sqlite3.dll');
}

void _use(String path) {
  open.overrideFor(
    OperatingSystem.windows,
    () => DynamicLibrary.open(path),
  );
}

String _dartToolPath() => '.dart_tool';

Iterable<File> _buildOutputCandidates() sync* {
  const configs = <String>['Release', 'Debug', 'Profile'];
  for (final config in configs) {
    yield File('build/windows/x64/runner/$config/sqlite3.dll');
    yield File(
      'build/windows/x64/plugins/sqlite3_flutter_libs/$config/sqlite3.dll',
    );
  }
}
