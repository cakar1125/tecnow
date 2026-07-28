/// Detay rotası — tek yerde.
///
/// Önceden her çağıran ekran kendi `switch`'iyle türden rota seçiyordu ve o
/// `switch`'lerde yeri olmayan türler hiçbir yere gidemiyordu. Rota artık
/// türe bakmaz; hangi ekranın çizileceğine kaydın kendisi karar verir.
library;

String detailRoute(String id) => '/icerik/$id';
