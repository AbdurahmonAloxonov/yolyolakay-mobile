import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// UI uslubini TANLASH uchun rasm yasagich.
///
/// Bu SINOV EMAS — shuning uchun nomi `_test.dart` bilan tugamaydi va
/// `flutter test` uni o'z-o'zidan yugurtirmaydi. Qo'lda chaqiriladi:
///
///   flutter test test/style_preview.dart --update-goldens
///
/// Natija: `style_preview/*.png` — bir xil mazmun (bitta safar kartochkasi,
/// bo'lim sarlavhasi, ma'lumot qutisi va tugmalar) har xil uslubda chizilgan.
/// Maqsad — uslubni gap bilan emas, KO'Z bilan tanlash.
void main() {
  setUpAll(() async {
    // Sinov muhitida standart shrift kvadratchalar chizadi. Tizimdagi haqiqiy
    // shriftni yuklaymiz, aks holda rasmda matn o'rniga qora bloklar chiqadi.
    Future<ByteData> read(String path) =>
        File(path).readAsBytes().then((b) => b.buffer.asByteData());

    await (FontLoader(
          'Preview',
        )..addFont(read('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf')))
        .load();
    // Noto Sans'da `→` va `★` yo'q — ularsiz rasmda kvadratcha chiqadi.
    // DejaVu zaxira sifatida qo'shiladi (`fontFamilyFallback`).
    await (FontLoader(
      'PreviewSymbols',
    )..addFont(read('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'))).load();
  });

  Future<void> shoot(WidgetTester tester, String name, Widget sample) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/$name.png'),
    );
  }

  testWidgets(
    '1 — hozirgi holat',
    (t) => shoot(t, '1_hozirgi', _Sample.current()),
  );
  testWidgets(
    '2 — Material 3 Expressive',
    (t) => shoot(t, '2_material3', _Sample.material3()),
  );
  testWidgets(
    '3 — Airbnb / BlaBlaCar',
    (t) => shoot(t, '3_airbnb', _Sample.airbnb()),
  );
  testWidgets('4 — Soft UI', (t) => shoot(t, '4_soft', _Sample.soft()));
  testWidgets('5 — aralash', (t) => shoot(t, '5_aralash', _Sample.mix()));
  testWidgets(
    '5 — aralash, tungi',
    (t) => shoot(t, '5_aralash_tungi', _Sample.mix(dark: true)),
  );
}

/// Namunadagi mazmun HAMMA uslubda bir xil: faqat ko'rinish o'zgaradi.
class _Sample extends StatelessWidget {
  const _Sample({
    required this.title,
    required this.theme,
    required this.card,
    required this.infoBox,
    this.background,
  });

  final String title;
  final ThemeData theme;
  final Widget card;
  final Widget infoBox;
  final Color? background;

  static const _pink = Color(0xFFE91E8C);
  static const _turquoise = Color(0xFF99E1D9);
  static const _wineAsh = Color(0xFF32292F);

