import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TORTIB-YANGILASH haqiqiy yuklanishni KUTISHI shart.
///
/// 🔴 Nima buzuq edi (egasi, 2026-08-21: «refreshda ilovada noto'g'ri
/// ishlayapti»): o'n bitta chaqiruv joyidan O'NTASI
/// `onRefresh: () async => ref.invalidate(...)` edi. `invalidate` —
/// SINXRON amal: u provayderni "eskirdi" deb belgilaydi va DARHOL
/// qaytadi. `RefreshIndicator` esa future tugashini "yangilash tugadi"
/// deb biladi va aylanishni to'xtatadi — ma'lumot hali kelmagan bo'lsa
/// ham. Odam uchun bu «tortdim, hech nima bo'lmadi» degani.
///
/// To'g'ri shakl — `ref.refresh(provider.future)`: u qayta yuklanishni
/// KUTADI, ya'ni indikator ma'lumot kelguncha aylanadi.
///
/// Bu qo'riqchi test: kelajakda kimdir yana `invalidate` yozib qo'ysa,
/// xato yana jimgina qaytardi — uni ko'z bilan sezish qiyin.
void main() {
  test('hech bir onRefresh ichida yolg\'iz invalidate qolmagan', () {
    final offenders = <String>[];

    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('onRefresh:')) continue;
        // Chaqiruvning o'zi va undan keyingi bir necha qator.
        final block = lines
            .sublist(i, (i + 6).clamp(0, lines.length))
            .join('\n');
        // `onRefresh` ichida invalidate BOR, lekin refresh/await YO'Q.
        final hasInvalidate = block.contains('invalidate(');
        final awaits =
            block.contains('.refresh(') || block.contains('await ');
        if (hasInvalidate && !awaits) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Bu joylarda yangilash ma\'lumotni KUTMAYDI — '
          '`ref.refresh(provider.future)` ishlating:\n${offenders.join('\n')}',
    );
  });
}
