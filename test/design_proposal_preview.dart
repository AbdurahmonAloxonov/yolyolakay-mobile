import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/preview_fonts.dart';

/// «YO'L» — ILOVANING YANGI DIZAYN TILI, taklif ko'rinishida.
///
/// 🔴 NEGA (egasi, 2026-09-02): «ilovamiz oldindan kelishib ko'rilmagan,
/// palapartish qurilgan. Bir-ikki joyni emas, TO'LIQ dizaynni yangilaymiz
/// — menga dizayn bo'yicha takliflar ber».
///
/// Bu fayl taklifni KO'RSATADI: avval tizimning o'zi (tipografika,
/// ranglar, tugmalar, holatlar), keyin o'sha tizim asosiy ekranlarga
/// qanday tushishi.
///
/// ⚠️ ILOVA KODIGA TEGMAYDI. Tasdiqlangach, bu yerdagi qарорlar
/// `app/theme.dart` va vidjetlarga ko'chiriladi.
///
///   flutter test test/design_proposal_preview.dart --update-goldens
///   → style_preview/design/*.png
///
/// ═══ TIZIMNING QOIDALARI ═══
///
/// 1. IMZO — YO'L CHIZIG'I. Ikki nuqta va ularni bog'lovchi chiziq
///    butun ilovada takrorlanadi: kartada, sarlavhada, bo'sh holatda,
///    safar borishida. Ilovani bir qarashda tanitadigan narsa shu.
///
/// 2. BITTA EKRANDA BITTA PUSHTI. Pushti — asosiy amal VA narx.
///    Boshqa hamma narsa neytral. Ilgari pushti hamma joyda edi va
///    shuning uchun hech narsani ajratmasdi.
///
/// 3. FERUZA — «BO'SH/YAXSHI», PUSHTI — «MUHIM/OZ QOLDI».
///    Rang holatni aytadi, bezak bo'lmaydi.
///
/// 4. SARLAVHA QALIN GROTESK (egasi tanladi). Serif olib tashlanadi:
///    Fraunces'da kirill YO'Q — ruscha sarlavhalar tizim shriftiga
///    tushib ketardi.
///
/// 5. HAR EKRANDA BO'SH, YUKLANISH VA XATO HOLATI CHIZILGAN bo'ladi.
///    Hozir ular ko'pincha bitta kulrang jumla.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    double height = 844,
  }) async {
    await tester.binding.setSurfaceSize(Size(390, height));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: withPreviewFont(ThemeData(fontFamily: 'Roboto')),
        home: screen,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/design/$name.png'),
    );
  }

  testWidgets(
    'tizim varag\'i',
    (t) => shoot(t, 'tizim_1_asoslar', const _SystemSheet(), height: 1500),
  );
  testWidgets(
    'bosh ekran',
    (t) => shoot(t, 'tizim_2_bosh', const _HomeScreen()),
  );
  testWidgets(
    'safar tafsiloti',
    (t) => shoot(t, 'tizim_3_safar', const _TripScreen()),
  );
  testWidgets(
    'holatlar',
    (t) => shoot(t, 'tizim_4_holatlar', const _StatesScreen(), height: 1000),
  );
}

// ══════════════════════════════════════════════════════════════════
// TOKENLAR
// ══════════════════════════════════════════════════════════════════

const _ink = Color(0xFF32292F); // matn, to'q sirt
const _inkSoft = Color(0xFF7A7076); // ikkinchi darajali matn
const _pink = Color(0xFFE91E8C); // asosiy amal + narx
const _turq = Color(0xFF14B8A6); // «bo'sh / yaxshi»
const _turqSoft = Color(0xFFD7F2EE);
const _bg = Color(0xFFF6F4F5);
const _line = Color(0xFFEBE6E9);

/// 4 ga karrali oraliqlar. Ekran chekkasi 20 (ilgari 16 edi — matn
/// chetga juda yaqin turardi va ilova zich ko'rinardi).
const _pad = 20.0;

