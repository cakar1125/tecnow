/// Türkçe tecOS özeti — **derleme zamanı**.
///
/// Uygulama AI'a hiç dokunmaz: anahtar burada, üreticinin ortam değişkeninde
/// durur ve mobil pakete girmez. Üretilen özet feed'e **metin olarak** iner.
///
/// Katman iki durumda da doğru çalışmak zorunda:
/// * **Anahtar yok** → hiç çağrı yapılmaz, her kayıt kaynağın kendi metniyle
///   ([SummaryOrigin.original]) yayımlanır. Anahtar bir kolaylıktır, koşul
///   değil; feed anahtarsız da eksiksiz üretilir.
/// * **Anahtar var** → özet üretilir, `summary_guard`'dan geçirilir ve ancak
///   geçerse kullanılır. Reddedilen özet atılır, kayıt orijinal açıklamasıyla
///   kalır. En kötü durumda içerik İngilizce kalır; asla uydurulmuş olmaz.
library;

import 'dart:convert';
import 'dart:io';

import 'package:tecos/data/feed/feed_schema.dart';

import 'summary_guard.dart';

/// Modelin gördüğü tek şey başlık ve kaynağın kendi açıklamasıdır.
///
/// Tarih, kimlik, yıldız sayısı gibi makine alanları **verilmez** — sebebi
/// `summary_guard.dart` içinde ölçülmüş hâliyle yazılı: tarih metne girerse
/// izin verilen sayı havuzu genişler ve uydurulmuş bir fiyat kapıdan geçer.
String sourceTextOf(FeedItem item) => '${item.title}\n${item.summary}';

abstract interface class Summarizer {
  /// [language] dilinde özet döndürür; üretemezse `null`.
  ///
  /// `null` bir hata değildir: "bu kayıt için özet yok" demektir ve kayıt
  /// orijinal metniyle yayımlanır.
  ///
  /// Dil **çağrı başına** verilir, sağlayıcının kurucusunda değil. İki yerde
  /// durabilirdi ama o zaman iki gerçek kaynağı olurdu: [applySummaries]'in
  /// damgaladığı dil ile modelin yazdığı dil ayrışabilir ve çıktı geçerli
  /// görünüp yanlış etiketli olurdu.
  Future<String?> summarize({
    required String title,
    required String sourceText,
    required String language,
  });
}

/// Anahtar yokken kullanılan. Hiçbir çağrı yapmaz.
final class DisabledSummarizer implements Summarizer {
  const DisabledSummarizer();

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
    required String language,
  }) async => null;
}

/// Yönergede kullanılacak dil adları.
///
/// Kaynaklar (GitHub, Hugging Face, resmi bloglar) evrensel ve İngilizce;
/// hedef dil **kaynağın bir özelliği değil, üretimin bir parametresi**. Bu
/// tablo o parametrenin insan tarafından okunabilir karşılığı.
///
/// Bilinmeyen kod, kodun kendisiyle yazılır. Zayıf ama sessiz değil: yeni bir
/// dil gerçekten yayınlanacaksa adı buraya eklenmeli.
const summaryLanguageNames = <String, String>{
  'tr': 'Türkçe',
  'en': 'İngilizce',
  'de': 'Almanca',
  'fr': 'Fransızca',
  'es': 'İspanyolca',
  'ar': 'Arapça',
};

/// Modele verilen yönerge — **sağlayıcıdan bağımsız**.
///
/// Kısıtlayıcıdır: kapı ([verifySummary]) zaten uydurma sayıyı reddediyor, ama
/// reddedilen her özet boşa harcanmış bir çağrıdır.
///
/// Tek yerde durması şart: iki sağlayıcı iki ayrı yönergeyle çalışsaydı,
/// aralarındaki kalite karşılaştırması modeli değil yönergeyi ölçerdi.
///
/// Dil dışında **hiçbir şey** değişmez. İki dilin özetleri arasındaki farkın
/// yönergeden değil modelden gelmesi, kalitenin dil başına ölçülebilmesinin
/// koşulu.
String summaryInstructionFor(String language) {
  final name = summaryLanguageNames[language] ?? language;
  return 'Aşağıdaki teknoloji duyurusunu $name olarak en fazla iki cümlede '
      'özetle. Kaynakta geçmeyen hiçbir sayı, oran, fiyat, ölçüt ya da '
      'bağlantı ekleme. Yorum katma, tanıtım dili kullanma. Yalnızca özeti '
      'yaz, başka hiçbir şey yazma.';
}

