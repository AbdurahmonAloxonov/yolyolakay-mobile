import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/rides/ride_share.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// ULASHILADIGAN HAVOLADAGI TIL PREFIKSI.
///
/// 🔴 NEGA BU SINOV BOR (16.09.2026, prodda o'lchab topildi):
/// `rideShareUrl` da `lang.name` ishlatilardi. Dart enum'ining nomi
/// `uzCyrl`, saytdagi til prefiksi esa `uz-cyrl` — ya'ni KIRILL
/// tilidagi odamning ulashgan havolasi O'LIK edi:
///
///     GET /uzCyrl/trip/{id}  → 307 → /uz/uzCyrl/trip/{id} → 404
///
/// Eng yomoni: bu «Safarimni kuzat» havolasiga ham tegishli edi, ya'ni
/// xavfsizlik funksiyasi aynan kirillda yuradigan odamda ishlamasdi.
///
/// Xato KO'RINMASDI — ilova havolani muvaffaqiyatli ulashardi, o'lik
/// ekani faqat qabul qilgan odamda bilinardi.
void main() {
  group('rideShareUrl — til prefiksi saytdagi bilan bir xil', () {
    // Sayt qabul qiladigan prefikslar (`shared/lib/i18n.ts` dagi
    // `LOCALES`). Katta-kichik harf muhim emas: sayt `uz-Cyrl` ni
    // `uz-cyrl` ga o'zi yo'naltiradi (prodda o'lchandi).
    const allowed = {'uz', 'uz-cyrl', 'ru', 'en'};

    for (final lang in Lang.values) {
      test('${lang.name} uchun prefiks yaroqli', () {
        final url = rideShareUrl('abc-123', lang);
        final prefix = Uri.parse(url).pathSegments.first;

        expect(
          allowed.contains(prefix.toLowerCase()),
          isTrue,
          reason:
              'Havolada «$prefix» prefiksi bor, sayt esa faqat $allowed ni '
              'biladi. Enum nomini (`lang.name`) manzilga qo\'ymang — '
              '`langCode(lang)` ishlating.',
        );
      });
    }

    test('kirill uchun AYNAN `uz-Cyrl` (enum nomi emas)', () {
      final url = rideShareUrl('abc-123', Lang.uzCyrl);
      expect(url, contains('/uz-Cyrl/'));
      expect(
        url,
        isNot(contains('uzCyrl/')),
        reason: 'Enum nomi manzilga tushib qolgan — havola 404 beradi.',
      );
    });

    test('safar id manzilda saqlanadi', () {
      expect(rideShareUrl('abc-123', Lang.uz), endsWith('/trip/abc-123'));
    });
  });
}
