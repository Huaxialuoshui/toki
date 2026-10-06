import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/countdown_item.dart';

/// 全部倒计时（置顶优先）。
final countdownsProvider = StreamProvider.autoDispose<List<CountdownItem>>(
  (ref) => ref.watch(countdownRepositoryProvider).watchAll(),
);

/// 已置顶的倒计时（首页横向卡片）。
final pinnedCountdownsProvider =
    StreamProvider.autoDispose<List<CountdownItem>>(
  (ref) => ref.watch(countdownRepositoryProvider).watchPinned(),
);
