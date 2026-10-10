import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KLAVIATURA ZANJIRI qo'riqchisi.
///
/// 🔴 NEGA (2026-08-25 auditi): butun ilovada `textInputAction` UMUMAN
/// ishlatilmagan edi. Ko'p maydonli formada bu shuni anglatardi: odam
/// bitta maydonni to'ldirib bo'lgach klaviatura yopiladi, u keyingi
/// maydonni QO'LI bilan izlaydi — va aynan o'sha maydonni klaviatura
/// yopib turgan bo'ladi. Uzun formada bu sakkiz marta takrorlanadi.
///
/// Bu test yangi ko'p maydonli forma qo'shilganda esdan chiqmasligi
/// uchun: zanjir bo'lmasa u shunchaki "biroz noqulay" bo'lib qoladi va
/// hech qachon tuzatilmaydi.
void main() {
  /// Ko'p maydonli formalar — har birida zanjir BO'LISHI shart.
  const forms = [
    'lib/features/profile/add_car_sheet.dart',
    'lib/features/profile/driver_verification_screen.dart',
    'lib/features/profile/edit_profile_screen.dart',
    'lib/features/profile/complete_profile_screen.dart',
    'lib/features/profile/password_sheet.dart',
    'lib/features/parcels/create_parcel_screen.dart',
  ];

  for (final path in forms) {
    test('$path — klaviatura zanjiri bor', () {
      final src = File(path).readAsStringSync();
      final fields = RegExp(r'\bTextField\(|\bTextFormField\(')
          .allMatches(src)
          .length;
      final chained = RegExp(r'textInputAction: TextInputAction\.')
          .allMatches(src)
          .length;

      expect(
        chained,
        greaterThanOrEqualTo(fields),
        reason:
            'Formada $fields maydon bor, `textInputAction` esa $chained ta. '
            'Har maydonga qo\'ying: oxirgisiga `done`, qolganlariga `next`.',
      );
    });
  }

  /// Zanjir `done` bilan TUGASHI kerak: oxirgi maydonda ham «Keyingi»
  /// tursa, klaviatura odamni hech qayerga olib bormaydi va u tugmani
  /// qidiradi.
  test('har zanjir `done` bilan tugaydi', () {
    for (final path in forms) {
      final src = File(path).readAsStringSync();
      expect(
        src,
        contains('TextInputAction.done'),
        reason: '$path — zanjirning oxirgi maydoni `done` bo\'lsin',
      );
    }
  });
}
