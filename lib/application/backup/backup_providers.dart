import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_store.dart';
import '../../data/repositories/repository_providers.dart';
import '../../infrastructure/backup/backup_file_store.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/database/app_database.dart';
import 'backup_service.dart';

/// 备份文件读写（测试里可以 override 到临时目录）。
final backupFileStoreProvider = Provider<BackupFileStore>(
  (ref) => BackupFileStore(),
);

final backupStoreProvider = Provider<BackupStore>(
  (ref) => BackupStore(ref.watch(appDatabaseProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    store: ref.watch(backupStoreProvider),
    files: ref.watch(backupFileStoreProvider),
    clock: ref.watch(clockProvider),
    currentSchemaVersion: AppDatabase.currentSchemaVersion,
  ),
);
