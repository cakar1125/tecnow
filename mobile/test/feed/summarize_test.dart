import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_schema.dart';

import '../../tool/feed/summarize.dart';
import '../../tool/feed/summary_guard.dart';

final _now = DateTime.utc(2026, 7, 27);

FeedItem _item({
  String id = 'a',
  String title = 'Nexus-7B released',
  String summary = 'A new open-weights model with 7B parameters.',
  SummaryOrigin origin = SummaryOrigin.original,
  String language = 'en',
  String? summarySourceHash,
}) => FeedItem(
  id: id,
  kind: FeedItemKind.aiModel,
  title: title,
  summary: summary,
  summaryOrigin: origin,
  sourceName: 'Hugging Face',
  sourceKind: FeedSourceKind.huggingFace,
  url: Uri.parse('https://huggingface.co/a/b'),
  publishedAt: _now,
  checkedAt: _now,
  language: language,
  trust: const TrustSignals(
    officialSource: true,
    hasLicense: true,
    recentlyUpdated: true,
    maintained: true,
    popularity: 5,
  ),
  topics: const ['llm'],
  summarySourceHash: summarySourceHash,
);

/// Önceki yayında duran, taşınmaya hazır bir kayıt.
///
/// Damga **gerçek kaynak metinden** üretilir — elle uydurulmuş bir damga testi
/// yeşil gösterip üretimde taşımayı hiç çalıştırmazdı.
FeedItem _published({
  String id = 'a',
  String title = 'Nexus-7B released',
  String sourceSummary = 'A new open-weights model with 7B parameters.',
  String turkish = 'Yeni bir açık ağırlıklı model yayımlandı.',
}) => _item(
  id: id,
  title: title,
  summary: turkish,
  origin: SummaryOrigin.generated,
  language: 'tr',
  summarySourceHash: fnv1aHex(
    sourceTextOf(_item(id: id, title: title, summary: sourceSummary)),
  ),
);

/// Sabit bir cevap veren sahte model.
final class FakeSummarizer implements Summarizer {
  FakeSummarizer(this.reply);

  final String? reply;
  final seen = <String>[];

  /// İstenen diller. Dilin çağrıya **gerçekten** ulaştığını ölçebilmek için
  /// ayrı tutuluyor: hedef dil ile damgalanan dil ayrışırsa çıktı geçerli
  /// görünüp yanlış etiketli olur ve bunu başka hiçbir kapı yakalamaz.
  final languages = <String>[];

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
    required String language,
  }) async {
    seen.add(sourceText);
    languages.add(language);
    return reply;
  }
}

final class ThrowingSummarizer implements Summarizer {
  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
    required String language,
  }) async => throw StateError('ağ hatası');
}

