import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/services/sync_service.dart';
import '../../infrastructure/sync/local_sync_service.dart';

/// 当前同步实现。第一版固定为"仅本地"；以后按设置切换成 WebDAV / 云。
final syncServiceProvider = Provider<SyncService>(
  (ref) => LocalSyncService(
    countRows: () async {
      final events = await ref.read(calendarRepositoryProvider).count();
      final countdowns =
          (await ref.read(countdownRepositoryProvider).getAll()).length;
      return events + countdowns;
    },
  ),
);
