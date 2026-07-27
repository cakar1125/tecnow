/// AI özetleri için doğrulama kapısı.
///
/// `docs/CONTENT_TRUST_POLICY.md`: *"AI, kaynakta olmayan sayı, benchmark,
/// fiyat veya özellik ekleyemez."* Bu dosya o cümleyi ölçülebilir bir kurala
/// çevirir ve üretici (`tool/feed/`) her AI özetini yayımlamadan önce buradan
/// geçirir.
///
/// Kapı **tek yönlü güvenlidir**: şüphede kalırsa reddeder. Reddedilen özet
/// atılır ve kayıt orijinal açıklamasıyla yayımlanır — yani en kötü durumda
/// içerik İngilizce kalır, asla uydurulmuş olmaz.
library;

enum SummaryRejection {
  empty,
  tooLong,

  /// Özette kaynakta bulunmayan bir sayı var (benchmark, fiyat, parametre).
  unsourcedNumber,

  /// Özette kaynakta bulunmayan bir bağlantı var.
  unsourcedLink,
}

final class SummaryVerdict {
  const SummaryVerdict.accepted() : rejection = null, detail = null;
  const SummaryVerdict.rejected(this.rejection, [this.detail]);

  final SummaryRejection? rejection;

  /// Reddi tetikleyen somut değer — üretici günlüğünde görünür, böylece
  /// "neden İngilizce kaldı" sorusu cevaplanabilir olur.
  final String? detail;

  bool get isAccepted => rejection == null;
}

/// Özet üst sınırı. Kaynağın yerini almak değil, ona yönlendirmek istiyoruz.
const summaryMaxLength = 400;

/// Metindeki sayıları karşılaştırılabilir biçime indirger.
///
/// `1,5` ve `1.5` aynı sayıdır; `70B` içindeki `70` de bir sayıdır. Baştaki
/// sıfırlar ve ayraçlar atılır ki `1,000` ile `1000` eşleşsin.
Set<String> extractNumbers(String text) {
  final matches = RegExp(r'\d[\d.,]*').allMatches(text);
  final numbers = <String>{};
  for (final match in matches) {
    final raw = match.group(0)!;
    // Sondaki ayraçlar cümle noktalaması olabilir: "sürüm 2." -> "2"
    final trimmed = raw.replaceAll(RegExp(r'[.,]+$'), '');
    // Binlik/ondalık ayraçlarını at: 1,000 -> 1000 · 1.5 -> 15
    final digits = trimmed.replaceAll(RegExp(r'[.,]'), '');
    final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (normalized.isNotEmpty) numbers.add(normalized);
  }
  return numbers;
}

Set<String> _extractLinks(String text) => RegExp(r'https?://\S+')
    .allMatches(text)
    .map((match) => match.group(0)!.replaceAll(RegExp(r'[).,]+$'), ''))
    .toSet();

/// Özeti kaynağa karşı doğrular.
///
/// [sourceText] **yalnızca başlık ve açıklamadır**; yayın tarihi, kimlik,
/// yıldız sayısı gibi makine alanları buraya konmaz ve modele de verilmez.
///
/// Bunun sebebi somut: `2026-07-20` gibi bir tarih metne katılırsa izin
/// verilen sayı havuzuna `2026`, `7` ve `20` girer ve uydurulmuş bir
/// *"aylık 20 dolar"* ifadesi kapıdan geçer. Tarihi arayüz zaten ayrı
/// gösteriyor; özetin onu tekrar etmesine gerek yok.
///
/// Bilinen yanlış-pozitif: kaynakta "seven billion" yazıp özette "7 milyar"
/// denirse sayı kaynakta rakamla geçmediği için özet reddedilir. Bu, ters
/// yönde hata yapmaktan (uydurulmuş sayıyı yayımlamak) yeğdir.
SummaryVerdict verifySummary({
  required String summary,
  required String sourceText,
}) {
  final trimmed = summary.trim();
  if (trimmed.isEmpty) {
    return const SummaryVerdict.rejected(SummaryRejection.empty);
  }
  if (trimmed.length > summaryMaxLength) {
    return SummaryVerdict.rejected(
      SummaryRejection.tooLong,
      '${trimmed.length} karakter, sınır $summaryMaxLength',
    );
  }

  final sourceNumbers = extractNumbers(sourceText);
  for (final number in extractNumbers(trimmed)) {
    if (!sourceNumbers.contains(number)) {
      return SummaryVerdict.rejected(SummaryRejection.unsourcedNumber, number);
    }
  }

  final sourceLinks = _extractLinks(sourceText);
  for (final link in _extractLinks(trimmed)) {
    if (!sourceLinks.contains(link)) {
      return SummaryVerdict.rejected(SummaryRejection.unsourcedLink, link);
    }
  }

  return const SummaryVerdict.accepted();
}
