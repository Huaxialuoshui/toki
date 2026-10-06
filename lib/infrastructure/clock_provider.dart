import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';

/// 全局时间来源。
///
/// 放在 infrastructure：application 与 data 都需要它，测试里只需 override
/// 这一个 provider 就能确定整个应用的时间。
final clockProvider = Provider<Clock>((ref) => const SystemClock());