/// İstek gövdesini **UTF-8 bayt dizisi** olarak kodlar.
///
/// `HttpClientRequest.write(String)` kullanılmıyor ve kullanılamaz: o metot
/// gövdeyi `request.encoding` ile kodluyor, varsayılanı **Latin-1** ve
/// yönergemiz Türkçe. `ş`, `ğ`, `ı` Latin-1'de yok.
///
/// Ölçüldü (2026-08-12, gerçek NVIDIA uç noktası, `tool/measure_summaries.dart`):
/// beş çağrının **beşi de** düştü —
/// `Invalid argument (string): Contains invalid characters.`
///
/// Kusurun asıl kötülüğü sessizliğiydi. Çağrı hatası kaydı düşürüyor, koşuyu
/// değil (`applySummaries` → `failed++`), yani anahtar eklenmiş olsaydı yayın
/// **başarıyla** tamamlanır, 200 kaydın 200'ü İngilizce kalır ve hiçbir kapı
/// bir şey söylemezdi. Kodun kendi başlığı bunu önceden yazmıştı: *"Bu sınıfın
/// canlı yolu ölçülmedi."* Ölçülmemiş yol, çalışan yol değildir.
///
/// Başlık da düzeltildi (`charset=utf-8`): `add` zaten baytı olduğu gibi
/// gönderiyor ama sunucuya gövdenin hangi kodlamada olduğunu söylemek onun
/// işi değil, bizim işimiz.
List<int> encodeRequestBody(Map<String, Object?> json) =>
    utf8.encode(jsonEncode(json));

/// Bir koşuda yapılacak en fazla **yeni** çağrı.
///
/// Sınır aşıldığında kalan kayıtlar orijinal metinleriyle kalır — koşu
/// **başarısız olmaz**.
///
/// Sayının anlamı 3 Ağustos 2026'da değişti. Eskiden 60'tı ve gerekçesi "her
/// koşuda her kaydı yeniden özetlemek gereksiz masraftır" idi — ama o israfın
/// asıl sebebi bütçe değil, **taşımanın olmamasıydı**: üretici feed'i her
/// koşuda yeniden kurduğu için geçen koşunun Türkçe özetleri kayboluyor ve
/// bütçe aynı işi tekrar satın almaya gidiyordu. Ölçüldü: yayımlanan 200
/// kaydın 180'i İngilizce kalmıştı.
///
/// Taşıma ([applySummaries] → `previous`) israfı bitirdi, bu yüzden sınır
/// artık bir **maliyet kapısı** değil, kaçak durumlar için bir tavan. 120
/// seçildi çünkü: (a) 180 kayıtlık birikim iki koşuda kapanır, (b) kararlı
/// durumda gerçek çağrı sayısı yalnız **yeni** kayıtlar kadar olacağı için bu
/// tavana zaten yaklaşılmaz.
///
/// **(b)'nin eski üçüncü maddesi ölçümle düştü.** "NVIDIA'nın 40 istek/dakika
/// sınırı için gereken 1,5 sn aralıkla en kötü durum ~3 dakikadır" yazıyordu;
/// o hesap çağrının kendisini **anlık** varsayıyordu. Ölçüldü (2026-08-12,
/// `meta/llama-3.3-70b-instruct`, beş çağrı): **7.757 – 19.362 ms**, ortanca
/// ~16 sn. Yani gerçek hız ~4 çağrı/dakika ve 1,5 sn'lik nezaket aralığı
/// hiçbir zaman devreye girmiyor — sınırın çok altındayız.
///
/// Sonucu: 120 çağrılık bir koşu ~30 dakika sürer, 3 değil. Saatlik cron için
/// sorun değil ve yalnız ilk iki koşuda görülür (birikim kapandıktan sonra
/// çağrı sayısı yeni kayıtlar kadar). Hızlandırmak gerekirse yol eşzamanlılık:
/// beş çağrı paralel ~40/dakika eder ve **tam** sınıra dayanır — o yüzden
/// ölçülmeden yapılmamalı.
const defaultSummaryBudget = 120;

final class SummaryPass {
  const SummaryPass({
    required this.items,
    this.summarized = 0,
    this.carried = 0,
    this.rejected = const {},
    this.failed = 0,
    this.budgetExhausted = false,
    this.firstFailure,
    this.abandoned = false,
  });

