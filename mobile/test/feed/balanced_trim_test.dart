import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_schema.dart';

import '../../tool/feed/generate.dart';

final _base = DateTime.utc(2026, 7, 28);

/// [ageInHours] büyüdükçe kayıt eskir. Tarih tek değişken olsun diye.
FeedItem _item(FeedItemKind kind, int ageInHours) => FeedItem(
  id: '${kind.name}-$ageInHours'.padRight(16, '0'),
  kind: kind,
  title: '${kind.name} $ageInHours',
  summary: 'Açıklama.',
  summaryOrigin: SummaryOrigin.original,
  sourceName: 'Kaynak',
  sourceKind: FeedSourceKind.officialBlog,
  url: Uri.parse('https://ornek.test/${kind.name}/$ageInHours'),
  publishedAt: _base.subtract(Duration(hours: ageInHours)),
  checkedAt: _base,
  language: 'tr',
  trust: const TrustSignals(
    officialSource: true,
    hasLicense: false,
    recentlyUpdated: true,
    maintained: true,
  ),
);

Map<FeedItemKind, int> _countByKind(List<FeedItem> items) {
  final counts = <FeedItemKind, int>{};
  for (final item in items) {
    counts[item.kind] = (counts[item.kind] ?? 0) + 1;
  }
  return counts;
}

void main() {
  test('limitin altındaki liste olduğu gibi kalır', () {
    final items = [
      _item(FeedItemKind.announcement, 3),
      _item(FeedItemKind.aiModel, 1),
    ];

    expect(balancedTrim(items, limit: 50), hasLength(2));
  });

  test('çıktı her zaman yeniden eskiye sıralı', () {
    final items = [
      for (var age = 0; age < 40; age++) _item(FeedItemKind.announcement, age),
    ];

    final trimmed = balancedTrim(items, limit: 10);
    for (var index = 1; index < trimmed.length; index++) {
      expect(
        trimmed[index].publishedAt.isAfter(trimmed[index - 1].publishedAt),
        isFalse,
      );
    }
  });

  /// Ölçülen gerçek koşu (2026-07-28): blog kaynakları eklendikten sonra
  /// duyurular tarih sıralamasında modelleri ezdi ve "AI Modelleri"
  /// sekmesinde 200 kayıttan yalnız **4** tanesi kaldı. Uygulamanın sekmeleri
  /// türe göre süzdüğü için bu, boş bir sekme demekti.
  test('yüksek hacimli bir tür diğerlerini aç bırakamaz', () {
    final items = [
      // Duyurular hem çok hem taze: saf tarih sıralamasında hepsini alırlar.
      for (var age = 0; age < 300; age++) _item(FeedItemKind.announcement, age),
      // Modeller daha eski — ama yine de görünmeliler.
      for (var age = 400; age < 460; age++) _item(FeedItemKind.aiModel, age),
      for (var age = 500; age < 530; age++) _item(FeedItemKind.mcp, age),
    ];

    final trimmed = balancedTrim(items, limit: 200, floorPerKind: 20);
    final counts = _countByKind(trimmed);

    expect(trimmed, hasLength(200));
    expect(counts[FeedItemKind.aiModel], greaterThanOrEqualTo(20));
    expect(counts[FeedItemKind.mcp], greaterThanOrEqualTo(20));
    // Duyurular hâlâ çoğunluk: taban tarihi devre dışı bırakmıyor, yalnız
    // diğer türlere bir taban ayırıyor.
    expect(counts[FeedItemKind.announcement], greaterThan(100));
  });

  test('taban dolduktan sonra kalan yerler tarihe göre dolar', () {
    final items = [
      for (var age = 0; age < 100; age++) _item(FeedItemKind.announcement, age),
      for (var age = 200; age < 230; age++) _item(FeedItemKind.aiModel, age),
    ];

    final trimmed = balancedTrim(items, limit: 60, floorPerKind: 20);
    final counts = _countByKind(trimmed);

    expect(trimmed, hasLength(60));
    expect(counts[FeedItemKind.aiModel], 20, reason: 'tabanı kadar');
    expect(counts[FeedItemKind.announcement], 40, reason: 'kalan her şey');
  });

  /// Taban, türe düşen paydan büyük olamaz: tek bir türün tabanı bütün yeri
  /// yiyip diğerlerine hiç bırakmamalı.
  test('taban limite sığmıyorsa küçültülür', () {
    final items = [
      for (var age = 0; age < 30; age++) _item(FeedItemKind.announcement, age),
      for (var age = 0; age < 30; age++) _item(FeedItemKind.aiModel, age),
      for (var age = 0; age < 30; age++) _item(FeedItemKind.mcp, age),
    ];

    final trimmed = balancedTrim(items, limit: 9, floorPerKind: 20);
    final counts = _countByKind(trimmed);

    expect(trimmed, hasLength(9));
    for (final kind in [
      FeedItemKind.announcement,
      FeedItemKind.aiModel,
      FeedItemKind.mcp,
    ]) {
      expect(counts[kind], 3, reason: '$kind eşit pay almalı');
    }
  });

  test('bir türde tabandan az kayıt varsa hepsi alınır', () {
    final items = [
      for (var age = 0; age < 100; age++) _item(FeedItemKind.announcement, age),
      for (var age = 300; age < 305; age++) _item(FeedItemKind.skill, age),
    ];

    final trimmed = balancedTrim(items, limit: 50, floorPerKind: 20);

    expect(_countByKind(trimmed)[FeedItemKind.skill], 5);
    expect(trimmed, hasLength(50));
  });

  test('kopya kayıt üretmez', () {
    final items = [
      for (var age = 0; age < 100; age++) _item(FeedItemKind.announcement, age),
      for (var age = 0; age < 40; age++) _item(FeedItemKind.aiModel, age),
    ];

    final trimmed = balancedTrim(items, limit: 80);

    expect(trimmed.map((item) => item.id).toSet(), hasLength(trimmed.length));
  });

  /// Üretici her koşuda aynı dosyayı yazmalı; aksi hâlde diff gürültüsü
  /// gerçek değişikliği gizler.
  test('aynı girdi her çağrıda aynı çıktıyı verir', () {
    final items = [
      for (var age = 0; age < 120; age++) _item(FeedItemKind.announcement, age),
      for (var age = 0; age < 40; age++) _item(FeedItemKind.aiModel, age),
      for (var age = 0; age < 25; age++) _item(FeedItemKind.mcp, age),
    ];

    final first = balancedTrim(items, limit: 100).map((item) => item.id);
    final second = balancedTrim(
      items.reversed.toList(),
      limit: 100,
    ).map((item) => item.id);

    expect(first, second);
  });
}
