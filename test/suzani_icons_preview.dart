import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/features/shared/brand/suzani_icons.dart';

import 'support/preview_fonts.dart';

/// SUZANI IKONKALARINI rasmga oladi — ko'z bilan tekshirish uchun.
///
/// Ikonkani kod bilan tasdiqlab bo'lmaydi: "24 pikselda o'qiladimi?" degan
/// savolga faqat KO'Z javob beradi. Shuning uchun bu yerda tasdiq yo'q —
/// rasm chiqariladi va `style_preview/suzani_ikonkalar.png` ga yoziladi.
///
///   flutter test test/suzani_icons_preview.dart --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadPreviewFonts);

  testWidgets('suzani ikonkalar varag\'i', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness: Brightness.light),
        home: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            Widget cell(SuzaniIcon icon, {required bool filled, required double size}) =>
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SuzaniIconWidget(
                    icon,
                    size: size,
                    filled: filled,
                    color: filled ? scheme.primary : scheme.onSurface,
                  ),
                );

            Widget row(String title, double size) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 14),
                  child: Text(title),
                ),
                Row(
                  children: [
                    for (final icon in SuzaniIcon.values)
                      cell(icon, filled: false, size: size),
                  ],
                ),
                Row(
                  children: [
                    for (final icon in SuzaniIcon.values)
                      cell(icon, filled: true, size: size),
                  ],
                ),
              ],
            );

            return Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 24 — menyudagi haqiqiy o'lcham, ya'ni HAL QILUVCHI qator.
                    row('24 px (menyu — haqiqiy o\'lcham)', 24),
                    row('40 px', 40),
                    row('72 px (naqsh ko\'rinsin)', 72),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/suzani_ikonkalar.png'),
    );
  });
}