  final List<FeedItem> items;

  /// Kapıdan geçip Türkçeye çevrilen kayıt sayısı.
  final int summarized;

  /// Önceki yayından **taşınan** özet sayısı — model çağrılmadan.
  final int carried;

  /// Reddedilen özetler, sebebiyle. "Neden İngilizce kaldı" sorusunun cevabı.
  final Map<SummaryRejection, int> rejected;

  /// Model çağrısı hata verdi. Kayıt orijinal metniyle kaldı.
  final int failed;

  final bool budgetExhausted;

  /// İlk çağrı hatasının türü ve mesajı — kısaltılmış.
  ///
  /// Sayı tek başına teşhis etmiyor. 14 Ağustos 2026'da bir koşu **120 çağrı
  /// hatası** bildirdi ve sebebi hiçbir yerde yazmadığı için 401 mi, 429 mu,
  /// zaman aşımı mı olduğu ancak koşu süresinden (60 dakika ÷ 120 ≈ 30 sn =
  /// zaman aşımı) çıkarılabildi. Kusurun kendisi değil, **sessizliği** pahalı.
  ///
  /// Anahtar sızdırmamak için mesaj 200 karaktere kırpılıyor: sağlayıcı hata
  /// gövdesinde isteği yansıtabilir.
  final String? firstFailure;

  /// Sağlayıcı düştüğü için özet katmanı **erken bırakıldı**.
  final bool abandoned;
}

/// Üst üste bu kadar hata gelirse sağlayıcı düşmüş sayılır ve kalan çağrılar
/// yapılmaz.
///
/// Tek tek hatalar normaldir — bir kaydın metni modeli rahatsız edebilir.
/// Ama arka arkaya beş hata artık kayıtla ilgili değildir: anahtar, kota ya
/// da ağ. O noktadan sonra denemeye devam etmek hiçbir şeyi kurtarmıyor,
/// yalnız koşuyu uzatıyor — 14 Ağustos'ta tam olarak bu oldu ve **bir saat**
/// harcandı. Beş, gerçek bir arıza ile tesadüfi bir dizi arasındaki makul
/// ayrım; düşürülürse geçici bir dalgalanma katmanı kapatır.
const summaryFailureStreakLimit = 5;