TextStyle _display = const TextStyle(
  fontSize: 30,
  height: 1.08,
  letterSpacing: -0.8,
  fontWeight: FontWeight.w800,
  color: _ink,
);
TextStyle _h1 = const TextStyle(
  fontSize: 22,
  height: 1.15,
  letterSpacing: -0.4,
  fontWeight: FontWeight.w800,
  color: _ink,
);
TextStyle _h2 = const TextStyle(
  fontSize: 17,
  height: 1.2,
  fontWeight: FontWeight.w700,
  color: _ink,
);
TextStyle _body = const TextStyle(
  fontSize: 15,
  height: 1.4,
  fontWeight: FontWeight.w400,
  color: _ink,
);
TextStyle _label = const TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: _inkSoft,
);
TextStyle _micro = const TextStyle(
  fontSize: 11,
  letterSpacing: 0.8,
  fontWeight: FontWeight.w800,
  color: _inkSoft,
);

// ══════════════════════════════════════════════════════════════════
// IMZO — YO'L CHIZIG'I. Butun ilovada takrorlanadigan yagona shakl.
// ══════════════════════════════════════════════════════════════════

class RouteLine extends StatelessWidget {
  const RouteLine({
    super.key,
    required this.from,
    required this.to,
    this.style,
    this.gap = 14,
  });

  final String from, to;
  final TextStyle? style;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final s = style ?? _h2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            children: [
              _dot(_pink),
              Container(width: 2, height: gap + 4, color: _line),
              _dot(_turq),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: s,
              ),
              SizedBox(height: gap - 6),
              Text(
                to,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: s.copyWith(color: _inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _dot(Color c) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

/// Asosiy tugma — butun engda, 52 px balandlikda.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, this.enabled = true, this.icon});
  final String label;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: enabled ? _pink : const Color(0xFFE4DFE2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: enabled ? Colors.white : _inkSoft),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : _inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.tone = _turq, this.soft = _turqSoft});
  final String text;
  final Color tone, soft;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tone),
    ),
  );
}

/// Karta — chegara YO'Q, chuqurlik yumshoq soya bilan.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _ink.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    padding: EdgeInsets.all(padding),
    child: child,
  );
}

/// Bo'lim sarlavhasi — kichik, katta harflarda, yonida chiziq.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(text.toUpperCase(), style: _micro),
      const SizedBox(width: 10),
      const Expanded(child: Divider(height: 1, color: _line)),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════
// 1. TIZIM VARAG'I — asoslar bir joyda
// ══════════════════════════════════════════════════════════════════

