import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yolyolakay/app/theme.dart';

import 'support/preview_fonts.dart';

/// UCHTA DIZAYN YO'NALISHI — egasi KO'Z BILAN tanlashi uchun.
///
/// 🔴 NEGA (egasi, 2026-09-02): «ilovamiz oldindan kelishib ko'rilmagan,
/// palapartish qurilgan — buni senior mobil dasturchidek juda go'zal
/// holatga olib kelish kerak».
///
/// Landing shu yo'l bilan tuzatilgandi: gap bilan emas, RASM bilan.
/// Shuning uchun bu yerda ilovaning eng ko'p ochiladigan ekrani —
/// qidiruv natijalari — uchta boshqa-boshqa tilda chiziladi. Egasi
/// bittasini tanlaydi, keyin o'sha til butun ilovaga tarqaladi.
///
/// ⚠️ Bu fayl ILOVA KODIGA TEGMAYDI. Uchala variant ham shu yerda,
/// alohida vidjetlar sifatida yashaydi — tanlanmaganlari o'chiriladi.
///
///   flutter test test/design_directions_preview.dart --update-goldens
///   → style_preview/design/*.png
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  Future<void> shoot(WidgetTester tester, String name, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: withPreviewFont(buildTheme(brightness: Brightness.light)),
        home: screen,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/design/$name.png'),
    );
  }

  testWidgets(
    'A — Chipta',
    (t) => shoot(t, 'yonalish_A_chipta', const _TicketDirection()),
  );
  testWidgets(
    'B — Suzani',
    (t) => shoot(t, 'yonalish_B_suzani', const _SuzaniDirection()),
  );
  testWidgets(
    'C — Toza',
    (t) => shoot(t, 'yonalish_C_toza', const _QuietDirection()),
  );
}

// ══════════════════════════════════════════════════════════════════
// UMUMIY MA'LUMOT — uchala variantda BIR XIL, farq faqat dizaynda
// ══════════════════════════════════════════════════════════════════

class _Trip {
  const _Trip(
    this.time,
    this.from,
    this.to,
    this.price,
    this.seats,
    this.driver,
    this.rating,
  );
  final String time, from, to, driver;
  final int price, seats;
  final double rating;
}

const _trips = [
  _Trip(
    'Ertaga 09:30',
    'Toshkent, Chilonzor',
    'Samarqand, Registon',
    150000,
    2,
    'Abdurahmon',
    4.8,
  ),
  _Trip(
    'Ertaga 14:00',
    'Toshkent, Yunusobod',
    'Samarqand, Universitet',
    120000,
    1,
    'Dilnoza',
    5.0,
  ),
  _Trip(
    '3-sentabr 07:15',
    'Toshkent, Sergeli',
    'Samarqand, Siyob',
    135000,
    3,
    'Jasur',
    4.6,
  ),
];

String _money(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

const _wine = Color(0xFF32292F);
const _pink = Color(0xFFE91E8C);
const _turq = Color(0xFF99E1D9);
const _soft = Color(0xFFF7F5F6);

// ══════════════════════════════════════════════════════════════════
// A — «CHIPTA»: safar = yo'l chiptasi
//
// Fikri: shaharlararo safar — bu bilet olish hissi. Karta chetlari
// O'YILGAN (kompostyor teshigi), o'rtasida punktir, chap tomonda
// VAQT ustuni, o'ngda narx. To'q sarlavha bloki safar yo'nalishini
// bayonot qilib qo'yadi.
// ══════════════════════════════════════════════════════════════════

class _TicketDirection extends StatelessWidget {
  const _TicketDirection();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _soft,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // To'q sarlavha — yo'nalish bayonoti
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 22),
            decoration: const BoxDecoration(
              color: _wine,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Filtr · 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Toshkent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Container(width: 34, height: 2, color: _turq),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: _turq, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Samarqand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '3-sentabr · 12 ta safar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final t in _trips) _TicketCard(trip: t),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.trip});
  final _Trip trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: CustomPaint(
        painter: _TicketShape(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chap ustun — VAQT
              SizedBox(
                width: 62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.time.split(' ').last,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _wine,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.time.split(' ').first,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A7F86),
                      ),
                    ),
                  ],
                ),
              ),
              // Punktir — chipta buklanadigan joy
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 1,
                  height: 74,
                  child: CustomPaint(painter: _Dashed()),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.from,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _wine,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                trip.to,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _wine,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_money(trip.price)} so\'m',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _pink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: _turq.withValues(alpha: 0.35),
                          child: Text(
                            trip.driver[0],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _wine,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          trip.driver,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF564E54),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFF5A623),
                        ),
                        Text(
                          trip.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF564E54),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: trip.seats <= 2
                                ? _pink.withValues(alpha: 0.10)
                                : _turq.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${trip.seats} joy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: trip.seats <= 2
                                  ? _pink
                                  : const Color(0xFF1F6B62),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chipta shakli — yon chetlarida kompostyor o'yig'i.
