import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 把一张 PNG 包成 `.ico` 容器。
///
/// Vista 之后的 ICO 允许条目里直接放 PNG（不用 BMP 的 AND/XOR 掩码），
/// 所以这里只需要写 6 字节的 ICONDIR + 16 字节的 ICONDIRENTRY + PNG 数据。
/// 纯函数，方便单测；真正调 Win32 的部分在 [WindowsAppIcon] 里。
Uint8List buildIcoFromPng(Uint8List png, {int size = 256}) {
  const int headerSize = 6;
  const int entrySize = 16;
  const int imageOffset = headerSize + entrySize;
  final data = ByteData(imageOffset + png.length);

  // ICONDIR
  data.setUint16(0, 0, Endian.little); // reserved
  data.setUint16(2, 1, Endian.little); // type = icon
  data.setUint16(4, 1, Endian.little); // 只放一个尺寸

  // ICONDIRENTRY（宽度/高度 0 表示 256）
  final dimension = size >= 256 ? 0 : size;
  data.setUint8(6, dimension);
  data.setUint8(7, dimension);
  data.setUint8(8, 0); // 调色板颜色数（真彩色写 0）
  data.setUint8(9, 0); // reserved
  data.setUint16(10, 1, Endian.little); // color planes
  data.setUint16(12, 32, Endian.little); // bits per pixel
  data.setUint32(14, png.length, Endian.little); // 图片数据长度
  data.setUint32(18, imageOffset, Endian.little); // 图片数据偏移

  final bytes = data.buffer.asUint8List();
  bytes.setRange(imageOffset, imageOffset + png.length, png);
  return bytes;
}

/// Windows：把用户图片转成 `.ico`，再用 Win32 换掉窗口 / 任务栏图标。
///
/// * exe 自身的图标是**打包时**烧进去的资源，运行时改不了——想改那个只能重新构建；
/// * 但窗口标题栏与任务栏用的是 `WM_SETICON`，运行时可以随时换。
class WindowsAppIcon {
  WindowsAppIcon({DynamicLibrary? user32})
      : _lib = user32 ?? DynamicLibrary.open('user32.dll') {
    _findWindowW = _lib.lookupFunction<_FindWindowNative, _FindWindowDart>(
      'FindWindowW',
    );
    _sendMessageW = _lib.lookupFunction<_SendMessageNative, _SendMessageDart>(
      'SendMessageW',
    );
    _loadImageW = _lib.lookupFunction<_LoadImageNative, _LoadImageDart>(
      'LoadImageW',
    );
    _destroyIcon = _lib.lookupFunction<_DestroyIconNative, _DestroyIconDart>(
      'DestroyIcon',
    );
    _getModuleHandleW =
        _lib.lookupFunction<_GetModuleHandleNative, _GetModuleHandleDart>(
      'GetModuleHandleW',
    );
    _extractIconW = _lib.lookupFunction<_ExtractIconNative, _ExtractIconDart>(
      'ExtractIconW',
    );
  }

  final DynamicLibrary _lib;

  late final _FindWindowDart _findWindowW;
  late final _SendMessageDart _sendMessageW;
  late final _LoadImageDart _loadImageW;
  late final _DestroyIconDart _destroyIcon;
  late final _GetModuleHandleDart _getModuleHandleW;
  late final _ExtractIconDart _extractIconW;

  /// Flutter Windows runner 注册的窗口类名（见 `windows/runner/win32_window.cpp`）。
  static const String windowClassName = 'FLUTTER_RUNNER_WIN32_WINDOW';

  static const int _wmSetIcon = 0x0080;
  static const int _iconSmall = 0;
  static const int _iconBig = 1;
  static const int _imageIcon = 1;
  static const int _lrLoadFromFile = 0x0010;
  static const String _icoFileName = 'toki_app_icon.ico';