void main() {
  group('anahtar yokken', () {
    /// Anahtar bir kolaylıktır, koşul değil: feed anahtarsız da eksiksiz
    /// üretilmeli.
    test('hiç çağrı yapılmaz ve kayıtlar olduğu gibi kalır', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: const DisabledSummarizer());

      expect(pass.summarized, 0);
      expect(pass.items.single.summaryOrigin, SummaryOrigin.original);
      expect(
        pass.items.single.summary,
        'A new open-weights model with 7B parameters.',
      );
      expect(pass.items.single.language, 'en');
    });
  });

  group('kabul edilen özet', () {
    test('tecOS özeti olarak işaretlenir ve dili Türkçe olur', () async {
      final pass = await applySummaries(
        [_item()],
        summarizer: FakeSummarizer('7B parametreli yeni açık ağırlıklı model.'),
      );

      final item = pass.items.single;
      expect(item.summary, '7B parametreli yeni açık ağırlıklı model.');
      expect(item.summaryOrigin, SummaryOrigin.generated);
      expect(item.language, 'tr');
      expect(pass.summarized, 1);
    });

    /// Özet yeniden yazılabilir, gerçekler yazılamaz.
    test('kaynak, adres, tarih ve güven sinyalleri değişmez', () async {
      final original = _item();
      final pass = await applySummaries([
        original,
      ], summarizer: FakeSummarizer('7B parametreli model.'));

      final item = pass.items.single;
      expect(item.url, original.url);
      expect(item.sourceName, original.sourceName);
      expect(item.publishedAt, original.publishedAt);
      expect(item.trust.score, original.trust.score);
      expect(item.topics, original.topics);
      expect(item.id, original.id);
    });
  });

  group('doğrulama kapısı', () {
    /// Kapı tek yönlü güvenli: şüphede kalırsa reddeder ve kayıt orijinal
    /// metniyle yayımlanır. En kötü durumda İngilizce kalır, uydurulmaz.
    test('kaynakta olmayan sayı reddedilir, orijinal korunur', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer('Model ayda 20 dolara sunuluyor.'));

      final item = pass.items.single;
      expect(item.summaryOrigin, SummaryOrigin.original);
      expect(item.summary, 'A new open-weights model with 7B parameters.');
      expect(pass.summarized, 0);
      expect(pass.rejected, {SummaryRejection.unsourcedNumber: 1});
    });

    test('kaynakta olmayan bağlantı reddedilir', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer('Ayrıntı: https://uydurma.test/x'));
      expect(pass.rejected, {SummaryRejection.unsourcedLink: 1});
      expect(pass.items.single.summaryOrigin, SummaryOrigin.original);
    });

    test('çok uzun özet reddedilir', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer('çok uzun ' * 60));
      expect(pass.rejected, {SummaryRejection.tooLong: 1});
    });
  });

  group('modele verilen metin', () {
    /// Tarih ve makine alanları modele **verilmez**: tarih metne girerse izin
    /// verilen sayı havuzu genişler ve uydurulmuş bir fiyat kapıdan geçer.
    test('yalnız başlık ve kaynağın kendi açıklaması gönderilir', () async {
      final summarizer = FakeSummarizer(null);
      await applySummaries([_item()], summarizer: summarizer);

      final sent = summarizer.seen.single;
      expect(
        sent,
        'Nexus-7B released\nA new open-weights model with 7B '
        'parameters.',
      );
      expect(sent, isNot(contains('2026')), reason: 'tarih sızmamalı');
      expect(sent, isNot(contains('huggingface.co')));
    });
  });

  group('dayanıklılık', () {
    test('model hatası kaydı düşürür, koşuyu değil', () async {
      final pass = await applySummaries([
        _item(),
        _item(title: 'İkinci'),
      ], summarizer: ThrowingSummarizer());
      expect(pass.items, hasLength(2));
      expect(pass.failed, 2);
      expect(pass.summarized, 0);
    });

    test('boş cevap kaydı olduğu gibi bırakır', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer(null));
      expect(pass.items.single.summaryOrigin, SummaryOrigin.original);
      expect(pass.rejected, isEmpty);
      expect(pass.failed, 0);
    });

    /// tecOS'un kendi kurduğu cümle zaten Türkçedir.
    test('tecOS özeti yeniden özetlenmez', () async {
      final summarizer = FakeSummarizer('yeni özet');
      final pass = await applySummaries([
        _item(
          origin: SummaryOrigin.generated,
          summary: 'Hugging Face üzerinde yayımlanan model.',
          language: 'tr',
        ),
      ], summarizer: summarizer);

      expect(summarizer.seen, isEmpty, reason: 'çağrı yapılmamalı');
      expect(
        pass.items.single.summary,
        'Hugging Face üzerinde yayımlanan '
        'model.',
      );
    });

    /// Maliyet kapısı: bütçe dolunca kalanlar orijinal metinleriyle kalır ve
    /// koşu **başarısız olmaz**.
    test('bütçe aşılınca kalan kayıtlar orijinal kalır', () async {
      final summarizer = FakeSummarizer('Kısa Türkçe özet.');
      final pass = await applySummaries(
        [_item(title: 'Bir'), _item(title: 'İki'), _item(title: 'Üç')],
        summarizer: summarizer,
        budget: 2,
      );

      expect(summarizer.seen, hasLength(2));
      expect(pass.summarized, 2);
      expect(pass.budgetExhausted, isTrue);
      expect(pass.items, hasLength(3));
      expect(pass.items.last.summaryOrigin, SummaryOrigin.original);
    });
  });

  /// Taşıma: önceki yayında aynı kaynak metinden üretilmiş bir özet varsa
  /// model **hiç çağrılmaz**.
  ///
  /// Düzeltilen kusur (ölçüldü 2026-08-03): üretici feed'i her koşuda
  /// kaynaklardan yeniden kurduğu için geçen koşunun Türkçe özetleri
  /// kayboluyor, bütçe aynı işi tekrar satın almaya gidiyordu. Yayımlanan 200
  /// kaydın 180'i bu yüzden İngilizce kalmıştı.
  group('özet taşıma', () {
    test('kaynak metin aynıysa özet taşınır, model çağrılmaz', () async {
      final summarizer = FakeSummarizer('çağrılmamalı');

      final pass = await applySummaries(
        [_item()],
        summarizer: summarizer,
        previous: [_published()],
      );

      expect(summarizer.seen, isEmpty, reason: 'model çağrılmamalı');
      expect(pass.carried, 1);
      expect(pass.summarized, 0);
      expect(
        pass.items.single.summary,
        'Yeni bir açık ağırlıklı model yayımlandı.',
      );
      expect(pass.items.single.summaryOrigin, SummaryOrigin.generated);
      expect(pass.items.single.language, 'tr');
    });

    /// Eski özet artık başka bir metni anlatıyor olurdu. Damganın var olma
    /// sebebi tam olarak bu.
    test('kaynak metin değiştiyse taşınmaz, yeniden özetlenir', () async {
      final summarizer = FakeSummarizer('Güncellenmiş Türkçe özet.');

      final pass = await applySummaries(
        [_item(summary: 'Now with 70B parameters and a new license.')],
        summarizer: summarizer,
        previous: [_published()],
      );

      expect(summarizer.seen, hasLength(1), reason: 'model çağrılmalı');
      expect(pass.carried, 0);
      expect(pass.summarized, 1);
      expect(pass.items.single.summary, 'Güncellenmiş Türkçe özet.');
    });

    /// Damgasız kayıt, bu alan eklenmeden önceki bir sürümden gelmiş olabilir;
    /// kaynak metninin değişip değişmediği **bilinemez**, o yüzden taşınmaz.
    test('damgası olmayan önceki kayıt taşınmaz', () async {
      final summarizer = FakeSummarizer('Yeni özet.');

      final pass = await applySummaries(
        [_item()],
        summarizer: summarizer,
        previous: [
          _item(summary: 'Eski Türkçe özet.', origin: SummaryOrigin.generated),
        ],
      );

      expect(summarizer.seen, hasLength(1));
      expect(pass.carried, 0);
    });

    test('önceki yayın yoksa davranış değişmez', () async {
      final summarizer = FakeSummarizer('Türkçe özet.');

      final pass = await applySummaries([_item()], summarizer: summarizer);

      expect(summarizer.seen, hasLength(1));
      expect(pass.carried, 0);
      expect(pass.summarized, 1);
    });

    /// Taşıma bir çağrı harcamaz; harcasaydı bütçe yine aynı işe giderdi ve
    /// düzeltme hiçbir şey kazandırmazdı.
    test('taşınan kayıt bütçeden düşmez', () async {
      final summarizer = FakeSummarizer('Yeni kayıt için özet.');

      final pass = await applySummaries(
        [_item(id: 'a'), _item(id: 'b', title: 'Başka bir model')],
        summarizer: summarizer,
        budget: 1,
        previous: [_published(id: 'a')],
      );

      expect(pass.carried, 1);
      expect(pass.summarized, 1, reason: 'bütçe yeni kayda kaldı');
      expect(summarizer.seen, hasLength(1));
    });

    /// Kapı kuralları zamanla sıkılaşabilir. Taşımak, yeni kuralı sessizce
    /// atlamak anlamına gelmemeli.
    test('taşınan özet kapıdan geçemezse taşınmaz', () async {
      final summarizer = FakeSummarizer('Kaynağa sadık yeni özet.');
      // Kaynakta olmayan bir sayı taşıyan "önceki" özet.
      final poisoned = _published(
        turkish: 'Model 99 milyar parametreyle geldi.',
      );

      final pass = await applySummaries(
        [_item()],
        summarizer: summarizer,
        previous: [poisoned],
      );

      expect(pass.carried, 0, reason: 'kapı reddetmeli');
      expect(summarizer.seen, hasLength(1), reason: 'yeniden üretilmeli');
    });
  });

  /// Sıralı yedekleme — feed adresi failover'ıyla aynı desen.
  group('FallbackSummarizer', () {
    test('birincil çökerse ikincil kullanılır', () async {
      final backup = FakeSummarizer('Yedekten gelen özet.');
      final chain = FallbackSummarizer([ThrowingSummarizer(), backup]);

      final result = await chain.summarize(
        title: 't',
        sourceText: 's',
        language: 'tr',
      );

      expect(result, 'Yedekten gelen özet.');
      expect(backup.seen, hasLength(1));
      expect(backup.languages, ['tr'], reason: 'dil yedeğe de geçmeli');
    });

    /// `null` bir hata değil, "bu kayıt için özet yok" demektir. Yedeğe
    /// taşımak, bilerek özet üretmeyen bir sağlayıcının kararını ezmek olurdu.
    test('birincil null dönerse ikinciye geçilmez', () async {
      final backup = FakeSummarizer('Kullanılmamalı.');
      final chain = FallbackSummarizer([FakeSummarizer(null), backup]);

      expect(
        await chain.summarize(title: 't', sourceText: 's', language: 'tr'),
        isNull,
      );
      expect(backup.seen, isEmpty);
    });

    /// Hepsi çökerse koşu **kırmızıya dönmez**: `applySummaries` hatayı yutar
    /// ve kayıt orijinal metniyle kalır.
    test('hepsi çökerse kayıt orijinal kalır', () async {
      final pass = await applySummaries(
        [_item()],
        summarizer: FallbackSummarizer([
          ThrowingSummarizer(),
          ThrowingSummarizer(),
        ]),
      );

      expect(pass.failed, 1);
      expect(pass.summarized, 0);
      expect(pass.items.single.summaryOrigin, SummaryOrigin.original);
    });
  });

  /// OpenAI uyumlu yanıt ayrıştırma (NVIDIA NIM bu biçimi kullanıyor).
  ///
  /// Canlı çağrı test edilemiyor ama **ayrıştırma** edilebilir — gerçek bir
  /// hatanın oluşabileceği yer burası.
  group('parseOpenAiText', () {
    test('geçerli yanıttan metin çıkarılır', () {
      const body =
          '{"choices":[{"message":{"role":"assistant",'
          '"content":"  Türkçe özet.  "}}]}';

      expect(parseOpenAiText(body), 'Türkçe özet.');
    });

    test('bozuk gövde null döner', () {
      expect(parseOpenAiText('bu JSON değil'), isNull);
      expect(parseOpenAiText('[]'), isNull);
    });

    test('içerik yoksa veya boşsa null döner', () {
      expect(parseOpenAiText('{"choices":[]}'), isNull);
      expect(parseOpenAiText('{"choices":[{"message":{}}]}'), isNull);
      expect(
        parseOpenAiText('{"choices":[{"message":{"content":"   "}}]}'),
        isNull,
      );
    });
  });

  /// İstek gövdesinin kodlanması.
  ///
  /// Ölçülen kusur (2026-08-12, gerçek NVIDIA uç noktası): gövde
  /// `HttpClientRequest.write(String)` ile yazılıyordu ve o metot
  /// `request.encoding` kullanıyor — varsayılanı **Latin-1**. Yönerge Türkçe
  /// olduğu için beş çağrının beşi de düştü:
  /// `Invalid argument (string): Contains invalid characters.`
  ///
  /// Kusur sessizdi: çağrı hatası kaydı düşürüyor, koşuyu değil. Anahtar
  /// eklenmiş olsaydı yayın "başarıyla" tamamlanır ve 200 kaydın 200'ü
  /// İngilizce kalırdı.
  group('istek gövdesi', () {
    test('Türkçe yönerge UTF-8 kodlanır ve geri okunur', () {
      final bytes = encodeRequestBody({'content': summaryInstructionFor('tr')});
      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;

      expect(decoded['content'], contains('Aşağıdaki'));
      expect(decoded['content'], contains('özetle'));
    });

    /// Kodlamanın gerçekten UTF-8 olduğunun kanıtı: Latin-1'de her karakter
    /// bir bayt olurdu. Türkçe harfler iki bayt kaplıyor, yani bayt sayısı
    /// karakter sayısını **aşmak zorunda**. Bu satır olmadan test, tek baytlı
    /// bir kodlamada da yeşil kalırdı.
    test('çok baytlı harfler bir bayttan fazla yer kaplar', () {
      final text = summaryInstructionFor('tr');
      final json = jsonEncode({'content': text});

      expect(
        encodeRequestBody({'content': text}).length,
        greaterThan(json.length),
      );
    });

    /// Yalnız Türkçe değil: hedef dil listesindeki her ad kodlanabilmeli.
    /// Arapça'nın buraya girmesi bilinçli — Latin-1'e hiç sığmayan bir alfabe,
    /// aynı kusurun geri gelmesini en hızlı yakalayan durum.
    test('her hedef dil adı kodlanabilir', () {
      for (final code in summaryLanguageNames.keys) {
        final bytes = encodeRequestBody({
          'content': summaryInstructionFor(code),
        });
        expect(
          utf8.decode(bytes),
          contains(summaryLanguageNames[code]!),
          reason: '$code kodlanamadı',
        );
      }
    });
  });

  group('hedef dil', () {
    /// Yönergede dil dışında **hiçbir şey** değişmemeli: iki dilin özetleri
    /// arasındaki fark modelden gelmeli, yönergeden değil. Aksi hâlde dil
    /// başına kalite ölçümü anlamsızlaşır.
    test('yönergede yalnız dil adı değişir', () {
      final turkish = summaryInstructionFor('tr');
      final english = summaryInstructionFor('en');

      expect(turkish, contains('Türkçe'));
      expect(english, contains('İngilizce'));
      expect(
        turkish.replaceAll('Türkçe', '·'),
        english.replaceAll('İngilizce', '·'),
      );
    });

    /// Bilinmeyen kod sessizce Türkçeye düşmemeli — o, yanlış dilde bir yayını
    /// doğru görünen bir etiketle üretmek olurdu.
    test('bilinmeyen kod kodun kendisiyle yazılır', () {
      expect(summaryInstructionFor('ja'), contains('ja olarak'));
      expect(summaryInstructionFor('ja'), isNot(contains('Türkçe')));
    });

    test('istenen dil modele iletilir ve kayda damgalanır', () async {
      final summarizer = FakeSummarizer('A concise English summary.');
      final pass = await applySummaries(
        [_item()],
        summarizer: summarizer,
        language: 'en',
      );

      expect(summarizer.languages, ['en']);
      expect(pass.items.single.language, 'en');
      expect(pass.items.single.summaryOrigin, SummaryOrigin.generated);
    });

    /// Taşımanın en tehlikeli kaçağı: çıktı geçerli görünür, yalnız yanlış
    /// dildedir ve hiçbir kapı bunu yakalamaz — `summary_guard` sayı ve
    /// bağlantı karşılaştırıyor, dil bakmıyor.
    test('başka dildeki önceki özet taşınmaz', () async {
      final earlier = _item().withSummary(
        summary: 'Türkçe bir özet cümlesi.',
        summaryOrigin: SummaryOrigin.generated,
        language: 'tr',
        summarySourceHash: fnv1aHex(sourceTextOf(_item())),
      );

      final summarizer = FakeSummarizer('An English summary.');
      final pass = await applySummaries(
        [_item()],
        summarizer: summarizer,
        language: 'en',
        previous: [earlier],
      );

      expect(pass.carried, 0, reason: 'dil eşleşmiyor, taşınmamalı');
      expect(pass.summarized, 1);
      expect(pass.items.single.language, 'en');
      expect(pass.items.single.summary, 'An English summary.');
    });

    test('aynı dildeki önceki özet taşınır', () async {
      final earlier = _item().withSummary(
        summary: 'An English summary.',
        summaryOrigin: SummaryOrigin.generated,
        language: 'en',
        summarySourceHash: fnv1aHex(sourceTextOf(_item())),
      );

      final summarizer = FakeSummarizer('yeniden üretilmemeli');
      final pass = await applySummaries(
        [_item()],
        summarizer: summarizer,
        language: 'en',
        previous: [earlier],
      );

      expect(pass.carried, 1);
      expect(summarizer.languages, isEmpty, reason: 'model çağrılmamalı');
    });
  });
}
