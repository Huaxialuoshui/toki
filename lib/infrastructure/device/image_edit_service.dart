import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'device_channel.dart';

/// 需要"分平台做事"的两处（改图 / 换图标）共用的平台判定。
///
/// 有了它，单测可以在 Windows 主机上模拟 Android，而不会真的去开系统画图。
enum DevicePlatform {
  android,
  windows,
  unsupported;

  static DevicePlatform get current {
    if (Platform.isAndroid) return DevicePlatform.android;
    if (Platform.isWindows) return DevicePlatform.windows;
    return DevicePlatform.unsupported;
  }
}

/// 一次「用系统图片编辑器改图」的结果。
class ImageEditOutcome {
  const ImageEditOutcome({
    this.path,
    this.changed = false,
    this.error,
  });

  /// 编辑后的图片路径（没有改动时等于原路径）。
  final String? path;

  /// 内容是否真的变了。
  final bool changed;

  /// 可读错误：没装编辑器 / 平台不支持 / 文件不存在等。
  final String? error;

  bool get ok => error == null;
}

/// 调用**系统自带**的图片编辑器改一张本机图片（规格：背景 / 头像 / 应用图标）。
///
/// * Android：FileProvider + `ACTION_EDIT`，交给相册 / 文件管理器自带的编辑功能；
/// * Windows：开系统画图（`mspaint`）编辑，退出后把结果另存为新文件。
///
/// 两个平台都会把"改完的图片"落到一个新路径上再返回，调用方只要把配置里的
/// 路径换掉即可——顺带避开了 Flutter 的图片缓存（同路径改内容不刷新）问题。
class ImageEditService {
  ImageEditService({DeviceChannel? channel, DevicePlatform? platform})
      : _channel = channel ?? DeviceChannel(),
        _platformOverride = platform;

  final DeviceChannel _channel;
  final DevicePlatform? _platformOverride;

  DevicePlatform get platform => _platformOverride ?? DevicePlatform.current;

  bool get isSupported => platform != DevicePlatform.unsupported;

  Future<ImageEditOutcome> edit(String path) async {
    final value = path.trim();
    if (value.isEmpty) {
      return const ImageEditOutcome(error: '这张图片没有本地文件，改不了');
    }
    if (!File(value).existsSync()) {
      return const ImageEditOutcome(error: '找不到这张图片');
    }

    if (platform == DevicePlatform.android) {
      try {
        final result = await _channel.editImage(value);
        return ImageEditOutcome(path: result.path, changed: result.changed);
      } on DeviceChannelException catch (error) {
        return ImageEditOutcome(error: error.message);
      }
    }
    if (platform == DevicePlatform.windows) {
      return _editOnWindows(value);
    }
    return const ImageEditOutcome(error: '当前平台不支持调用系统图片编辑器');
  }

  /// Windows：系统画图（Win11 也保留了 `mspaint` 这个名字）。
  Future<ImageEditOutcome> _editOnWindows(String path) async {
    final before = _fingerprint(File(path));
    Process? process;
    try {
      process = await Process.start('mspaint', <String>[path], runInShell: true);
    } on ProcessException {
      process = null;
    }
    if (process == null) {
      return const ImageEditOutcome(error: '没找到系统画图工具（mspaint）');
    }
    await process.exitCode;

    final file = File(path);
    if (!file.existsSync()) {
      return const ImageEditOutcome(error: '图片被移走了，找不到文件');
    }
    if (_fingerprint(file) == before) {
      return ImageEditOutcome(path: path, changed: false);
    }
    // 另存为一份新文件：既保留原图，也让 Flutter 不必和图片缓存较劲。
    try {
      final directory = await getApplicationSupportDirectory();
      final editedDir = Directory(p.join(directory.path, 'edited'));
      if (!editedDir.existsSync()) editedDir.createSync(recursive: true);
      final target = File(
        p.join(editedDir.path, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}'),
      );
      file.copySync(target.path);
      return ImageEditOutcome(path: target.path, changed: true);
    } on FileSystemException catch (error) {
      return ImageEditOutcome(error: '保存编辑结果失败：${error.message}');
    }
  }

  /// 文件指纹：大小 + 修改时间，用来判断"到底改没改"。
  String _fingerprint(File file) =>
      '${file.lengthSync()}:${file.lastModifiedSync().microsecondsSinceEpoch}';
}