class _TicketShape extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 18.0;
    const notch = 9.0;
    final y = size.height * 0.5;
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, y - notch)
      ..arcToPoint(
        Offset(size.width, y + notch),
        radius: const Radius.circular(notch),
        clockwise: false,
      )
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: const Radius.circular(r),
      )
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r), radius: const Radius.circular(r))
      ..lineTo(0, y + notch)
      ..arcToPoint(
        Offset(0, y - notch),
        radius: const Radius.circular(notch),
        clockwise: false,
      )
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..close();
    canvas.drawShadow(path, _wine.withValues(alpha: 0.5), 4, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Dashed extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE0D9DE)
      ..strokeWidth = 1.2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 4), p);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════
// B — «SUZANI»: milliy naqsh TUZILMA sifatida
//
// Fikri: naqsh fon bo'lib yotmaydi — u shakl beradi. Haydovchi surati
// PESHTOQ (madrasa ravog'i) shaklida kesiladi, bo'lim sarlavhasi paxta
// guli bilan ochiladi, kartalar orasida ingichka jiyak yuradi.
// Ranglar iliq: zamin sarg'ish-oq, aksent pushti va feruza.
// ══════════════════════════════════════════════════════════════════

class _SuzaniDirection extends StatelessWidget {
  const _SuzaniDirection();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F4),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              // Girih to'ri — juda sokin, mazmunni bosmaydi
              Positioned.fill(child: CustomPaint(painter: _GirihGrid())),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 22, color: _wine),
                        const Spacer(),
                        _PakhtaMark(
                          size: 16,
                          color: _pink.withValues(alpha: .5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ⚠️ `RichText` tema shriftini MEROS OLMAYDI — unga
                    // `fontFamily` bermasak, matn tizim shriftida (testda
                    // esa to'ldirilgan to'rtburchak bo'lib) chiziladi.
                    // `Text.rich` esa `DefaultTextStyle` dan meros oladi.
                    Text.rich(
                      const TextSpan(
                        children: [
                          TextSpan(text: 'Toshkent — '),
                          TextSpan(
                            text: 'Samarqand',
                            style: TextStyle(color: _pink),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: _wine,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '3-sentabr · 12 ta safar topildi',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7A6E74)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(height: 10, child: CustomPaint(painter: _Jiyak())),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _trips.length; i++) ...[
            _SuzaniCard(trip: _trips[i]),
            if (i != _trips.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: SizedBox(
                  height: 12,
                  child: CustomPaint(painter: _Jiyak()),
                ),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SuzaniCard extends StatelessWidget {
  const _SuzaniCard({required this.trip});
  final _Trip trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE4DC)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PESHTOQ — surat ravoq shaklida kesiladi
                ClipPath(
                  clipper: _PeshtoqClip(),
                  child: Container(
                    width: 46,
                    height: 58,
                    color: _turq.withValues(alpha: 0.35),
                    alignment: Alignment.center,
                    child: Text(
                      trip.driver[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _wine,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            trip.time,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7A6E74),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_money(trip.price)} so\'m',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _pink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _RouteLine(from: trip.from, to: trip.to),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PakhtaMark(size: 13, color: _turq),
                const SizedBox(width: 6),
                Text(
                  '${trip.driver} · ${trip.rating}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF564E54),
                  ),
                ),
                const Spacer(),
                Text(
                  '${trip.seats} joy bo\'sh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: trip.seats <= 2 ? _pink : const Color(0xFF1F6B62),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.from, required this.to});
  final String from, to;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _pink,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 1.5, height: 16, color: const Color(0xFFE6DED8)),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _turq,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _wine,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                to,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _wine,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Peshtoq ravog'i — yuqorisi o'tkir kamar, pastki burchaklar to'g'ri.
class _PeshtoqClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.42)
      ..quadraticBezierTo(0, h * 0.10, w * 0.5, 0)
      ..quadraticBezierTo(w, h * 0.10, w, h * 0.42)
      ..lineTo(w, h)
      ..close();
  }

  @override
  bool shouldReclip(_) => false;
}

/// Paxta guli — beshta yaproq va markaz.
class _PakhtaMark extends StatelessWidget {
  const _PakhtaMark({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _Pakhta(color)),
  );
}

class _Pakhta extends CustomPainter {
  _Pakhta(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final p = Paint()..color = color;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(math.cos(a), math.sin(a)) * r * 0.45,
          width: r * 0.85,
          height: r * 1.15,
        ),
        p,
      );
    }
    canvas.drawCircle(c, r * 0.28, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Jiyak — ikkita to'lqin bir-biriga o'ralgan ingichka hoshiya.
class _Jiyak extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _turq.withValues(alpha: 0.75);
    for (final dir in [1.0, -1.0]) {
      final path = Path()..moveTo(0, size.height / 2);
      const step = 16.0;
      for (var x = 0.0; x < size.width; x += step) {
        path.relativeQuadraticBezierTo(
          step / 2,
          dir * size.height / 2.2,
          step,
          0,
        );
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Girih to'ri — sakkiz nurli yulduzlar to'ri, juda sokin.
class _GirihGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _wine.withValues(alpha: 0.05);
    const cell = 46.0;
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            c + Offset(math.cos(a), math.sin(a)) * cell * 0.34,
            c - Offset(math.cos(a), math.sin(a)) * cell * 0.34,
            p,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════
// C — «TOZA»: sokin, tez, raqamlar hukmron
//
// Fikri: karta ham, ramka ham yo'q. Faqat havo, ingichka ajratgich va
// KATTA tipografika. Rang holat uchun tejab ishlatiladi — «oxirgi
// joylar» dan boshqa hech nima pushti emas. Bunday ro'yxat ko'z bilan
// eng tez skanerlanadi va ilova YENGIL his qilinadi.
// ══════════════════════════════════════════════════════════════════

class _QuietDirection extends StatelessWidget {
  const _QuietDirection();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 56, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_back, size: 22, color: _wine),
                    const Spacer(),
                    Text(
                      'Filtr',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _wine.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Toshkent —\nSamarqand',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.08,
                    letterSpacing: -0.8,
                    fontWeight: FontWeight.w800,
                    color: _wine,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '3-sentabr · 12 ta safar',
                  style: TextStyle(
                    fontSize: 14,
                    color: _wine.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
          for (var i = 0; i < _trips.length; i++) ...[
            _QuietRow(trip: _trips[i]),
            if (i != _trips.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF0EDEF),
                ),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuietRow extends StatelessWidget {
  const _QuietRow({required this.trip});
  final _Trip trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _wine.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Text(
                _money(trip.price),
                style: const TextStyle(
                  fontSize: 22,
                  height: 1,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w800,
                  color: _wine,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'so\'m',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _wine.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trip.from,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: _wine,
            ),
          ),
          Text(
            trip.to,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: _wine.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                trip.driver,
                style: TextStyle(
                  fontSize: 13,
                  color: _wine.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.star_rounded,
                size: 14,
                color: _wine.withValues(alpha: 0.35),
              ),
              Text(
                trip.rating.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: _wine.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (trip.seats <= 2)
                Text(
                  '${trip.seats} joy qoldi',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _pink,
                  ),
                )
              else
                Text(
                  '${trip.seats} joy',
                  style: TextStyle(
                    fontSize: 13,
                    color: _wine.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
