import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/api_client.dart';

/// JWT muddatini o'qish — OLDINDAN yangilashning asosi.
///
/// 🔴 NEGA TEST: bu yerdagi xato JIMGINA yuzaga chiqadi. `jwtExpiry` `null`
/// qaytarsa, ilova "token hech qachon eskirmaydi" deb hisoblaydi va oldindan
/// yangilash BUTUNLAY o'chadi — hammasi eski holicha (401 to'lqini, sessiya
/// uzilishi) ishlaydi, lekin hech qanday xato ko'rinmaydi. Buni faqat
/// 15 daqiqadan keyin, jonli qurilmada payqash mumkin edi.
///
/// Eng nozik joyi — base64url: JWT to'ldirish belgisisiz (`=`) keladi va
/// `base64.decode` bunday satrda `FormatException` tashlaydi.
void main() {
  /// Berilgan payload bilan haqiqiy shakldagi (to'ldirishsiz, base64url) token.
  String tokenWith(Map<String, dynamic> payload) {
    final head = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
    final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
    // JWT'da `=` to'ldirish belgilari BO'LMAYDI — aynan shu holatni sinaymiz.
    return '${head.replaceAll('=', '')}.${body.replaceAll('=', '')}.imzo';
  }

  test('exp o\'qiladi', () {
    final exp = DateTime.now().add(const Duration(minutes: 15));
    final token = tokenWith({
      'sub': 'u-1',
      'exp': exp.millisecondsSinceEpoch ~/ 1000,
    });

    final parsed = jwtExpiry(token);
    expect(parsed, isNotNull);
    expect(
      parsed!.difference(exp).inSeconds.abs(),
      lessThan(2),
      reason: 'muddat sekundgacha to\'g\'ri o\'qilsin',
    );
  });

  /// Payload uzunligi 4 ga bo'linmaydigan holat — to'ldirishsiz base64url'ning
  /// eng ko'p uchraydigan ko'rinishi.
  test('to\'ldirish belgisisiz (base64url) token ham o\'qiladi', () {
    for (var i = 0; i < 4; i++) {
      final token = tokenWith({
        // Har xil uzunlikdagi payload — 4 ning har qoldig'i sinaladi.
        'pad': 'x' * i,
        'exp': 2000000000,
      });
      expect(
        jwtExpiry(token),
        isNotNull,
        reason: 'payload uzunligi qoldig\'i ${token.split('.')[1].length % 4}',
      );
    }
  });

  test('kirill/UTF-8 payload buzmaydi', () {
    final token = tokenWith({'name': 'Farg\'ona Тошкент', 'exp': 2000000000});
    expect(jwtExpiry(token), isNotNull);
  });

  group('yaroqsiz token — null (yiqilmaydi)', () {
    test('bo\'sh satr', () => expect(jwtExpiry(''), isNull));
    test('nuqtasiz', () => expect(jwtExpiry('shunchaki-matn'), isNull));
    test('buzuq base64', () => expect(jwtExpiry('a.!!!!.c'), isNull));

    /// `exp` yo'q — muddat NOMA'LUM. Bunda `null` qaytishi SHART: aks holda
    /// har so'rovda "eskirgan" deb yangilash so'ralib, refresh token bekorga
    /// aylanaverardi (u esa har aylanishda eskisini o'ldiradi).
    test('exp maydoni yo\'q', () {
      expect(jwtExpiry(tokenWith({'sub': 'u-1'})), isNull);
    });

    test('exp son emas', () {
      expect(jwtExpiry(tokenWith({'exp': 'ertaga'})), isNull);
    });
  });
}
