import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bildirishnoma kanali UCH joyda e'lon qilinadi va uchalasi AYNAN bir xil
/// bo'lishi shart.
///
/// 🔴 NEGA TEST KERAK: bu xato ikki marta chiqdi va ikkalasida ham
/// `flutter analyze` jim turdi — bog'lanish kod orqali emas, SATR orqali.
///
///   1. 2026-08-28: manifest `yolyolakay_default` ga ishora qilardi, lekin
///      bu kanal hech qachon yaratilmagan edi → Android uni o'zi
///      `IMPORTANCE_DEFAULT` bilan yaratardi → ovoz bor, banner yo'q.
///   2. O'sha ko'chishda chat ID'si `strings.xml` da YANGILANMAY qoldi:
///      `MainActivity.kt` eski `yolyolakay_chat` ni yaratardi, Dart esa
///      uni «eski» deb O'CHIRARDI. Har ishga tushishda biri yaratib,
///      ikkinchisi o'chirib turardi.
///
/// 🔑 Kanalning muhimligini ham, ovozini ham yaratilgandan KEYIN
/// o'zgartirib bo'lmaydi. Ya'ni bunday nomuvofiqlik relizga chiqsa,
/// keyingi reliz bilan TUZATIB BO'LMAYDI — faqat yana yangi ID olinadi.
void main() {
  final dart = File('lib/core/push.dart').readAsStringSync();
  final strings = File(
    'android/app/src/main/res/values/strings.xml',
  ).readAsStringSync();
  final kotlin = File(
    'android/app/src/main/kotlin/uz/yolyolakay/mobile/MainActivity.kt',
  ).readAsStringSync();

  String dartConst(String name) =>
      RegExp("const $name = '([^']+)'").firstMatch(dart)!.group(1)!;

  String xmlString(String name) => RegExp(
    '<string name="$name"[^>]*>([^<]+)</string>',
  ).firstMatch(strings)!.group(1)!;

  test('kanal ID lari Dart va Android resurslarida bir xil', () {
    expect(
      xmlString('default_notification_channel_id'),
      dartConst('_channelDefault'),
      reason:
          'strings.xml dagi standart kanal ID si `push.dart` dagi '
          '`_channelDefault` dan farq qilyapti. Manifest AYNAN shu '
          'resursga tayanadi — mos kelmasa ilova yopiq bo\'lganda '
          'bildirishnoma sozlanmagan kanalga tushadi.',
    );
    expect(
      xmlString('chat_notification_channel_id'),
      dartConst('_channelChat'),
      reason:
          'strings.xml dagi chat kanali ID si `push.dart` dagi '
          '`_channelChat` dan farq qilyapti (aynan shu xato 2026-08-28 da '
          'sezilmay o\'tib ketgan edi).',
    );
  });

  test('MainActivity kanalni resursdan oladi, satrni qotirmaydi', () {
    for (final name in const [
      'default_notification_channel_id',
      'chat_notification_channel_id',
    ]) {
      expect(
        kotlin.contains('R.string.$name'),
        isTrue,
        reason:
            'MainActivity.kt `$name` resursidan foydalanishi kerak. '
            'ID qotirib yozilsa u strings.xml bilan jimgina ayrilib ketadi.',
      );
    }
    expect(
      kotlin.contains('yolyolakay_default'),
      isFalse,
      reason: 'Kanal ID si MainActivity.kt ga QOTIRIB yozilgan.',
    );
  });

  test('ovozli xabar: fayl bor va uch joyda bir xil nom bilan ulangan', () {
    final sound = dartConst('_voiceSound');

    final raw = Directory('android/app/src/main/res/raw');
    final files = raw
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.startsWith('$sound.'))
        .toList();

    expect(
      files.length,
      1,
      reason:
          'res/raw/ da `$sound` nomli AYNAN bitta fayl bo\'lishi kerak, '
          'topilgani: $files. Ikkita bo\'lsa (masalan .wav va .mp3 birga) '
          'qaysi biri yangrashini Android o\'zi tanlaydi.',
    );

    // 🔴 `shrinkResources` faylni SATR murojaatidan tanimaydi va relizdan
    // o'chirib yuboradi (birinchi yig'ilishda aynan shunday bo'ldi — AAB
    // ichida fayl yo'q edi). `keep.xml` uni saqlab qoladi.
    final keep = File(
      'android/app/src/main/res/raw/keep.xml',
    ).readAsStringSync();
    expect(
      keep.contains('@raw/$sound'),
      isTrue,
      reason:
          'res/raw/keep.xml da `@raw/$sound` ko\'rsatilmagan. Usiz ovoz '
          'fayli reliz yig\'ilishida jimgina tashlab yuboriladi: AAB '
          'muvaffaqiyatli chiqadi, kanal yaratiladi, ovoz esa YO\'Q.',
    );

    expect(
      kotlin.contains('raw/$sound'),
      isTrue,
      reason:
          'MainActivity.kt kanalni `raw/$sound` ovozi bilan yaratishi shart. '
          '🔑 Kotlin Dart dan OLDIN ishlaydi — kanalni amalda u yaratadi, '
          'ya\'ni ovoz faqat Dart tomonda ko\'rsatilsa HECH QACHON '
          'eshitilmaydi.',
    );
  });

  test(
    'iOS: ovoz fayli to\'plamda va Xcode loyihasida ro\'yxatdan o\'tgan',
    () {
      final sound = dartConst('_voiceSound');

      expect(
        File('ios/Runner/$sound.wav').existsSync(),
        isTrue,
        reason:
            'iOS ovozi ilova to\'plamining ILDIZIDA turishi shart — '
            'Android\'dagi `res/raw` bu yerda ishlamaydi.',
      );

      // 🔴 Faylni papkaga qo'yishning O'ZI yetmaydi: Xcode uni `Resources`
      // bosqichiga qo'shilmagan bo'lsa to'plamga UMUMAN tushmaydi va iOS
      // jimgina standart ovozga qaytadi — hech qanday xato chiqmaydi.
      final pbx = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(
        pbx.contains('$sound.wav in Resources'),
        isTrue,
        reason:
            '`$sound.wav` Xcode loyihasining Resources bosqichida yo\'q — '
            'fayl to\'plamga tushmaydi.',
      );
    },
  );

  test('standart kanal IMPORTANCE_MAX — Dart bilan bir xil daraja', () {
    // Kotlin oldin ishlagani uchun kanal AMALDA shu qiymat bilan tug'iladi;
    // Android esa muhimlikni keyin ko'tarishga ruxsat bermaydi. HIGH qolsa
    // Dart dagi `Importance.max` yozuvi yolg'on bo'lib qolardi.
    expect(
      kotlin.contains('IMPORTANCE_HIGH'),
      isFalse,
      reason:
          'MainActivity.kt da IMPORTANCE_HIGH qolgan, `push.dart` esa '
          '`Importance.max` deb yozadi. Birinchi yaratgan g\'olib chiqadi.',
    );
  });

  test('chiqarilgan barcha eski kanallar o\'chirish ro\'yxatida', () {
    // Odamlarning telefonida QOLGAN, endi ishlatilmaydigan ID lar. Ro'yxatdan
    // tushib qolsa, tizim sozlamalarida hech nima kelmaydigan o'lik qator
    // bo'lib osilib turadi.
    const shipped = [
      'yolyolakay_default',
      'yolyolakay_chat',
      'yolyolakay_default_v2',
      'yolyolakay_chat_v2',
    ];
    final legacy = RegExp(
      r'_legacyChannels\s*=\s*\[(.*?)\]',
      dotAll: true,
    ).firstMatch(dart)!.group(1)!;

    final live = {dartConst('_channelDefault'), dartConst('_channelChat')};
    for (final id in shipped) {
      if (live.contains(id)) continue;
      expect(
        legacy.contains("'$id'"),
        isTrue,
        reason:
            '`$id` relizga chiqqan, endi ishlatilmaydi, lekin '
            '`_legacyChannels` da yo\'q — u foydalanuvchi sozlamalarida '
            'o\'lik kanal bo\'lib qoladi.',
      );
    }
  });
}