class _SystemSheet extends StatelessWidget {
  const _SystemSheet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(_pad, 46, _pad, 32),
        children: [
          Text('Yo\'l', style: _display),
          const SizedBox(height: 4),
          Text('Ilovaning dizayn tili', style: _label),
          const SizedBox(height: 26),

          const SectionTitle('Tipografika'),
          const SizedBox(height: 14),
          Text('Manzilga yeting', style: _display),
          const SizedBox(height: 6),
          Text('Toshkent — Samarqand', style: _h1),
          const SizedBox(height: 6),
          Text('Safar tafsilotlari', style: _h2),
          const SizedBox(height: 6),
          Text(
            'Haydovchi hujjatlari tekshirilgan, narx kelishiladi.',
            style: _body,
          ),
          const SizedBox(height: 6),
          Text('Ertaga 09:30 · 4 soat', style: _label),
          const SizedBox(height: 6),
          Text('BO\'LIM SARLAVHASI', style: _micro),
          const SizedBox(height: 24),

          const SectionTitle('Ranglar'),
          const SizedBox(height: 14),
          Row(
            children: [
              _swatch(_pink, 'Amal · narx'),
              _swatch(_turq, 'Bo\'sh joy'),
              _swatch(_ink, 'Matn · to\'q sirt'),
              _swatch(const Color(0xFFF5A623), 'Ogohlantirish'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Qoida: bitta ekran bo\'lagida BITTA pushti element. '
            'Pushti — asosiy amal va narx, boshqa hech nima emas.',
            style: _label,
          ),
          const SizedBox(height: 24),

          const SectionTitle('Imzo — yo\'l chizig\'i'),
          const SizedBox(height: 14),
          Panel(
            child: RouteLine(
              from: 'Toshkent, Chilonzor',
              to: 'Samarqand, Registon',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Shu shakl kartada ham, sarlavhada ham, bo\'sh holatda ham '
            'takrorlanadi — ilovani bir qarashda tanitadi.',
            style: _label,
          ),
          const SizedBox(height: 24),

          const SectionTitle('Tugmalar va nishonlar'),
          const SizedBox(height: 14),
          const PrimaryButton('Joy band qilish'),
          const SizedBox(height: 10),
          const PrimaryButton('Joy band qilish', enabled: false),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: _inkSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'O\'chiq tugma DOIM sababini aytadi',
                  style: _label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Pill('3 joy bo\'sh'),
              Pill('2 joy qoldi', tone: _pink, soft: Color(0xFFFDE8F3)),
              Pill('Tekshirilgan'),
              Pill(
                'Moderatsiyada',
                tone: Color(0xFF8A7F86),
                soft: Color(0xFFEFEBEE),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const SectionTitle('Oraliqlar'),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _spaceRow('Ekran chekkasi', 20),
                _spaceRow('Bo\'limlar orasi', 24),
                _spaceRow('Karta ichi', 16),
                _spaceRow('Qatorlar orasi', 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _swatch(Color c, String name) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 10.5, color: _inkSoft)),
        ],
      ),
    ),
  );

