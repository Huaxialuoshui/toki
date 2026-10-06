import 'dart:convert';

import 'package:drift/drift.dart';

/// `List<String>` ↔ JSON 文本（用于 AI 人设的 enabledTools 等）。
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const <String>[];
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return const <String>[];
    return decoded.whereType<String>().toList(growable: false);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// 时间列说明：统一使用 drift 的 `dateTime()`。
///
/// drift 以 **Unix 时间戳（秒）** 保存绝对时刻，读回时按本地时区还原，
/// 因此夏令时/时区变化都不会让时间错位；代价是精确到秒（对本应用足够）。
const String kDateTimeStorageNote =
    'DateTime 以 Unix 时间戳（秒）保存绝对时刻，读回为本地时间，精度到秒。';
