import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/core/format.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// UCHINCHI TIL QO'RIQCHISI.
///
/// 🔴 Nima buzilgan edi (2026-08-16): ilova uchta tilni qo'llab-quvvatlaydi
/// va profilda "English" tanlash mumkin, lekin xato xabarlari va sana
/// formatlash `bool isUz` ga tayanardi — ya'ni "o'zbek emas = rus".
/// Ingliz tilini tanlagan odam HAR BIR xatoni va har bir sanani ruscha
/// ko'rardi, hech qanday xato ham chiqmasdi.
///
/// Bu test aynan shu holatni qotiradi: yangi til qo'shilganda yoki
/// `Lang` o'rniga yana ikkilik bayroq kiritilganda darhol yiqiladi.
void main() {
  /// Kirill harflari — ruscha matn ingliz tiliga "sizib o'tganini" aniqlash
  /// uchun eng ishonchli belgi.
  bool hasCyrillic(String s) => RegExp('[а-яА-ЯёЁ]').hasMatch(s);

  ApiException of(int status) => ApiException.from(
    DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
      ),
      type: DioExceptionType.badResponse,
    ),
  );

  group('xato xabarlari', () {
    test('inglizchada RUSCHA matn qaytmaydi', () {
      for (final status in [400, 401, 403, 404, 423, 429, 500, 503]) {
        final message = of(status).localized(Lang.en);
        expect(
          hasCyrillic(message),
          isFalse,
          reason: '$status uchun ruscha matn qaytdi: $message',
        );
        expect(message.trim(), isNotEmpty, reason: '$status uchun bo\'sh');
      }
    });

    test('uchala til uchun ham matn bor va bir-biridan farq qiladi', () {
      final uz = of(500).localized(Lang.uz);
      final ru = of(500).localized(Lang.ru);
      final en = of(500).localized(Lang.en);
      expect({uz, ru, en}.length, 3, reason: 'tillar takrorlanmasin');
    });
  });

  group('sana va davomiylik', () {
    test('inglizchada oy nomi inglizcha', () {
      final date = DateTime(DateTime.now().year, 8, 9);
      expect(formatDate(date, Lang.en), 'August 9');
      expect(formatDate(date, Lang.uz), '9 avgust');
      expect(formatDate(date, Lang.ru), '9 августа');
    });

    test('davomiylik birliklari tilga mos', () {
      const duration = Duration(hours: 4, minutes: 45);
      expect(formatDuration(duration, Lang.en), '4 h 45 min');
      expect(formatDuration(duration, Lang.uz), '4 soat 45 daqiqa');
      expect(formatDuration(duration, Lang.ru), '4 ч 45 мин');

      // KUNDAN OSHGAN ORALIQ — «139 soat» emas (10.09.2026).
      const late_ = Duration(hours: 139, minutes: 1);
      expect(formatDuration(late_, Lang.uz), '5 kun 19 soat');
      expect(formatDuration(late_, Lang.ru), '5 д 19 ч');
      expect(formatDuration(late_, Lang.en), '5 d 19 h');
      expect(formatDuration(const Duration(days: 2), Lang.uz), '2 kun');
    });
  });

  group('tarjima lug\'ati', () {
    /// `_(uz, ru, en)` uchala argumentni ham TALAB qiladi, lekin kimdir
    /// inglizcha o'rniga ruschani nusxalab qo'yishi mumkin. Eng ko'p
    /// ko'rinadigan satrlarni tekshiramiz.
    test('asosiy satrlar inglizchada kirillsiz', () {
      const t = AppStrings(Lang.en);
      for (final value in [
        t.searchTitle,
        t.bookButton,
        t.profileTitle,
        t.chatsTitle,
        t.notificationsTitle,
        t.splashTagline,
        t.welcomeFillProfile,
        t.newDeviceHint,
        t.rideCancelledTitle,
        t.pushDisabledTitle,
      ]) {
        expect(hasCyrillic(value), isFalse, reason: value);
      }
    });
  });
}
