import 'dart:io';

/// Bağlayıcı testleri **ağa çıkmaz**: gerçek servislerden alınmış biçimde
/// örnek yanıtlar `test/feed/fixtures/` altında durur.
///
/// Böylece testler hızlıdır, çevrimdışı çalışır ve dış servisin o günkü
/// içeriğine bağlı değildir — bir bağlayıcı testi kırılıyorsa sebebi bizim
/// kodumuzdur, karşı tarafın o gün ne yayımladığı değil.
String feedFixture(String name) =>
    File('test/feed/fixtures/$name').readAsStringSync();
