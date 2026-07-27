import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/feed/summarize.dart';

String _body(List<Map<String, Object?>> content) =>
    jsonEncode({'id': 'msg_1', 'type': 'message', 'content': content});

void main() {
  group('Anthropic yanıtını ayrıştırma', () {
    test('metin bloğu okunur', () {
      expect(
        parseAnthropicText(
          _body([
            {'type': 'text', 'text': '  Kısa Türkçe özet.  '},
          ]),
        ),
        'Kısa Türkçe özet.',
      );
    });

    test('birden çok metin bloğu birleştirilir', () {
      expect(
        parseAnthropicText(
          _body([
            {'type': 'text', 'text': 'Birinci cümle. '},
            {'type': 'text', 'text': 'İkinci cümle.'},
          ]),
        ),
        'Birinci cümle. İkinci cümle.',
      );
    });

    /// Metin olmayan bloklar (`thinking` gibi) özete karışmamalı.
    test('metin olmayan bloklar atlanır', () {
      expect(
        parseAnthropicText(
          _body([
            {'type': 'thinking', 'thinking': 'iç düşünce'},
            {'type': 'text', 'text': 'Görünen özet.'},
          ]),
        ),
        'Görünen özet.',
      );
    });
  });

  /// Beklenmeyen bir biçimde `null` dönmeli: kayıt orijinal metniyle kalır.
  /// Tahmin edilmez, çökülmez.
  group('beklenmeyen biçim', () {
    test('JSON değilse null', () {
      expect(parseAnthropicText('bu JSON değil'), isNull);
      expect(parseAnthropicText(''), isNull);
    });

    test('nesne değilse null', () {
      expect(parseAnthropicText('[]'), isNull);
      expect(parseAnthropicText('"metin"'), isNull);
    });

    test('content listesi yoksa null', () {
      expect(parseAnthropicText('{"content": "metin"}'), isNull);
      expect(parseAnthropicText('{"error": {"type": "overloaded"}}'), isNull);
    });

    test('metin bloğu yoksa null', () {
      expect(parseAnthropicText(_body([])), isNull);
      expect(
        parseAnthropicText(
          _body([
            {'type': 'tool_use', 'name': 'x'},
          ]),
        ),
        isNull,
      );
    });

    test('boş metin null sayılır', () {
      expect(
        parseAnthropicText(
          _body([
            {'type': 'text', 'text': '   '},
          ]),
        ),
        isNull,
      );
    });
  });
}
