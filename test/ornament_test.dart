import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/features/shared/brand/atlas.dart';
import 'package:yolyolakay/features/shared/brand/ornament.dart';

/// NAQSH QO'RIQCHILARI.
///
/// Naqshning GO'ZALLIGINI test tekshira olmaydi — buning uchun
/// `test/ornament_preview.dart` rasmlari bor. Lekin naqshni jimgina
/// buzadigan uchta narsani AYNAN test tutadi, chunki ular ko'z bilan
/// topilmaydi:
///
///   1. tungi rejimda relyef ranglari almashmasa — sahifa oq to'r
///      bilan qoplanadi (saytda aynan shunday bo'lgan);
///   2. ravoq YUMALOQ bo'lib qolsa — peshtoq tanilmaydi, lekin
///      «chiroyli» ko'rinaveradi;
///   3. naqsh bosishni o'ziga olsa — tugma ishlamay qoladi.
void main() {
  group('naqsh ranglari TEMADAN keladi', () {
    test('relyef yorug\' va tungida BOSHQACHA bo\'ladi', () {
      final light = OrnamentTokens.forTheme(
        buildTheme(brightness: Brightness.light),
      );
      final dark = OrnamentTokens.forTheme(
        buildTheme(brightness: Brightness.dark),
      );

      // 🔴 Saytda o'lchab topilgan xato: qirra rangi qotirib yozilganda
      // (`rgba(255,255,255,0.95)`) tungi rejimda butun sahifa oq to'r
      // bilan qoplanib, matn umuman o'qilmay qolgandi.
      expect(
        light.reliefLight,
        isNot(dark.reliefLight),
        reason:
            'qirra yorug\'i ikkala temada bir xil — tungida naqsh '
            'matnni bosadi',
      );
      expect(light.reliefShadow, isNot(dark.reliefShadow));
      expect(light.band, isNot(dark.band));

      // Tungida qirra XIRA bo'lishi shart.
      expect(dark.reliefLight.a, lessThan(0.12));
    });

    test('har uslubda kesim ZAMIN rangi bilan bir xil', () {
      // Kesim tasmani «uzib» ko'rsatadi. Zamindan farq qilsa, uzilgan
      // joyda begona dog' qoladi va naqsh singan chiziqqa aylanadi.
      for (final style in ThemeStyle.values) {
        for (final brightness in Brightness.values) {
          final theme = buildTheme(brightness: brightness, style: style);
          expect(
            OrnamentTokens.forTheme(theme).cut,
            theme.colorScheme.surface,
            reason: '$style/$brightness',
          );
        }
      }
    });

    test('tema kengaytmasi ROʻYXATDA — vidjet uni topadi', () {
      for (final style in ThemeStyle.values) {
        final theme = buildTheme(brightness: Brightness.light, style: style);
        expect(theme.extension<OrnamentTokens>(), isNotNull);
      }
    });
  });

  group('peshtoq UCHLI bo\'ladi', () {
    // 🔴 Birinchi urinishda ravoq tepasi deyarli TEKIS edi (0.335…0.665
    // oralig'ida) va shakl «qabr toshi»ga o'xshardi. Quyidagi ikki
    // tasdiq aynan shuni tutadi: uchida shakl TOR bo'lishi shart.
    const size = Size(200, 260);

    test('cho\'qqisi markazda va tor', () {
      final path = peshtoqPath(size);
      expect(path.contains(const Offset(100, 3)), isTrue);
      expect(
        path.contains(const Offset(60, 3)),
        isFalse,
        reason: 'ravoq tepasi tekis — bu peshtoq emas, yumaloq quti',
      );
    });

    test('muqarnas uyasi ham shu quruvchidan', () {
      final cell = pointedArch(const Size(60, 60), spring: 1);
      expect(cell.contains(const Offset(30, 2)), isTrue);
      expect(cell.contains(const Offset(16, 2)), isFalse);
    });

    test('ravoq pastki burchaklarini TO\'LDIRADI', () {
      // Surat ravoq ichida kesiladi: pastki burchaklar ochiq qolsa
      // kartaning tagida oq uchburchaklar paydo bo'ladi.
      final path = peshtoqPath(size);
      expect(path.contains(const Offset(2, 258)), isTrue);
      expect(path.contains(const Offset(198, 258)), isTrue);
    });
  });

  group('naqsh bosishni o\'ziga OLMAYDI', () {
    testWidgets('zamin naqshi ustidagi tugma bosiladi', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: GanchPattern()),
                const Positioned.fill(child: AtlasCloth()),
                Center(
                  child: FilledButton(
                    onPressed: () => tapped = true,
                    child: const Text('Bosish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Bosish'));
      expect(tapped, isTrue);
    });
  });

  group('to\'quv termasi USLUBGA moslashadi', () {
    test('tungi haydashda SOVUQ rang YO\'Q', () {
      /*
       * 🔴 O'LCHAB TOPILGAN XATO (2026-09-03): jiyak amber uslubida
       * ham xonatlasning to'q ko'k va yashil ranglarida chizilardi —
       * ruldagi odamning ekrani tepasida yorqin SOVUQ chiziq turardi.
       *
       * Amber uslubi aynan shuning uchun bor: tunda ko'k yorug'lik
       * ko'zni qamashtiradi va qorong'ilikka moslashishni buzadi.
       * Ya'ni bu bezak emas, ko'rish qulayligi masalasi.
       *
       * Qoida: har rangda QIZIL kanal KO'K dan katta bo'lsin.
       */
      for (final palette in AtlasPalette.amber) {
        for (final color in [
          palette.ground,
          palette.motif,
          palette.core,
          palette.accent,
          palette.light,
        ]) {
          expect(
            color.r,
            greaterThan(color.b),
            reason:
                'amber termasida sovuq rang: '
                '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16)}',
          );
        }
      }
    });

    test('har uslubda O\'Z termasi', () {
      List<AtlasPalette> threads(ThemeStyle style) => buildTheme(
        brightness: Brightness.dark,
        style: style,
      ).extension<OrnamentTokens>()!.threads;

      expect(threads(ThemeStyle.classic), AtlasPalette.all);
      expect(threads(ThemeStyle.amber), AtlasPalette.amber);
      expect(threads(ThemeStyle.neon), AtlasPalette.neon);
    });

    test('har termada UCHTA variant bor', () {
      // `AtlasEdge(palette: i)` indeksni 3 ga bo'lib oladi — ro'yxat
      // qisqa bo'lsa variantlar takrorlanib qoladi.
      for (final list in [
        AtlasPalette.all,
        AtlasPalette.amber,
        AtlasPalette.neon,
      ]) {
        expect(list.length, 3);
      }
    });
  });

  group('atlas ranglari TEMADAN MUSTAQIL', () {
    test('xonatlas rangi tungi rejimda ham o\'zgarmaydi', () {
      // Atlas — haqiqiy mato. Uning rangi interfeys temasiga qarab
      // o'zgarsa, u atlas bo'lmay qoladi.
      expect(AtlasPalette.at(0).ground, AtlasColors.crimson);
      expect(AtlasPalette.at(3).ground, AtlasPalette.at(0).ground);
      expect(AtlasPalette.all.length, 3);
    });
  });
}
