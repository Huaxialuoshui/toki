import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toki/infrastructure/storage/local_image_store.dart';

/// 选出来的图片要搬进应用私有目录（相册给的是 cache 里的临时文件）。
void main() {
  late Directory root;
  late File picked;

  setUp(() {
    root = Directory.systemTemp.createTempSync('toki_images_test');
    picked = File('${root.path}/cache_pick.png')..writeAsBytesSync(<int>[1, 2, 3]);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('复制到 images/ 下并返回新路径，内容一致', () async {
    final saved = await persistPickedImage(picked.path, directory: root);

    expect(saved, contains('images'));
    expect(saved, endsWith('.png'));
    expect(File(saved).existsSync(), isTrue);
    expect(File(saved).readAsBytesSync(), picked.readAsBytesSync());
    // 原文件还在（没被搬走，只是复制）
    expect(picked.existsSync(), isTrue);
  });

  test('可以指定文件名，重复保存不会互相覆盖', () async {
    final first = await persistPickedImage(
      picked.path,
      name: 'app_icon.png',
      directory: root,
    );
    final second = await persistPickedImage(
      picked.path,
      name: 'other.png',
      directory: root,
    );

    expect(first, endsWith('app_icon.png'));
    expect(second, endsWith('other.png'));
    expect(first == second, isFalse);
  });
}
