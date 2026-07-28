/// Uygulama sürümü.
///
/// Öncesinde Ayarlar ekranının dibinde `Uygulama Sürümü: [DESIGN_FIXTURE_ONLY]`
/// yazıyordu — tasarım döneminden kalma bir yer tutucu, kullanıcıya olduğu gibi
/// gösteriliyordu.
///
/// Sabit **elle** yazılır ama **elle doğrulanmaz**:
/// `test/app/app_version_test.dart` bunu `pubspec.yaml` ile karşılaştırır, yani
/// sürüm yükseltilip burası unutulursa süit kırmızıya döner. Alternatif olan
/// `package_info_plus`, tek satır metin uğruna taşınacak bir eklenti
/// bağımlılığı olurdu; çalışma zamanında `pubspec.yaml` okunamadığı için de
/// üçüncü bir seçenek yok.
library;

/// `pubspec.yaml` içindeki `version` alanının `+` öncesi.
const appVersion = '1.0.2';

/// `pubspec.yaml` içindeki `version` alanının `+` sonrası (Android
/// `versionCode`).
const appBuildNumber = 3;

/// Kullanıcıya gösterilen tam sürüm.
const appVersionLabel = '$appVersion+$appBuildNumber';
