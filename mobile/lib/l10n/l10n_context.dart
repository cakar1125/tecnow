/// `context.l10n` — çevirilere erişim.
///
/// `context.text` ve `context.palette` ile aynı desen: tasarım sistemi ve
/// diller aynı yoldan okunuyor, böylece bir widget'ın hangi bağlam değerine
/// baktığı tek bir bakışta görünüyor.
///
/// **`AppLocalizations.of(context)` doğrudan çağrılmıyor.** Uzun olduğu için
/// değil: `l10n.yaml`'da `nullable-getter: false` verildiği için o çağrı
/// delege eksikse `null` yerine **hata** fırlatıyor, ve o hata çalışma anında
/// çıkıyor. Tek bir yerden geçirmek, hatanın nerede doğduğunu belirsiz
/// bırakmıyor.
library;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension L10nContext on BuildContext {
  L10n get l10n => L10n.of(this);
}
