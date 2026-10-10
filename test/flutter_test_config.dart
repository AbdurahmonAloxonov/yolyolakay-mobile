import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// TESTLARDA HAQIQIY SHRIFTLARNI YUKLAYDI.
///
/// 🔴 NEGA KERAK (2026-08-27): Flutter testlari `pubspec.yaml` dagi
/// shriftlarni O'ZI YUKLAMAYDI — ular o'rniga glifsiz sinov shrifti
/// ishlatiladi. Natijada `style_preview` dagi namuna rasmlarida matn
/// noto'g'ri chizilardi va `→` kabi belgilar bo'sh kvadrat (tofu) bo'lib
/// ko'rinardi. Ya'ni rasmga qarab dizayn haqida XULOSA CHIQARIB
/// BO'LMASDI — u qurilmadagidan boshqacha edi.
///
/// Endi namuna rasmlari haqiqiy tipografikani ko'rsatadi va ular dizayn
/// tekshiruvi uchun ishonchli manba bo'ladi.
///
/// ⚠️ Shrift topilmasa test YIQILMAYDI — sinov shrifti bilan davom etadi.
/// Bu fayl butun test to'plamini boshqaradi va bitta yo'q fayl tufayli
/// 560 ta testni to'xtatish nomutanosib bo'lardi.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var any = false;
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loader.addFont(
        file.readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
      );
      any = true;
    }
    if (any) await loader.load();
  }

  await load('Inter', ['assets/fonts/Inter-var.ttf']);
  await load('Fraunces', [
    'assets/fonts/Fraunces-Regular.ttf',
    'assets/fonts/Fraunces-SemiBold.ttf',
    'assets/fonts/Fraunces-Bold.ttf',
  ]);

  await testMain();
}