  static Widget _spaceRow(String name, double v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(width: 130, child: Text(name, style: _label)),
        Container(width: v, height: 10, color: _turqSoft),
        const SizedBox(width: 8),
        Text('${v.toInt()}', style: _micro),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
// 2. BOSH EKRAN — qidiruv
//
// Fikri: bosh ekranning vazifasi BITTA — «qayerdan qayerga». Shuning
// uchun u forma emas, BAYONOT bo'lib turadi: katta sarlavha, ostida
// yo'l chizig'i ko'rinishidagi ikkita maydon, keyin bitta tugma.
// Ostida — oxirgi yo'nalishlar (bir bosishda takrorlash).
// ══════════════════════════════════════════════════════════════════

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(_pad, 52, _pad, 26),
            decoration: const BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Salom, Abdurahmon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.notifications_none,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Qayerga\nboramiz?',
                  style: _display.copyWith(color: Colors.white, fontSize: 32),
                ),
                const SizedBox(height: 22),
                // Qidiruv — yo'l chizig'i ko'rinishida
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      RouteLine(
                        from: 'Toshkent',
                        to: 'Samarqand',
                        gap: 18,
                        style: _h2.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: _line),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 17,
                            color: _inkSoft,
                          ),
                          const SizedBox(width: 8),
                          Text('Ertaga, 3-sentabr', style: _body),
                          const Spacer(),
                          const Icon(
                            Icons.person_outline,
                            size: 17,
                            color: _inkSoft,
                          ),
                          const SizedBox(width: 6),
                          Text('1 kishi', style: _body),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const PrimaryButton('Safar qidirish', icon: Icons.search),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: _pad),
            child: SectionTitle('Tez-tez boradigan yo\'llaringiz'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _pad),
              children: const [
                _RouteChip('Toshkent', 'Samarqand', '12 ta safar'),
                _RouteChip('Toshkent', 'Namangan', '5 ta safar'),
                _RouteChip('Buxoro', 'Toshkent', '2 ta safar'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Haydovchi bo\'ling'),
                const SizedBox(height: 12),
                Panel(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _turqSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_outlined,
                          color: _turq,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bo\'sh o\'rindiqlaringiz bormi?',
                              style: _h2.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text('Yo\'l xarajatini bo\'lishing', style: _label),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: _inkSoft),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip(this.from, this.to, this.note);
  final String from, to, note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _pink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _h2.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Container(width: 2, height: 10, color: _line),
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _turq,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  to,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _h2.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(note, style: _micro.copyWith(letterSpacing: 0)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 3. SAFAR TAFSILOTI — bron qilish
//
// Fikri: bu ekranda odam BITTA qaror qabul qiladi. Shuning uchun
// narx va tugma pastda QOTIB turadi, tepada esa qaror uchun kerakli
// uch narsa: qachon/qayerdan-qayerga, kim olib ketadi, qanday shart.
// ══════════════════════════════════════════════════════════════════

class _TripScreen extends StatelessWidget {
  const _TripScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(_pad, 46, _pad, 20),
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_back, size: 22, color: _ink),
                    const Spacer(),
                    const Icon(Icons.ios_share, size: 20, color: _inkSoft),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.emergency_outlined,
                      size: 20,
                      color: const Color(0xFFE63946),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ERTAGA', style: _micro),
                          const SizedBox(height: 2),
                          Text('09:30', style: _display),
                        ],
                      ),
                    ),
                    Pill('4 soat yo\'l'),
                  ],
                ),
                const SizedBox(height: 20),
                Panel(
                  child: RouteLine(
                    from: 'Toshkent, Chilonzor tumani',
                    to: 'Samarqand, Registon maydoni',
                    gap: 20,
                  ),
                ),
                const SizedBox(height: 22),
                const SectionTitle('Haydovchi'),
                const SizedBox(height: 12),
                Panel(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _turqSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'A',
                          style: _h1.copyWith(color: _turq, fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Abdurahmon R.',
                              style: _h2.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFF5A623),
                                ),
                                const SizedBox(width: 3),
                                Text('4.8 · 37 sharh', style: _label),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionTitle('O\'rindiqlar'),
                const SizedBox(height: 12),
                Panel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const _Seat(taken: false, driver: true),
                          const SizedBox(width: 14),
                          const _Seat(taken: false, selected: true),
                          const Spacer(),
                          Text('4 tadan 2 tasi bo\'sh', style: _label),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          _Seat(taken: true),
                          SizedBox(width: 6),
                          _Seat(taken: true),
                          SizedBox(width: 6),
                          _Seat(taken: false),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionTitle('Shartlar'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Pill(
                      'Chekilmaydi',
                      tone: Color(0xFF564E54),
                      soft: Color(0xFFEFEBEE),
                    ),
                    Pill(
                      'Konditsioner',
                      tone: Color(0xFF564E54),
                      soft: Color(0xFFEFEBEE),
                    ),
                    Pill(
                      'Yuk joyi bor',
                      tone: Color(0xFF564E54),
                      soft: Color(0xFFEFEBEE),
                    ),
                    Pill(
                      'Narx kelishiladi',
                      tone: Color(0xFF564E54),
                      soft: Color(0xFFEFEBEE),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pastki panel — narx va amal DOIM ko'rinadi
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _line)),
            ),
            padding: const EdgeInsets.fromLTRB(_pad, 14, _pad, 22),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1 o\'rin uchun', style: _label),
                        const SizedBox(height: 2),
                        Text(
                          '150 000 so\'m',
                          style: _h1.copyWith(color: _pink, fontSize: 24),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.remove, size: 18, color: _inkSoft),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('1', style: _h2.copyWith(fontSize: 16)),
                          ),
                          const Icon(Icons.add, size: 18, color: _ink),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const PrimaryButton('Joy band qilish'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({this.taken = false, this.selected = false, this.driver = false});
  final bool taken, selected, driver;

  @override
  Widget build(BuildContext context) {
    if (driver) {
      return const SizedBox.square(
        dimension: 34,
        child: Icon(Icons.airline_seat_recline_extra, size: 22, color: _line),
      );
    }
    return SizedBox.square(
      dimension: 34,
      child: Icon(
        Icons.event_seat,
        size: 22,
        color: selected
            ? _pink
            : taken
            ? const Color(0xFFCFC7CC)
            : _turq,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 4. HOLATLAR — bo'sh, yuklanish, xato, offline
//
// 🔴 Hozir ilovada bular ko'pincha bitta kulrang jumla. Holat —
// ekranning eng ko'p ko'riladigan qismi bo'lishi mumkin (birinchi
// ochilish, tarmoq yo'q, natija chiqmadi), shuning uchun u ham
// CHIZILGAN bo'lishi kerak.
// ══════════════════════════════════════════════════════════════════

class _StatesScreen extends StatelessWidget {
  const _StatesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(_pad, 46, _pad, 32),
        children: [
          Text('Holatlar', style: _display),
          const SizedBox(height: 24),

          const SectionTitle('Natija yo\'q'),
          const SizedBox(height: 12),
          Panel(
            padding: 22,
            child: Column(
              children: [
                SizedBox(
                  height: 62,
                  child: CustomPaint(
                    size: const Size(120, 62),
                    painter: _EmptyRoute(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Bu kunga safar yo\'q',
                  style: _h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Ertangi kunni ko\'ring yoki yo\'nalishga obuna bo\'ling — '
                  'safar chiqsa xabar beramiz.',
                  style: _label,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const PrimaryButton('Yo\'nalishga obuna bo\'lish'),
                const SizedBox(height: 8),
                Text(
                  'Ertangi kunni ko\'rish',
                  style: _label.copyWith(
                    color: _pink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const SectionTitle('Yuklanmoqda'),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                for (var i = 0; i < 2; i++) ...[
                  Row(
                    children: [
                      _bone(38, 38, r: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bone(double.infinity, 11),
                            const SizedBox(height: 8),
                            _bone(140, 11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _bone(58, 14),
                    ],
                  ),
                  if (i == 0) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          const SectionTitle('Aloqa yo\'q'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E0),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 20,
                  color: Color(0xFFB07A16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Internet yo\'q',
                        style: _h2.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF6B4A0B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Oxirgi yangilanish: 14:20 · saqlangan ro\'yxat',
                        style: _label.copyWith(
                          color: const Color(0xFF8A6A2A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const SectionTitle('Xato'),
          const SizedBox(height: 12),
          Panel(
            padding: 20,
            child: Column(
              children: [
                Text(
                  'Safarlarni yuklab bo\'lmadi',
                  style: _h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Aloqa tiklangach qayta urinib ko\'ring.',
                  style: _label,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Qayta urinish',
                    style: _h2.copyWith(fontSize: 14, color: _ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bone(double w, double h, {double r = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFFEDE8EB),
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

/// Bo'sh holat uchun imzo — uzilgan yo'l chizig'i.
class _EmptyRoute extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = Offset(cx, 8);
    final bottom = Offset(cx, size.height - 8);
    final dash = Paint()
      ..color = _line
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    var y = top.dy + 10;
    while (y < bottom.dy - 10) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 5), dash);
      y += 11;
    }
    canvas.drawCircle(top, 6, Paint()..color = _pink.withValues(alpha: 0.35));
    canvas.drawCircle(
      bottom,
      6,
      Paint()..color = _turq.withValues(alpha: 0.45),
    );
    // yon tomonlarda sokin nurlar — «izlayapmiz» hissi
    final ray = Paint()
      ..color = _line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final a = math.pi / 4 + i * 0.35;
      canvas.drawLine(
        Offset(cx + 22 + i * 10, size.height / 2 - math.sin(a) * 10),
        Offset(cx + 30 + i * 10, size.height / 2 - math.sin(a) * 10),
        ray,
      );
      canvas.drawLine(
        Offset(cx - 22 - i * 10, size.height / 2 + math.sin(a) * 10),
        Offset(cx - 30 - i * 10, size.height / 2 + math.sin(a) * 10),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
