import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TARIF TAFSILOTIDAGI FILTRLAR RO'YXATI HAQIQATGA MOS TURSINMI.
///
/// 🔴 NEGA BU TEST BOR: tarif oynasi "shu tarifda konditsioner, chekilmaydi,
/// orqada 2 kishi va haydash uslubi ochiladi" deb VA'DA beradi. Haqiqiy
/// qulf esa boshqa faylda — e'lon berish ekranida (`_premiumLocked`).
///
/// Ikkalasi ayri joyda turgani uchun ular JIMGINA ayri ketishi mumkin:
/// masalan backend beshinchi filtrni ham pullik qilsa, e'lon ekrani uni
/// qulflaydi-yu, tarif oynasi bu haqda hech nima demaydi. Odam pul to'laydi
/// va va'da qilinmagan cheklovga duch keladi — bu eng yomon xil xato,
/// chunki u PUL bilan bog'liq va hech qanday xato xabari bermaydi.
///
/// Test ikkala ro'yxatni solishtiradi.
void main() {
  test('tarif oynasidagi filtrlar e\'lon ekranidagi qulf bilan bir xil', () {
    final createRide = File(
      'lib/features/rides/create_ride_screen.dart',
    ).readAsStringSync();
    final tariffs = File(
      'lib/features/billing/tariffs_screen.dart',
    ).readAsStringSync();

    // FAQAT so'rov quriladigan blokni qaraymiz.
    //
    // `locked` bayrog'i ekranning boshqa joyida ham ishlatiladi (tugmani
    // o'chirish, izoh ko'rsatish) — bizga esa SERVERGA KETADIGAN qiymatlar
    // kerak. Shuning uchun `PublishRideRequest(...)` ichi kesib olinadi.
    final requestStart = createRide.indexOf('PublishRideRequest(');
    expect(
      requestStart,
      isNonNegative,
      reason: 'So\'rov quriladigan blok topilmadi — test yangilanishi kerak',
    );
    // Maydonlar ro'yxati bir necha o'nlab qator — oyna bilan kesamiz.
    // Yopuvchi qavsni izlash mo'rt: chekinish o'zgarsa test yiqilardi.
    final requestBlock = createRide.substring(
      requestStart,
      (requestStart + 1500).clamp(0, createRide.length),
    );

    final lockedFields = RegExp(r'(\w+): locked \?')
        .allMatches(requestBlock)
        .map((m) => m.group(1)!)
        .toSet();

    expect(
      lockedFields,
      {'hasAc', 'noSmoking', 'maxTwoBack', 'drivingSpeed'},
      reason:
          'E\'lon ekranidagi pullik filtrlar ro\'yxati o\'zgaribdi. '
          'Tarif tafsiloti oynasidagi ro\'yxatni ham yangilang, aks holda '
          'u sotib olishdan oldin YOLG\'ON va\'da beradi.',
    );

    // Tarif oynasi aynan shu to'rttasini sanaydi (satr kalitlari orqali).
    for (final key in ['t.hasAc', 't.noSmoking', 't.maxTwoBack', 't.drivingStyle']) {
      expect(
        tariffs.contains(key),
        isTrue,
        reason: 'Tarif tafsilotida $key yo\'q — ro\'yxat to\'liq emas',
      );
    }
  });
}
