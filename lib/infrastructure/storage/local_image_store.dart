import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 把用户选中的图片搬进应用私有目录，返回新路径。
///
/// 相册 / 文件选择器给出来的是 **cache 目录**里的临时文件（Android 上形如
/// `/data/user/0/<包名>/cache/<uuid>/1000000123.png`），系统随时可以清掉，
/// 别的应用也未必长期读得到。背景图 / 头像 / 应用图标这些都是要长期用的，
/// 所以选完立刻复制一份到应用自己的目录 `images/` 下。
///
/// [directory] 只用给测试注入，正常调用不用传。
Future<String> persistPickedImage(
  String sourcePath, {
  String? name,
  Directory? directory,
}) async {
  final source = File(sourcePath);
  final root = directory ?? await getApplicationSupportDirectory();
  final target = Directory(p.join(root.path, 'images'));
  if (!target.existsSync()) target.createSync(recursive: true);

  final extension = p.extension(sourcePath);
  final fileName = (name == null || name.trim().isEmpty)
      ? '${DateTime.now().millisecondsSinceEpoch}$extension'
      : name.trim();
  final file = File(p.join(target.path, fileName));
  await source.copy(file.path);
  return file.path;
}