/// Özet katmanını uygular.
///
/// Yalnız [SummaryOrigin.original] taşıyan kayıtlar adaydır: tecOS'un
/// kendi kurduğu cümleler (Hugging Face yapısal özeti) zaten Türkçedir ve
/// yeniden özetlenmez.
///
/// [previous] verilirse **taşıma** devreye girer: bir kaydın kimliği önceki
/// yayında varsa ve o kayıt aynı kaynak metinden üretilmiş bir tecOS özeti
/// taşıyorsa, özet olduğu gibi alınır ve **model çağrılmaz**.
///
/// Bu bir hız iyileştirmesi değil, bir kusurun düzeltilmesi: üretici feed'i her
/// koşuda kaynaklardan yeniden kuruyor, yani geçen koşuda Türkçeleştirilmiş bir
/// kayıt bu koşuda yine `original` olarak geliyordu. Bütçe her seferinde aynı
/// işi tekrar satın almaya harcanıyor, kuyruktaki kayıtlar hiç sıra
/// alamıyordu. Ölçüldü (2026-08-03): yayımlanan 200 kaydın 180'i İngilizceydi.
Future<SummaryPass> applySummaries(
  List<FeedItem> items, {
  required Summarizer summarizer,
  String language = 'tr',
  int budget = defaultSummaryBudget,
  List<FeedItem> previous = const [],
}) async {
  final result = <FeedItem>[];
  final rejected = <SummaryRejection, int>{};
  var summarized = 0;
  var carried = 0;
  var failed = 0;
  var calls = 0;
  var failureStreak = 0;
  String? firstFailure;
  var abandoned = false;

  // Yalnız taşınabilir olanlar: tecOS özeti **ve** damgası olanlar.
  // Damgasız bir kayıt eski bir sürümden gelmiş olabilir; kaynak metninin
  // değişip değişmediği bilinemeyeceği için taşınmaz.
  //
  // Dil de eşleşmeli. Dosya başına tek dil yayınlandığı için normalde zaten
  // eşleşir, ama hedef dil değiştirildiğinde (ya da yanlış `--previous`
  // verildiğinde) eşleşmeseydi taşıma, İngilizce bir dosyaya Türkçe özetleri
  // **sessizce** doldururdu. Sessiz olması burada asıl tehlike: çıktı geçerli
  // görünür, yalnız yanlış dildedir.
  final carryable = {
    for (final item in previous)
      if (item.summaryOrigin == SummaryOrigin.generated &&
          item.summarySourceHash != null &&
          item.language == language)
        item.id: item,
  };

  for (final item in items) {
    if (item.summaryOrigin != SummaryOrigin.original) {
      result.add(item);
      continue;
    }

    final sourceText = sourceTextOf(item);
    final sourceHash = fnv1aHex(sourceText);

    // Taşıma bütçeden **düşmez**: harcanan bir çağrı yok.
    final earlier = carryable[item.id];
    if (earlier != null && earlier.summarySourceHash == sourceHash) {
      // Kapı yeniden çalıştırılır. Özet üretildiğinde geçmişti, ama kapının
      // kuralları o günden bu yana sıkılaşmış olabilir; taşımak, yeni kuralı
      // sessizce atlamak anlamına gelmemeli.
      final carriedVerdict = verifySummary(
        summary: earlier.summary,
        sourceText: sourceText,
      );
      if (carriedVerdict.isAccepted) {
        carried++;
        result.add(
          item.withSummary(
            summary: earlier.summary,
            summaryOrigin: SummaryOrigin.generated,
            language: earlier.language,
            summarySourceHash: sourceHash,
          ),
        );
        continue;
      }
      // Kapıdan düştü: taşıma yok, aşağıdaki normal yol yeniden üretmeyi dener.
    }

    if (calls >= budget || abandoned) {
      result.add(item);
      continue;
    }

    String? generated;
    try {
      calls++;
      generated = await summarizer.summarize(
        title: item.title,
        sourceText: sourceText,
        language: language,
      );
      failureStreak = 0;
    } catch (error) {
      // Model çağrısı bir kaydı düşürebilir, koşuyu değil.
      failed++;
      failureStreak++;
      firstFailure ??= describeSummaryFailure(error);
      if (failureStreak >= summaryFailureStreakLimit) abandoned = true;
      result.add(item);
      continue;
    }

    if (generated == null) {
      result.add(item);
      continue;
    }

    final verdict = verifySummary(summary: generated, sourceText: sourceText);
    if (!verdict.isAccepted) {
      rejected.update(
        verdict.rejection!,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      result.add(item);
      continue;
    }

    summarized++;
    result.add(
      item.withSummary(
        summary: generated.trim(),
        summaryOrigin: SummaryOrigin.generated,
        language: language,
        // Bir sonraki koşu bu damgaya bakıp özeti yeniden satın almayacak.
        summarySourceHash: sourceHash,
      ),
    );
  }

  return SummaryPass(
    items: result,
    summarized: summarized,
    carried: carried,
    rejected: rejected,
    failed: failed,
    budgetExhausted: calls >= budget,
    firstFailure: firstFailure,
    abandoned: abandoned,
  );
}

/// Çağrı hatasını tek satıra indirir: **tür + kısaltılmış mesaj**.
///
/// Tür tek başına yetmiyor — `HttpException` hem 401 hem 429 hem 500 olabilir
/// ve üçünün cevabı farklı. Mesaj da tek başına yetmiyor: zaman aşımı boş
/// mesajlı bir `TimeoutException` olarak geliyor ve o boşluk teşhisin
/// kendisi.
///
/// 200 karakter sınırı bir nezaket değil güvenlik: sağlayıcılar hata
/// gövdesinde isteği yansıtabiliyor ve bu çıktı koşu loguna yazılıyor.
String describeSummaryFailure(Object error) {
  final text = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  final clipped = text.length > 200 ? '${text.substring(0, 200)}…' : text;
  return '${error.runtimeType}: $clipped';
}

/// Anthropic Messages API ile özetler.
///
/// **Bu sınıfın canlı yolu ölçülmedi**: geliştirme sırasında elde anahtar
/// yoktu. Anahtarsız yol, doğrulama kapısı ve reddedilen özetin orijinale
/// düşmesi test altındadır; gerçek API yanıtı değildir. İlk anahtarlı koşuda
/// çıktı gözle doğrulanmalı.
final class AnthropicSummarizer implements Summarizer {
  AnthropicSummarizer({
    required this.apiKey,
    this.model = 'claude-haiku-4-5-20251001',
    this.timeout = const Duration(seconds: 30),
  });

  /// Ortam değişkeninden gelir. Depoya yazılmaz, uygulamaya gömülmez.
  final String apiKey;

  /// Kısa metinlerin toplu özeti için en ucuz uygun model.
  final String model;

  final Duration timeout;

  static final _endpoint = Uri.https('api.anthropic.com', '/v1/messages');

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
    required String language,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final payload = encodeRequestBody({
        'model': model,
        'max_tokens': 300,
        'messages': [
          {
            'role': 'user',
            'content': '${summaryInstructionFor(language)}\n\n$sourceText',
          },
        ],
      });

      final request = await client.postUrl(_endpoint);
      request.headers
        ..set('x-api-key', apiKey)
        ..set('anthropic-version', '2023-06-01')
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request
        ..contentLength = payload.length
        ..add(payload);

      final response = await request.close().timeout(timeout);
      // Gövde okuması da sınırlı. `close()` yalnız **başlıkların** geldiğini
      // söylüyor; başlıklar gelip gövde yarıda kalırsa bu `await` süresiz
      // beklerdi ve iş akışının varsayılan sınırı 6 saat.
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('Anthropic API ${response.statusCode}: $body');
      }
      return parseAnthropicText(body);
    } finally {
      client.close(force: true);
    }
  }
}

