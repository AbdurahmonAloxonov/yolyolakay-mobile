import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/features/shared/brand/atlas.dart';
import 'package:yolyolakay/features/shared/brand/ornament.dart';
import 'package:yolyolakay/features/shared/brand/suzani_avatar.dart';

import 'support/preview_fonts.dart';

/// NAQSHLARNI RASMGA OLADI — ko'z bilan tekshirish uchun.
///
/// 🔑 Saytdagi eng qimmat dars: naqshni KOD bilan tasdiqlab bo'lmaydi.
/// «Girihmi yoki shunchaki yulduzmi», «mato ko'rinyaptimi yoki tekis
/// chiziqmi» — bu savollarga faqat KO'Z javob beradi. Shuning uchun bu
/// yerda tasdiq yo'q, rasm chiqadi:
///
///   flutter test test/ornament_preview.dart --update-goldens
///   → style_preview/naqsh/*.png
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Size size,
    Widget Function(BuildContext) build, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness: brightness),
        home: Builder(builder: (c) => Scaffold(body: build(c))),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/naqsh/$name.png'),
    );
  }

  Widget label(BuildContext c, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Theme.of(c).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.dark ? 'tungi' : 'yorug';

    testWidgets('girih va ganch — $suffix', (tester) async {
      await shoot(tester, 'girih_$suffix', const Size(760, 900), (c) {
        final scheme = Theme.of(c).colorScheme;
        Widget plate(String title, Color bg, Widget pattern) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label(c, title),
              Expanded(
                child: Container(
                  color: bg,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      pattern,
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Naqsh matnni bosmasligi kerak — shu yozuv '
                            'o\'qilishi bilan tekshiriladi.',
                            style: TextStyle(
                              fontSize: 15,
                              color: bg.computeLuminance() > 0.5
                                  ? scheme.onSurface
                                  : scheme.surface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  plate(
                    'GIRIH — to\'q zaminda (katak 104)',
                    heroSurface(Theme.of(c)),
                    GirihPattern(
                      cut: heroSurface(Theme.of(c)),
                      color: onHeroSurface(Theme.of(c)).withValues(alpha: 0.14),
                    ),
                  ),
                  plate(
                    'GIRIH — katak 72 (mayda)',
                    heroSurface(Theme.of(c)),
                    GirihPattern(
                      cell: 72,
                      cut: heroSurface(Theme.of(c)),
                      color: onHeroSurface(Theme.of(c)).withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  plate(
                    'GANCH — yorug\' zaminda, depth 1.0',
                    scheme.surface,
                    const GanchPattern(),
                  ),
                  plate(
                    'GANCH — depth 0.6 (mazmun bo\'limi)',
                    scheme.surface,
                    const GanchPattern(depth: 0.6),
                  ),
                ],
              ),
            ),
          ],
        );
      }, brightness: brightness);
    });

    testWidgets('belgilar — $suffix', (tester) async {
      await shoot(tester, 'belgilar_$suffix', const Size(760, 900), (c) {
        final scheme = Theme.of(c).colorScheme;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label(c, 'PAXTA GULI — 20 / 24 / 28 / 40'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final s in [20.0, 24.0, 28.0, 40.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Pakhta(size: s),
                      ),
                  ],
                ),
              ),
              label(c, 'BO\'LIM BELGISI'),
              const OrnamentMark(),
              label(c, 'ISLIMI — bo\'lim ajratgichi'),
              const IslimiBand(),
              label(c, 'QO\'CHQOR SHOXI — qadam medalyoni'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var i = 1; i <= 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: QochqorStep(number: i),
                      ),
                  ],
                ),
              ),
              label(c, 'MUQARNAS — zamindan zaminga o\'tish'),
              Container(
                color: heroSurface(Theme.of(c)),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    MuqarnasBand(color: scheme.surface),
                  ],
                ),
              ),
              Container(height: 24, color: scheme.surface),
              label(c, 'PESHTOQ — surat SHU SHAKLDA kesiladi'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 190,
                      child: PeshtoqFrame(
                        child: Container(
                          color: scheme.primary,
                          child: const Center(
                            child: Icon(
                              Icons.photo,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      height: 140,
                      child: PeshtoqFrame(
                        border: BorderSide(color: scheme.primary, width: 2),
                        child: const AtlasCloth(palette: 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      height: 100,
                      child: PeshtoqFrame(
                        child: Container(color: scheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              label(c, 'PALAK ROZETKASI — suv belgisi'),
              SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -20,
                      child: PalakRosette(
                        size: 260,
                        color: scheme.primary,
                        opacity: 0.16,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Mazmun rozetka ustida turadi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }, brightness: brightness);
    });
  }

  testWidgets('shaxsiy muhr — 24 ta odam', (tester) async {
    await shoot(tester, 'muhr', const Size(760, 420), (c) {
      final seeds = List.generate(24, (i) => 'user-$i-abdurahmon');
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(c, 'RO\'YXATDAGI O\'LCHAM (36 px)'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in seeds)
                  ClipOval(child: SuzaniAvatar(seed: s, size: 36)),
              ],
            ),
            label(c, 'PROFIL O\'LCHAMI (88 px)'),
            Wrap(
              spacing: 12,
              children: [
                for (final s in seeds.take(6))
                  ClipOval(child: SuzaniAvatar(seed: s, size: 88)),
              ],
            ),
          ],
        ),
      );
    });
  });

  testWidgets('atlas — mato va jiyak', (tester) async {
    await shoot(tester, 'atlas', const Size(760, 1000), (c) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(c, 'MATO — tik, uchta terma (bir marta YIRIK)'),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(child: AtlasCloth(palette: i)),
                ],
              ),
            ),
            label(c, 'MATO — yotiq tasma, scale 0.8'),
            const SizedBox(
              height: 110,
              child: AtlasCloth(vertical: false, scale: 0.8),
            ),
            label(c, 'JIYAK — 4 / 6 / 10 px (ingichka joyda HAMMA rang)'),
            const AtlasEdge(height: 4),
            const SizedBox(height: 10),
            const AtlasEdge(height: 6, palette: 1),
            const SizedBox(height: 10),
            const AtlasEdge(height: 10, palette: 2),
            label(c, 'MATO — nursiz (jiyak yonida taqqoslash uchun)'),
            const SizedBox(
              height: 120,
              child: AtlasCloth(sheen: false, scale: 0.6),
            ),
          ],
        ),
      );
    });
  });
}
