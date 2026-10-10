import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// EDGE-TO-EDGE QO'RIQCHISI (Android 15+ / targetSdk 36).
///
/// 🔴 NIMA GAP: Android 15 dan boshlab tizim ilovani MAJBURAN "edge-to-edge"
/// rejimida chizadi — kontent status paneli va imo-ishora paneli OSTIGA ham
/// yoyiladi. targetSdk 35 da buni `windowOptOutEdgeToEdgeEnforcement` bilan
/// o'chirish mumkin edi; **targetSdk 36 da bu opt-out ISHLAMAYDI**. Bizda
/// targetSdk 36, ya'ni tanlov yo'q — insetlarni o'zimiz hisobga olishimiz
/// shart. Play Console ham buni ogohlantirish sifatida ko'rsatib turibdi.
///
/// Flutter 3.44 da rejim O'ZI yoqiladi, `SystemChrome` chaqirig'i kerak emas.
/// `Scaffold` + `AppBar` + M3 `NavigationBar` ham insetlarni o'zi qoplaydi.
/// QOPLAMAYDIGAN yagona joy — pastdan chiqadigan varaqlar
/// (`showModalBottomSheet`): ular default'da `useSafeArea: false` bilan
/// ochiladi va varaqning eng pastki tugmasi imo-ishora paneli ostida qolib,
/// bosib bo'lmaydigan bo'lib qoladi.
///
/// 2026-08-19 da 10 ta varaqdan 8 tasi aynan shunday edi — eng xavflisi
/// SOS varaqi ("102 ga qo'ng'iroq" tugmasi). Bu test o'shanga qaytmaslik
/// uchun.
///
/// NEGA TEST: buni qurilmasiz ko'rib bo'lmaydi. Yangi varaq qo'shgan odam
/// (yoki men) buni sezmaydi — emulyatorda gesture-navigatsiya yoqilmagan
/// bo'lsa muammo umuman ko'rinmaydi ham.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('har bir showModalBottomSheet da useSafeArea: true bor', () {
    final violations = <String>[];

    /// IZOHLARNI OLIB TASHLAYDI — kodni qidirishdan oldin.
    ///
    /// 🔴 NEGA KERAK (10.09.2026): bu qo'riqchi XOM MATNNI qidirardi.
    /// `theme.dart` ga varaq temasi qo'shilib, uning izohida
    /// `showModalBottomSheet` so'zi YOZILGANDA test yiqildi — u
    /// izohdagi so'zni chaqiruv deb o'qidi va keyingi qavsni tekshirdi.
    ///
    /// Ya'ni qo'riqchi API haqida HUJJAT yozishni taqiqlab qo'yardi.
    /// Izoh — kod emas: uni o'chirib, keyin qidiramiz. Qatorlar soni
    /// saqlanadi (izoh o'rniga bo'shliq qo'yiladi), shunda xato
    /// xabaridagi qator raqami to'g'ri qoladi.
    String stripComments(String src) {
      final out = StringBuffer();
      var i = 0;
      while (i < src.length) {
        if (src.startsWith('//', i)) {
          while (i < src.length && src[i] != '\n') {
            out.write(' ');
            i++;
          }
        } else if (src.startsWith('/*', i)) {
          final end = src.indexOf('*/', i + 2);
          final stop = end == -1 ? src.length : end + 2;
          for (var k = i; k < stop; k++) {
            out.write(src[k] == '\n' ? '\n' : ' ');
          }
          i = stop;
        } else {
          out.write(src[i]);
          i++;
        }
      }
      return out.toString();
    }

    for (final file in dartFiles) {
      final source = stripComments(file.readAsStringSync());
      if (!source.contains('showModalBottomSheet')) continue;

      // Chaqiruvning ochilish qavsidan boshlab mos yopilish qavsigacha bo'lgan
      // bo'lakni olamiz — ichida `useSafeArea` bormi, shuni tekshiramiz.
      // Oddiy qator-bo'yicha qidiruv yetmaydi: parametrlar bir necha qatorga
      // yoyilgan va ular orasida boshqa chaqiruvlar ham bo'lishi mumkin.
      var index = source.indexOf('showModalBottomSheet');
      while (index != -1) {
        final open = source.indexOf('(', index);
        if (open == -1) break;

        var depth = 0;
        var end = open;
        for (var i = open; i < source.length; i++) {
          if (source[i] == '(') depth++;
          if (source[i] == ')') {
            depth--;
            if (depth == 0) {
              end = i;
              break;
            }
          }
        }

        // ⚠️ IZOHLAR OLIB TASHLANADI. Bu tekshiruv birinchi yozilishida
        // shunchaki `contains('useSafeArea')` edi va u HAR DOIM o'tardi:
        // parametr yonidagi izohning o'zida ham shu so'z bor. Ya'ni qo'riqchi
        // hech qachon yiqilmasdi — bu qo'riqchi yo'qligidan ham yomonroq,
        // chunki "tekshirilgan" degan yolg'on tuyg'u beradi.
        final call = source
            .substring(open, end)
            .replaceAll(RegExp(r'//[^\n]*'), '');
        if (!RegExp(r'useSafeArea:\s*true').hasMatch(call)) {
          final line = '\n'.allMatches(source.substring(0, index)).length + 1;
          violations.add('${file.path}:$line');
        }

        index = source.indexOf('showModalBottomSheet', end);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Bu varaqlarda `useSafeArea: true` yo\'q — Android 15+ da pastki '
          'tugma imo-ishora paneli ostida qoladi:\n  ${violations.join('\n  ')}',
    );
  });

  test('targetSdk edge-to-edge dan opt-out qilmaydi', () {
    // `windowOptOutEdgeToEdgeEnforcement` targetSdk 36 da baribir e'tiborsiz
    // qoldiriladi. Uni qo'shish "muammo hal bo'ldi" degan YOLG'ON tuyg'u
    // beradi — shuning uchun umuman bo'lmasin.
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    if (!manifest.existsSync()) return;

    expect(
      manifest.readAsStringSync(),
      isNot(contains('OptOutEdgeToEdge')),
      reason:
          'targetSdk 36 da bu bayroq ISHLAMAYDI. Insetlar kod tomonda '
          'hisobga olinishi kerak (SafeArea / useSafeArea).',
    );
  });
}
