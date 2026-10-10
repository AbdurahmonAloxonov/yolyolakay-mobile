import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/shared/brand/suzani_icons.dart';

/// Suzani ikonkalari — chizilish qo'riqchisi.
///
/// Ikonkaning CHIROYLI ekanini kod tekshira olmaydi (buning uchun
/// `suzani_icons_preview.dart` rasm chiqaradi). Bu yerda tekshiriladigan
/// narsa boshqa: ular UMUMAN chizilishi.
///
/// 🔴 NEGA KERAK: shakllar `Path.combine` bilan kesiladi va bu amal
/// noto'g'ri yo'lda (masalan bo'sh yoki yopilmagan `Path`) tashlaydi.
/// Bunday xato faqat EKRANDA ko'rinadi — ilova qizil kvadrat chizadi va
/// pastki menyu butunlay yo'qoladi. Ilgari `BlendMode.clear` bilan
/// yozilgan variant aynan shu sababdan jimgina noto'g'ri chizilgan edi.
void main() {
  Future<void> paintAll(
    WidgetTester tester, {
    required double size,
    required bool filled,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final icon in SuzaniIcon.values)
                SuzaniIconWidget(
                  icon,
                  size: size,
                  filled: filled,
                  color: Colors.black,
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  for (final size in const [16.0, 24.0, 40.0, 72.0]) {
    testWidgets('$size px — chiziq varianti chiziladi', (tester) async {
      await paintAll(tester, size: size, filled: false);
    });

    testWidgets('$size px — to\'ldirilgan variant chiziladi', (tester) async {
      await paintAll(tester, size: size, filled: true);
    });
  }

  testWidgets('rang berilmasa IconTheme dan olinadi', (tester) async {
    // Menyu va tugmalar ichida ikonka O'ZI to'g'ri ranglanishi kerak:
    // aks holda har chaqiruvda rang yozish kerak bo'ladi va bittasi
    // unutilgan kuni ikonka tungi rejimda ko'rinmay qoladi.
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(color: Colors.red),
          child: SuzaniIconWidget(SuzaniIcon.car),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('to\'plamda hamma kerakli ikonka bor', (tester) async {
    // Pastki menyu shu beshtaga tayanadi — biri o'chirilsa menyu
    // yiqiladi, lekin buni faqat ilovani ochganda ko'rardik.
    expect(
      SuzaniIcon.values,
      containsAll(const [
        SuzaniIcon.search,
        SuzaniIcon.create,
        SuzaniIcon.car,
        SuzaniIcon.parcel,
        SuzaniIcon.chat,
        SuzaniIcon.person,
      ]),
    );
  });
}