  static ThemeData _base() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Preview',
    fontFamilyFallback: const ['PreviewSymbols'],
    colorScheme: ColorScheme.fromSeed(seedColor: _pink).copyWith(
      primary: _pink,
      onPrimary: Colors.white,
      secondary: _turquoise,
      onSurface: _wineAsh,
      surface: Colors.white,
    ),
  );

  // ————— 1. HOZIRGI: chegara + 16 radius, lekin qutilar har xil —————
  static Widget current() => _Sample(
    title: 'Hozirgi holat',
    theme: _base(),
    background: const Color(0xFFFAF8F9),
    card: _CardShell(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE4E8)),
      ),
    ),
    // ⚠ ATAYIN boshqa radius: hozir kodda aynan shunday (14 va 6 yonma-yon).
    infoBox: _InfoShell(
      decoration: BoxDecoration(
        color: _turquoise.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      badgeRadius: 6,
    ),
  );

  // ————— 2. MATERIAL 3 EXPRESSIVE: to'ldirilgan sirt, katta radius —————
  static Widget material3() => _Sample(
    title: 'Material 3 Expressive',
    theme: _base(),
    background: const Color(0xFFFDF7FA),
    card: _CardShell(
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEF5),
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    infoBox: _InfoShell(
      decoration: BoxDecoration(
        color: _turquoise.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      badgeRadius: 999,
    ),
  );

  // ————— 3. AIRBNB / BLABLACAR: oq, yupqa chegara, ko'p havo —————
  static Widget airbnb() => _Sample(
    title: 'Airbnb / BlaBlaCar',
    theme: _base(),
    background: Colors.white,
    card: _CardShell(
      spacious: true,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    ),
    infoBox: _InfoShell(
      spacious: true,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      badgeRadius: 999,
    ),
  );

  // ————— 4. SOFT UI: chegarasiz, ikki tomonlama yumshoq soya —————
  static Widget soft() {
    const bg = Color(0xFFEFEDF0);
    final softShadow = [
      const BoxShadow(
        color: Color(0xFFFFFFFF),
        blurRadius: 12,
        offset: Offset(-4, -4),
      ),
      const BoxShadow(
        color: Color(0x1A32292F),
        blurRadius: 12,
        offset: Offset(5, 5),
      ),
    ];
    return _Sample(
      title: 'Soft UI',
      theme: _base(),
      background: bg,
      card: _CardShell(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow,
        ),
      ),
      infoBox: _InfoShell(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow,
        ),
        badgeRadius: 999,
      ),
    );
  }

  // ————— 5. ARALASH: Airbnb'ning oq havosi + Soft UI'ning yumshoq soyasi —————
  //
  // Nima olindi: 3-dan — oq fon, keng ichki chekka, tinch neytral quti;
  //              4-dan — CHEGARASIZ karta va yumshoq soya.
  //
  // Nima OLINMADI: 4-dagi kulrang fon (#EFEDF0) va ikki tomonlama "bo'rtma"
  // soya. Aynan o'sha ikkitasi tungi rejimni buzadi: oq soya qorong'ida
  // ko'rinmaydi va bo'rtiqlik yo'qoladi. Bu yerda soya BIR tomonlama va
  // qorong'ida u umuman ishlatilmaydi — chuqurlik sirt rangi bilan beriladi
  // (`surface` fondan biroz och). Shu sabab uslub ikkala rejimda ham butun.
  static Widget mix({bool dark = false}) {
    final scheme = _base().colorScheme.copyWith(
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: dark ? const Color(0xFF241F23) : Colors.white,
      onSurface: dark ? const Color(0xFFF2EEF1) : _wineAsh,
      onSurfaceVariant: dark
          ? const Color(0xFF9E949A)
          : const Color(0xFF8A7F86),
      outlineVariant: dark ? const Color(0xFF3A3339) : const Color(0xFFE6E0E4),
    );
    // 🔴 Birinchi urinishda fon ham, karta ham OQ edi — karta butunlay
    // yo'qolib ketdi, faqat pastki soyasi ko'rinardi. Chegarasiz karta
    // ishlashi uchun fon undan bir oz TO'Q bo'lishi SHART. Farq juda kichik
    // (#F7F5F7 va oq), lekin aynan shu karta chetini ko'rsatadi.
    final background = dark ? const Color(0xFF161316) : const Color(0xFFF7F5F7);

    // Qorong'ida soya YO'Q: qora ustiga qora soya ko'rinmaydi, faqat
    // hisoblash qiymatini yeydi. Chuqurlik `surface` ning ochroqligidan.
    final elevation = dark
        ? const <BoxShadow>[]
        : const [
            BoxShadow(
              color: Color(0x0F32292F),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x0A32292F),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ];

    return _Sample(
      title: dark ? 'Aralash — tungi rejim' : 'Aralash (3 + 4)',
      // 🔴 `_base().copyWith(colorScheme: ...)` QILMANG: u faqat sxemani
      // almashtiradi, `textTheme` esa yorug' temadan hisoblanib bo'lgan
      // bo'ladi va matn qora bo'lib qoladi — qorong'i fonda o'qib bo'lmaydi
      // (birinchi urinishda aynan shunday bo'ldi). Tema sxemadan QAYTA
      // quriladi.
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Preview',
        fontFamilyFallback: const ['PreviewSymbols'],
        brightness: dark ? Brightness.dark : Brightness.light,
        colorScheme: scheme,
      ),
      background: background,
      card: _CardShell(
        spacious: true,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: elevation,
        ),
      ),
      infoBox: _InfoShell(
        spacious: true,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1F2624) : const Color(0xFFF2F9F8),
          borderRadius: BorderRadius.circular(16),
        ),
        badgeRadius: 999,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A8F96),
                  ),
                ),
                const SizedBox(height: 16),
                // Bo'lim sarlavhasi — hozir kodda uch xil, bu yerda bitta.
                Text(
                  'YAQIN SAFARLAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                card,
                const SizedBox(height: 16),
                infoBox,
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              theme.filledButtonTheme.style == null ? 14 : 14,
                            ),
                          ),
                        ),
                        child: const Text('Bekor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: _pink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Joy band qilish'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Safar kartochkasi — mazmuni hamma uslubda bir xil.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.decoration, this.spacious = false});

  final BoxDecoration decoration;
  final bool spacious;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacious ? 20 : 16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF99E1D9),
                child: Text('A', style: TextStyle(color: Color(0xFF32292F))),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aziz Karimov',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Chevrolet Cobalt',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9A8F96)),
                    ),
                  ],
                ),
              ),
              const Text('★ 4.9', style: TextStyle(fontSize: 13)),
            ],
          ),
          SizedBox(height: spacious ? 16 : 12),
          const Text(
            'Toshkent → Samarqand',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Ertaga, 09:00 · 3 joy bo\'sh',
            style: TextStyle(fontSize: 13, color: muted),
          ),
          SizedBox(height: spacious ? 16 : 12),
          const Text(
            '150 000 so\'m',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE91E8C),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ma'lumot qutisi + kichik yorliq (davlat raqami kabi).
class _InfoShell extends StatelessWidget {
  const _InfoShell({
    required this.decoration,
    required this.badgeRadius,
    this.spacious = false,
  });

  final BoxDecoration decoration;
  final double badgeRadius;
  final bool spacious;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacious ? 20 : 16),
      decoration: decoration,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Bron tasdiqlandi. Haydovchi bilan bog\'laning.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(badgeRadius),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: const Text(
                  '01 A 123 BC',
                  style: TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