/// Anthropic yanıtından metni çıkarır.
///
/// Üst düzey ve genel: canlı çağrıyı test edemiyoruz ama **ayrıştırmayı**
/// edebiliriz, ve gerçek bir hatanın oluşabileceği yer burası. Beklenmeyen bir
/// biçimde `null` döner — kayıt orijinal metniyle kalır, tahmin edilmez.
String? parseAnthropicText(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final content = decoded['content'];
  if (content is! List) return null;

  final buffer = StringBuffer();
  for (final block in content) {
    // `thinking` gibi metin olmayan bloklar atlanır; yalnız `text` alınır.
    if (block is Map && block['type'] == 'text' && block['text'] is String) {
      buffer.write(block['text']);
    }
  }
  final text = buffer.toString().trim();
  return text.isEmpty ? null : text;
}

/// NVIDIA NIM ile özetler — **OpenAI uyumlu** uç.
///
/// [AnthropicSummarizer]'ın aynadaki ikizi: aynı yönerge, aynı sözleşme, farklı
/// uç ve farklı yanıt biçimi. Kapı ([verifySummary]) modelden bağımsız
/// çalıştığı için sağlayıcı eklemek güvenliği değiştirmez.
///
/// **Model seçimi ölçümle yapılır, buradaki değer yalnız başlangıç noktasıdır.**
/// Türkçe özet kalitesi modele göre belirgin değişir ve bunu tahmin etmek
/// yanlış olur; karşılaştırma yöntemi `summary_guard`'ın ret oranıdır.
/// `NVIDIA_MODEL` ortam değişkeniyle kod değiştirmeden denenebilir.
///
/// **Bu sınıfın canlı yolu ölçülmedi** — [AnthropicSummarizer] ile aynı durum.
/// Ayrıştırma ([parseOpenAiText]) ayrı ve test edilebilir tutuldu.
final class NvidiaSummarizer implements Summarizer {
  NvidiaSummarizer({
    required this.apiKey,
    this.model = 'meta/llama-3.3-70b-instruct',
    this.timeout = const Duration(seconds: 90),
    this.minimumInterval = const Duration(milliseconds: 1500),
  });

  /// Ortam değişkeninden gelir. Depoya yazılmaz, uygulamaya gömülmez.
  final String apiKey;
  final String model;

