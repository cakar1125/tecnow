import 'app/bootstrap.dart';

void main() {
  // `ProviderScope` artık `bootstrap` içinde kuruluyor: tohumlamanın
  // `runApp`'ten önce çalışabilmesi için konteynerin elle oluşturulması gerekir.
  bootstrap();
}
