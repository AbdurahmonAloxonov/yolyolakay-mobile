import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// STATISTIKA MAXFIYLIK CHEGARASINI BUZMASINMI.
///
/// 🔴 NEGA BU TEST BOR: analitika o'z-o'zidan o'sadi. Bugun "shahar nomi"
/// yuboriladi, ertaga kimdir "ism ham qo'shsak yaxshi bo'lardi" deydi va
/// maxfiylik siyosatida va'da qilinganidan ko'proq ma'lumot chiqib ketadi.
/// Buni ko'z bilan payqash deyarli imkonsiz — hodisa jimgina yuboriladi.
///
/// Shuning uchun taqiqlangan maydonlar ro'yxati kodda qotirilgan.
/// Yangi hodisa qo'shayotganda test yiqilsa — payloadni qaytadan
/// o'ylab ko'ring, testni "tuzatmang".
void main() {
  test('analitika payloadida shaxsiy maydon YO\'Q', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    // Payload ichida uchramasligi kerak bo'lgan kalitlar.
    const forbidden = [
      "'name'",
      "'phone'",
      "'phone_number'",
      "'first_name'",
      "'last_name'",
      "'content'",
      "'message'",
      "'peer_name'",
      "'address'",
      "'origin_address'",
      "'destination_address'",
    ];

    final problems = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      var from = 0;
      while (true) {
        final start = src.indexOf('AnalyticsEvent.', from);
        if (start < 0) break;
        // Chaqiruvning taxminiy oxiri — keyingi `);`
        final end = src.indexOf(');', start);
        final call = src.substring(start, end < 0 ? src.length : end);
        for (final key in forbidden) {
          if (call.contains(key)) {
            problems.add('${file.path}: $key');
          }
        }
        from = start + 1;
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          'Analitika payloadiga shaxsiy maydon tushib qolgan:\n'
          '${problems.join('\n')}\n'
          'Maxfiylik siyosatida faqat shahar, son va ID va\'da qilingan.',
    );
  });
}
