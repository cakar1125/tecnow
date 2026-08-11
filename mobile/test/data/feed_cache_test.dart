import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tecos/data/feed/feed_cache.dart';
import 'package:tecos/data/local/app_database.dart';
import 'package:tecos/data/local/schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SqfliteFeedCache cache;

  setUp(() async {
    db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    cache = SqfliteFeedCache(Future.value(db));
  });

  tearDown(() async => db.close());

  test('boş önbellek null döner', () async {
    expect(await cache.read(), isNull);
  });

  test('yazılan kayıt aynen geri okunur', () async {
    await cache.write(
      CachedFeed(
        payload: '{"schemaVersion": 1}',
        fetchedAt: DateTime.utc(2026, 7, 27, 9, 30),
        generatedAt: DateTime.utc(2026, 7, 27, 6),
        sourceUrl: 'https://ornek.test/feed.json',
      ),
    );

    final entry = await cache.read();
    expect(entry, isNotNull);
    expect(entry!.payload, '{"schemaVersion": 1}');
    expect(entry.fetchedAt, DateTime.utc(2026, 7, 27, 9, 30));
    expect(entry.generatedAt, DateTime.utc(2026, 7, 27, 6));
    expect(entry.sourceUrl, 'https://ornek.test/feed.json');
  });

  /// Cihazın saat dilimi değişirse "son güncelleme" saatleri kaymamalı.
  test('tarihler UTC olarak korunur', () async {
    final local = DateTime(2026, 7, 27, 12);
    await cache.write(
      CachedFeed(
        payload: '{}',
        fetchedAt: local,
        generatedAt: local,
        sourceUrl: 'https://ornek.test/feed.json',
      ),
    );

    final entry = (await cache.read())!;
    expect(entry.fetchedAt.isUtc, isTrue);
    expect(entry.fetchedAt, local.toUtc());
  });

  /// "Son çekilen feed" tanımı gereği tekildir. İkinci bir kaydın birikmesi
  /// önbelleği zamanla büyüyen bir tabloya çevirirdi.
  test('ikinci yazma eskisinin yerine geçer', () async {
    for (final version in ['ilk', 'ikinci', 'ucuncu']) {
      await cache.write(
        CachedFeed(
          payload: version,
          fetchedAt: DateTime.utc(2026, 7, 27),
          generatedAt: DateTime.utc(2026, 7, 27),
          sourceUrl: 'https://ornek.test/feed.json',
        ),
      );
    }

    expect((await cache.read())!.payload, 'ucuncu');
    final rows = await db.query(FeedCacheTable.name);
    expect(rows, hasLength(1));
  });

  /// Tekillik yalnız uygulama kodunda varsayılmaz: veritabanı da reddeder.
  test('ikinci satır veritabanı seviyesinde engellenir', () async {
    await expectLater(
      db.insert(FeedCacheTable.name, {
        FeedCacheTable.id: 2,
        FeedCacheTable.payload: '{}',
        FeedCacheTable.fetchedAt: 1,
        FeedCacheTable.generatedAt: 1,
        FeedCacheTable.sourceUrl: 'https://ornek.test/feed.json',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  /// Ölçüldü (2026-07-28): 200 kayıtlık gerçek feed ham 182,8 KB, gzip
  /// 30,5 KB. Sıkıştırma sessizce kaybolursa önbellek yedi katına çıkar ve
  /// bunu kimse fark etmez — bu yüzden kazanç testle sabitleniyor.
  test('gövde sıkıştırılmış saklanır', () async {
    // JSON'a benzeyen, tekrarlı bir gövde: gerçek feed de böyledir.
    final payload = jsonEncode({
      'schemaVersion': 1,
      'items': [
        for (var index = 0; index < 400; index++)
          {
            'id': 'kayit-$index',
            'title': 'Örnek başlık',
            'summary': 'Açıklama.',
          },
      ],
    });

    await cache.write(
      CachedFeed(
        payload: payload,
        fetchedAt: DateTime.utc(2026, 7, 28),
        generatedAt: DateTime.utc(2026, 7, 28),
        sourceUrl: 'https://ornek.test/feed.json',
      ),
    );

    final stored = (await db.query(FeedCacheTable.name)).single;
    final blob = stored[FeedCacheTable.payload]! as List<int>;

    expect(
      blob.length,
      lessThan(payload.length ~/ 4),
      reason: 'gzip en az dörtte bire indirmeli',
    );
    // Ve kayıpsız: geri okunan metin birebir aynı olmalı.
    expect((await cache.read())!.payload, payload);
  });

  test('Türkçe karakterler gidiş-dönüşte bozulmaz', () async {
    const payload = '{"baslik":"Şığüöç İçerik — açıklama"}';
    await cache.write(
      CachedFeed(
        payload: payload,
        fetchedAt: DateTime.utc(2026, 7, 28),
        generatedAt: DateTime.utc(2026, 7, 28),
        sourceUrl: 'https://ornek.test/feed.json',
      ),
    );

    expect((await cache.read())!.payload, payload);
  });

  /// Kendini onarır: bozuk bir satır silinmezse her açılışta yeniden
  /// çözülmeye çalışılır ve önbellek kalıcı olarak ölü kalırdı.
  test('çözülemeyen gövde silinir ve null döner', () async {
    await db.insert(FeedCacheTable.name, {
      FeedCacheTable.id: 1,
      FeedCacheTable.payload: Uint8List.fromList([1, 2, 3, 4, 5]),
      FeedCacheTable.fetchedAt: 1,
      FeedCacheTable.generatedAt: 1,
      FeedCacheTable.sourceUrl: 'https://ornek.test/feed.json',
    });

    expect(await cache.read(), isNull);
    expect(
      await db.query(FeedCacheTable.name),
      isEmpty,
      reason: 'bozuk satır silinmeli',
    );
  });

  test('clear önbelleği boşaltır', () async {
    await cache.write(
      CachedFeed(
        payload: '{}',
        fetchedAt: DateTime.utc(2026, 7, 27),
        generatedAt: DateTime.utc(2026, 7, 27),
        sourceUrl: 'https://ornek.test/feed.json',
      ),
    );
    await cache.clear();

    expect(await cache.read(), isNull);
  });
}
