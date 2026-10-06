import 'dart:io';

import 'package:flutter/material.dart';

/// 把用户填的字符串解析成图片源：
/// * `http(s)://...` → 网络图片
/// * 含路径分隔符或图片后缀 → 本地文件
/// * 其它 → null（调用方回落到文字 / 纯色）
ImageProvider? resolveImageProvider(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.startsWith('http://') || text.startsWith('https://')) {
    return NetworkImage(text);
  }
  final lower = text.toLowerCase();
  final isFileLike = text.contains(Platform.pathSeparator) ||
      text.contains('/') ||
      lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
  if (!isFileLike) return null;
  return FileImage(File(text));
}