  /// Bir çağrının en fazla ne kadar sürebileceği.
  ///
  /// **30 saniyeydi ve ölçümle yetersiz çıktı.** 15 Ağustos 2026, koşu #141:
  /// beş çağrının beşi de `TimeoutException after 0:00:30` ile düştü.
  ///
  /// Sebebi uç noktanın biçiminde: akış (streaming) kullanılmıyor, yani yanıt
  /// başlıkları **üretim tamamen bittikten sonra** geliyor. Ölçülen süre bu
  /// yüzden ağ gecikmesi değil, 70 milyarlık bir modelin 300 jetona kadar
  /// üretim süresi. Yerel ölçümde (12 Ağustos, 5 çağrı) medyan ~16 sn, en
  /// yavaşı 19,4 sn'ydi — sınıra yalnız 10 saniye vardı. Paylaşımlı ücretsiz
  /// katmanda kuyruk bunu aşıyor.
  ///
  /// 90 saniye bir tahmin ve öyle olduğu biliniyor. Tahminin maliyeti
  /// [summaryFailureStreakLimit] ile sınırlı: yanlışsa koşu 5 × 90 sn = 7,5
  /// dakika kaybeder, bir saat değil.
  final Duration timeout;

  /// İki çağrı arasındaki en kısa süre.
  ///
  /// Ücretsiz katman **dakikada 40 istek** veriyor; 1,5 sn aralık dakikada 40
  /// çağrı demek. Sınır aşılırsa 429 gelir ve o kayıtlar İngilizce kalırdı —
  /// yani hız sınırlaması bir nezaket değil, kapsamın koşulu.
  final Duration minimumInterval;

  static final _endpoint = Uri.https(
    'integrate.api.nvidia.com',
    '/v1/chat/completions',
  );

  DateTime? _lastCall;

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
    required String language,
  }) async {
    await _pace();

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final payload = encodeRequestBody({
        'model': model,
        'max_tokens': 300,
        // Özet yaratıcılık işi değil; düşük sıcaklık uydurmayı azaltır ve
        // kapının ret oranını düşürür.
        'temperature': 0.2,
        'messages': [
          {
            'role': 'user',
            'content': '${summaryInstructionFor(language)}\n\n$sourceText',
          },
        ],
      });

      final request = await client.postUrl(_endpoint);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request
        ..contentLength = payload.length
        ..add(payload);

      final response = await request.close().timeout(timeout);
      // Gövde okuması da sınırlı. `close()` yalnız **başlıkların** geldiğini
      // söylüyor; başlıklar gelip gövde yarıda kalırsa bu `await` süresiz
      // beklerdi ve iş akışının varsayılan sınırı 6 saat.
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('NVIDIA API ${response.statusCode}: $body');
      }
      return parseOpenAiText(body);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _pace() async {
    final last = _lastCall;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < minimumInterval) {
        await Future<void>.delayed(minimumInterval - elapsed);
      }
    }
    _lastCall = DateTime.now();
  }
}

/// OpenAI uyumlu yanıttan metni çıkarır (`choices[0].message.content`).
///
/// [parseAnthropicText] ile aynı sözleşme: beklenmeyen bir biçimde `null` döner
/// ve kayıt orijinal metniyle kalır. Tahmin edilmez.
String? parseOpenAiText(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final first = choices.first;
  if (first is! Map) return null;
  final message = first['message'];
  if (message is! Map) return null;
  final content = message['content'];
  if (content is! String) return null;
  final text = content.trim();
  return text.isEmpty ? null : text;
}

/// Sağlayıcıları **sırayla** dener: ilki çökerse ikinciye geçer.
///
/// Desen yeni değil — feed adresi failover'ının (`SyncingFeedRepository`) aynısı
/// ve aynı dersi taşıyor: ilk hata saklanır, hepsi çökerse geri verilir.
///
/// **Yalnız fırlatılan istisna zincirde ilerletir.** `null` bir hata değil,
/// "bu kayıt için özet yok" demektir; onu yedeğe taşımak, bilerek özet
/// üretmeyen bir sağlayıcının kararını ezmek olurdu.
///
/// Kapı reddi de zinciri **ilerletmez**. İkinci bir modeli denemek cazip ama
/// çağrıyı ikiye katlar ve bugünkü davranışı (kayıt orijinal kalır) değiştirir;
/// bilinçli olarak dışarıda bırakıldı.
final class FallbackSummarizer implements Summarizer {
  const FallbackSummarizer(this.providers);

  final List<Summarizer> providers;

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
    required String language,
  }) async {
    Object? firstFailure;
    for (final provider in providers) {
      try {
        return await provider.summarize(
          title: title,
          sourceText: sourceText,
          language: language,
        );
      } catch (error) {
        firstFailure ??= error;
      }
    }
    if (firstFailure != null) throw firstFailure;
    // Sağlayıcı yok: hiç çağrı yapılmamış demektir, hata değil.
    return null;
  }
}
