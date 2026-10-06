import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// `context.l10n.navHome` 这样的简写，避免每处都写 `AppLocalizations.of(context)`。
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// 当前生效的语言代码（`zh` / `en`），用于日期格式化。
  String get localeCode => Localizations.localeOf(this).languageCode;
}