  /// 应用自定义图标：图片 → 256px PNG → .ico → WM_SETICON。
  Future<bool> setIcon(String imagePath) async {
    final png = await _pngBytes(imagePath, 256);
    if (png == null) return false;
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, _icoFileName));
    await file.writeAsBytes(buildIcoFromPng(png), flush: true);
    return _applyIco(file.path);
  }

  /// 恢复默认：从自己的 exe 里取回原来的图标。
  Future<bool> resetIcon() {
    final hwnd = _window();
    if (hwnd == 0) return Future<bool>.value(false);
    final instance = _getModuleHandleW(nullptr);
    final icon = _extractIconW(instance, nullptr, 0);
    if (icon == 0) return Future<bool>.value(false);
    _releaseIcons();
    _bigIcon = icon;
    _smallIcon = icon;
    _sendMessageW(hwnd, _wmSetIcon, _iconBig, icon);
    _sendMessageW(hwnd, _wmSetIcon, _iconSmall, icon);
    return Future<bool>.value(true);
  }

  bool _applyIco(String icoPath) {
    final hwnd = _window();
    if (hwnd == 0) return false;
    final path = icoPath.toNativeUtf16();
    try {
      final big = _loadImageW(0, path, _imageIcon, 256, 256, _lrLoadFromFile);
      final small = _loadImageW(0, path, _imageIcon, 32, 32, _lrLoadFromFile);
      // 窗口不接管图标句柄的释放：换新的之前要把旧的销毁掉，新的要留着。
      _releaseIcons();
      var changed = false;
      if (big != 0) {
        _sendMessageW(hwnd, _wmSetIcon, _iconBig, big);
        _bigIcon = big;
        changed = true;
      }
      if (small != 0) {
        _sendMessageW(hwnd, _wmSetIcon, _iconSmall, small);
        _smallIcon = small;
        changed = true;
      }
      return changed;
    } finally {
      malloc.free(path);
    }
  }

  /// 当前窗口正在用的图标句柄（窗口不会帮我们释放，得自己记着）。
  int _bigIcon = 0;
  int _smallIcon = 0;

  void _releaseIcons() {
    for (final icon in <int>[_bigIcon, _smallIcon]) {
      if (icon != 0) _destroyIcon(icon);
    }
    _bigIcon = 0;
    _smallIcon = 0;
  }

  int _window() {
    final className = windowClassName.toNativeUtf16();
    try {
      return _findWindowW(className, nullptr);
    } finally {
      malloc.free(className);
    }
  }

  /// 把任意支持的图片缩进 256×256 透明画布，再编码成 PNG。
  Future<Uint8List?> _pngBytes(String imagePath, int size) async {
    final file = File(imagePath);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final source = frame.image;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final scale = size / math.max(source.width, source.height);
      final width = source.width * scale;
      final height = source.height * scale;
      canvas.drawImageRect(
        source,
        Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
        Rect.fromLTWH(
          (size - width) / 2,
          (size - height) / 2,
          width,
          height,
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return data?.buffer.asUint8List();
    } finally {
      source.dispose();
      codec.dispose();
    }
  }
}

typedef _FindWindowNative = IntPtr Function(Pointer<Utf16>, Pointer<Utf16>);
typedef _FindWindowDart = int Function(Pointer<Utf16>, Pointer<Utf16>);

typedef _SendMessageNative = IntPtr Function(IntPtr, Uint32, IntPtr, IntPtr);
typedef _SendMessageDart = int Function(int, int, int, int);

typedef _LoadImageNative = IntPtr Function(
  IntPtr,
  Pointer<Utf16>,
  Uint32,
  Int32,
  Int32,
  Uint32,
);
typedef _LoadImageDart = int Function(
  int,
  Pointer<Utf16>,
  int,
  int,
  int,
  int,
);

typedef _DestroyIconNative = Int32 Function(IntPtr);
typedef _DestroyIconDart = int Function(int);

typedef _GetModuleHandleNative = IntPtr Function(Pointer<Utf16>);
typedef _GetModuleHandleDart = int Function(Pointer<Utf16>);

typedef _ExtractIconNative = IntPtr Function(IntPtr, Pointer<Utf16>, Uint32);
typedef _ExtractIconDart = int Function(int, Pointer<Utf16>, int);
