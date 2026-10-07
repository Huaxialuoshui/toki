import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:toki/infrastructure/device/windows_app_icon.dart';

/// Windows 自定义图标用的 ICO 容器（PNG 压缩条目）。
void main() {
  Uint8List fakePng(int length) => Uint8List.fromList(
        <int>[0x89, 0x50, 0x4E, 0x47, ...List<int>.filled(length, 0x7F)],
      );

  test('ICO 头部与条目结构正确（256 尺寸写 0）', () {
    final png = fakePng(64);
    final ico = buildIcoFromPng(png);
    final data = ByteData.sublistView(ico);

    expect(data.getUint16(0, Endian.little), 0); // reserved
    expect(data.getUint16(2, Endian.little), 1); // type = icon
    expect(data.getUint16(4, Endian.little), 1); // 一个尺寸

    expect(data.getUint8(6), 0); // 宽度 0 = 256
    expect(data.getUint8(7), 0); // 高度 0 = 256
    expect(data.getUint8(8), 0); // 调色板
    expect(data.getUint8(9), 0); // reserved
    expect(data.getUint16(10, Endian.little), 1); // planes
    expect(data.getUint16(12, Endian.little), 32); // bpp
    expect(data.getUint32(14, Endian.little), png.length);
    expect(data.getUint32(18, Endian.little), 22); // 数据紧跟在头后面

    // PNG 数据原样放在偏移 22 之后
    expect(ico.sublist(22), png);
  });

  test('非 256 尺寸按真实像素写入宽高', () {
    final ico = buildIcoFromPng(fakePng(8), size: 64);
    expect(ico[6], 64);
    expect(ico[7], 64);
  });
}
