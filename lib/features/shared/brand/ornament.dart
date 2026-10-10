import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'atlas.dart';

/// O'ZBEK NAQSHLARI — dizayn tili, bezak emas.
///
/// 🔴 NEGA YOZILDI (2026-09-03): saytda bu yo'l bosib o'tilgan va egasi
/// uni yetti to'lqinda sayqallagan, ILOVA esa o'sha yerda qolgandi.
/// Ilovada milliylikdan atigi uchta narsa bor edi: suzani avatari,
/// rozetkali ajratgich va profil sarlavhasidagi ROMB teksturasi —
/// aynan egasi saytda «romb har madaniyatda bor» deb OLIB TASHLATGAN
/// motiv. Qolgan hamma ekran har qanday yevropa ilovasiniki bo'lishi
/// mumkin edi.
///
/// Bu fayl `src/shared/ui/brand/Ornament.tsx` ning ko'chirmasi emas,
/// TARJIMASI: SVG naqshlari Flutter `CustomPainter` iga o'giriladi va
/// saytda o'lchab topilgan qoidalar shu yerda ham amal qiladi.
///
///   • GIRIH        — o'ralgan tasma (xatam tuguni). Zamin naqshi.
///   • GANCH        — o'sha girih, lekin YORUG' zaminda: rang bilan
///                    emas, soya va qirra bilan ko'rinadi.
///   • PAXTA        — paxta guli. Bo'lim belgisi va ro'yxat nuqtasi.
///   • PESHTOQ      — madrasa ravog'i. Surat SHU SHAKLDA kesiladi.
///   • ISLIMI       — o'simlik novdasi. Bo'lim ajratgichi.
///   • QO'CHQOR SHOXI — juft burama. Qadam raqami medalyoni.
///   • PALAK        — so'zana rozetkasi. Katta, xira suv belgisi.
///   • MUQARNAS     — asal uyasi qatori. Zamindan zaminga O'TISH.
///
/// ⚠️ HAMMASI BITTA QOIDAGA BO'YSUNADI: naqsh mazmunni bosmaydi.
/// Zaminda quyuqlik 0.10 dan oshmaydi, ravoq esa suratni KESADI —
/// ustiga chiqmaydi.
///
/// ═══════════════════════════════════════════════════════════════════
///  NAQSH NIZOMI — HAR ELEMENTNING O'Z JOYI BOR
/// ═══════════════════════════════════════════════════════════════════
///
/// 🔴 NEGA YOZILDI (10.09.2026). Egasi ilovaga qarab «hunuk bo'lib
/// qolgan» dedi. Sabab naqshning O'ZIDA emas — TARTIBSIZLIGIDA edi:
///
///   • ikat ipi (`JiyakLine`) `AppBar.bottom` da 17 ta ekranda turardi,
///     VA `BottomActionBar` ichida ham bittasi bor edi. Ya'ni bitta
///     ekranda ip IKKI MARTA chiqib, ekranni tasma-tasma qilib
///     kesardi (safar tafsiloti ekranida ochiq ko'rindi);
///   • girih `cell: 96` da telefon enida o'n bir marta takrorlanardi —
///     bu tugun emas, TO'R edi, va `alpha: 0.11` uni kontentdan
///     balandroq ovozda chiqarardi.
///
/// Naqsh olib tashlanmadi va tashlanmaydi — u ilovaning o'zligi.
/// Uning o'rniga NIZOM yozildi:
///
/// ⚠️ ATLAS IPINING IKKI ROLI BOR — nizom yozilayotganda aniqlandi:
///
///   1. SAHIFA TIKUVI (`JiyakLine`) — sarlavha panelining ostida.
///      Ilovaning imzosi. Har ekranda BITTA.
///   2. BUYUM JIYAGI — o'zi yopiq buyumning ICHIDAGI ip: tarif
///      hujjati, safar pasporti, plakat, bo'sh holat nishoni. U
///      buyumga tegishli, sahifaga emas — masalan tarif kartasi
///      «xabar emas, HUJJAT» bo'lishi uchun pastida jiyak turadi.
///
/// Ya'ni taqiqlangan narsa — YALANG'OCH ip: biror buyum ichida
/// bo'lmagan, sahifa bo'ylab cho'zilgan ikkinchi tikuv.
///
/// ┌────────────────┬──────────────────────────┬──────────────────┐
/// │ Element        │ Yagona joyi              │ Ekranda necha    │
/// ├────────────────┼──────────────────────────┼──────────────────┤
/// │ Sahifa tikuvi  │ `AppBar.bottom`          │ 1 marta          │
/// │ Buyum jiyagi   │ Card / nishon / plakat   │ buyum bilan      │
/// │ Girih          │ zamin to'qimasi          │ 2 marta*         │
/// │ Muqarnas       │ peshtoq→kontent o'tishi  │ 1 marta          │
/// │ Peshtoq ramkasi│ hero va bo'sh holat      │ buyum bilan      │
/// │ Palak rozetkasi│ faqat hero burchagi      │ 1 marta          │
/// │ Suzani         │ avatar va tab ikonkalari │ cheksiz          │
/// │ LoomLoader     │ faqat yuklanish          │ —                │
/// └────────────────┴──────────────────────────┴──────────────────┘
///
/// * Girih ikkita bo'lishi mumkin, lekin faqat HAR ZAMIN UCHUN BITTA:
///   to'q peshtoqda girih, yorug' tanada ganch. Bular bir motivning
///   ikki ko'rinishi (`GanchPattern` — `GirihPattern` ning nomli
///   konstruktori), shuning uchun bu takror emas. Uchinchisi esa
///   allaqachon shovqin.
///
/// Suzani cheksiz, chunki u BEZAK EMAS — u ma'lumot: har bir odamning
/// o'z muhri, har bir bo'limning o'z ikonkasi.
///
/// Girih to'qimasining quyuqligi `0.08` dan oshmasin — undan yuqorisi
/// kontent bilan raqobatlashadi.
///
/// 🔑 Bu nizom `test/ornament_discipline_test.dart` da QO'RIQLANADI:
/// u har bir ekranni chizib, yuqoridagi sonlarni sanaydi. Yangi ekran
/// yozganda nizomni eslash shart emas — test o'zi aytadi.

// ═══════════════════════════════════════════════════════════════════
//  NAQSH RANGLARI — TOKEN, qotirilgan qiymat EMAS
// ═══════════════════════════════════════════════════════════════════

/// Naqsh ranglari — temaning bir qismi.
///
/// 🔴 NEGA THEME EXTENSION (saytda o'lchab topilgan xato, 2026-08-31):
/// relyef ranglari `rgba(255,255,255,0.95)` deb QOTIRIB yozilgandi va
/// TUNGI rejimda butun sahifa oq to'r bilan qoplanib, matn umuman
/// o'qilmay qolgandi. Ilovada bu yanada xavfliroq: bu yerda temaning
/// BESHTA kombinatsiyasi bor (classic/neon × yorug'/tungi, plus amber).
/// Shuning uchun naqsh rangi hech qachon vidjetda hisoblanmaydi — u
/// temadan olinadi va `test/ornament_test.dart` buni qo'riqlaydi.
@immutable
class OrnamentTokens extends ThemeExtension<OrnamentTokens> {
  const OrnamentTokens({
    required this.band,
    required this.cut,
    required this.reliefShadow,
    required this.reliefLight,
    required this.reliefCore,
    required this.threads,
  });

  /// Tasma rangi — to'q zaminda ko'rinadigan girih.
  final Color band;

  /// KESIM — tasma pastdan o'tayotganini uzib ko'rsatadigan rang.
  ///
  /// ⚠️ ZAMIN RANGI BILAN BIR XIL bo'lishi SHART. Aks holda tasma
  /// uzilgan joyda begona dog' qoladi va naqsh «singan chiziq» bo'lib
  /// ko'rinadi (saytda aynan shunday bo'lgan).
  final Color cut;

  /// O'yiq soyasi (relyef pastki qatlami).
  final Color reliefShadow;

  /// O'yiq qirrasining yorug'i.
  final Color reliefLight;

  /// O'zak — relyefning o'zi, juda xira.
  final Color reliefCore;

  /// TO'QUV TERMALARI — jiyak va mato uchun uchta variant.
  ///
  /// Uslubga qarab almashadi: klassikda xonatlas, tungi haydashda
  /// faqat issiq ranglar, neonda pushti/cyan. Tuzilma o'zgarmaydi.
  final List<AtlasPalette> threads;

  /// Temadan olish. Kengaytma yo'q bo'lsa (masalan begona `ThemeData`
  /// bilan qurilgan test) — zamin rangidan hisoblanadi, ya'ni naqsh
  /// hech qachon YO'QOLMAYDI va hech qachon buzilmaydi.
  static OrnamentTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<OrnamentTokens>() ?? forTheme(theme);
  }

  /// Tema ranglaridan naqsh tokenlarini hosil qiladi.
  ///
  /// Yagona manba: `buildTheme` ham shuni chaqiradi, tasodifiy
  /// `ThemeData` ham shu yerga tushadi — ikki xil natija bo'lmaydi.
  static OrnamentTokens forTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return OrnamentTokens(
      band: scheme.onSurface.withValues(alpha: dark ? 0.13 : 0.10),
      cut: scheme.surface,
      // Qorong'ida soya QORA bo'ladi (o'yiq chuqurroq ko'rinadi),
      // yorug'da esa matn rangining xira qatlami.
      reliefShadow: dark
          ? Colors.black.withValues(alpha: 0.34)
          : scheme.onSurface.withValues(alpha: 0.105),
      // 🔴 Qorong'ida qirra XIRA oq: to'la oq bo'lsa naqsh matnni yeydi.
      reliefLight: dark
          ? Colors.white.withValues(alpha: 0.055)
          : Colors.white.withValues(alpha: 0.90),
      reliefCore: scheme.onSurface.withValues(alpha: dark ? 0.025 : 0.045),
      threads: AtlasPalette.all,
    );
  }

  @override
  OrnamentTokens copyWith({
    Color? band,
    Color? cut,
    Color? reliefShadow,
    Color? reliefLight,
    Color? reliefCore,
    List<AtlasPalette>? threads,
  }) => OrnamentTokens(
    band: band ?? this.band,
    cut: cut ?? this.cut,
    reliefShadow: reliefShadow ?? this.reliefShadow,
    reliefLight: reliefLight ?? this.reliefLight,
    reliefCore: reliefCore ?? this.reliefCore,
    threads: threads ?? this.threads,
  );

  @override
  OrnamentTokens lerp(ThemeExtension<OrnamentTokens>? other, double t) {
    if (other is! OrnamentTokens) return this;
    return OrnamentTokens(
      band: Color.lerp(band, other.band, t)!,
      cut: Color.lerp(cut, other.cut, t)!,
      reliefShadow: Color.lerp(reliefShadow, other.reliefShadow, t)!,
      reliefLight: Color.lerp(reliefLight, other.reliefLight, t)!,
      reliefCore: Color.lerp(reliefCore, other.reliefCore, t)!,
      // Terma — ro'yxat, oraliq qiymati yo'q: yarim yo'lda kuchliroq
      // tomonnikini olamiz.
      threads: t < 0.5 ? threads : other.threads,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GIRIH — HAQIQIY O'RALGAN TASMA (xatam tuguni)
// ═══════════════════════════════════════════════════════════════════

/// Girih naqshi — Temuriylar davrining «xatam» tuguni.
///
/// 🔑 SAYTDA O'RGANILGAN DARS (egasi, 2026-08-31: «san o'zbek
/// naqshlarini olmagansan, shunchaki yulduz chizib qo'yibsan»):
/// haqiqiy girihda yulduz CHIZILMAYDI. U tasmalarning kesishuvidan
/// kelib chiqadi:
///
///   • naqsh uzluksiz TASMALARDAN yig'iladi — chiziq emas, eni bor
///     lenta (shuning uchun har lentaning ikkita qirrasi bor);
///   • tasmalar bir-birining goh ustidan, goh ostidan o'tadi;
///   • yulduz — o'ralishlar orasida QOLGAN bo'shliq.
///
/// Texnikasi: tasma ikki marta chiziladi — avval ZAMIN rangida keng
/// («kesim»), keyin ustidan ingichka rang. Kesim pastdan o'tayotgan
/// tasmani uzib ko'rsatadi.
///
/// ⚠️ Katak MAYDA bo'lsin (~90–120 px). Yirik qilsang naqsh emas,
/// «katta sakkizburchaklar» bo'lib qoladi.
class GirihPattern extends StatelessWidget {
  /// ⚠️ [color] SHAFFOF berilsin (`withValues(alpha: …)`).
  ///
  /// 🔴 O'LCHAB TOPILGAN XATO (2026-09-03): eski `IkatTexture` quyuqlikni
  /// O'ZI qo'shardi (`opacity: 0.06`), shuning uchun chaqiruvchilar
  /// rangni TO'LIQ berardi. Almashtirishda o'sha chaqiruvlar shundoq
  /// ko'chirilgan va profil sarlavhasi butunlay to'q-feruza panjara
  /// bilan qoplanib, ism ham, reyting ham O'QILMAY qolgandi.
  const GirihPattern({
    super.key,
    this.color,
    this.cut,
    this.opacity = 1,
    this.cell = 104,
    this.relief = false,
  });

  /// Yorug' zamin uchun — ganch o'ymasi rejimi.
  const GirihPattern.ganch({
    super.key,
    this.cell = 104,
    double depth = 1,
    this.color,
    this.cut,
  }) : opacity = depth,
       relief = true;

  final Color? color;
  final Color? cut;
  final double opacity;

  /// Bitta tugun katagi (piksel).
  final double cell;

  /// Ganch rejimi — izohi [OrnamentTokens.reliefLight] da.
  final bool relief;

  @override
  Widget build(BuildContext context) {
    final tokens = OrnamentTokens.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GirihPainter(
            cell: cell,
            opacity: opacity,
            relief: relief,
            band: color ?? tokens.band,
            cut: cut ?? tokens.cut,
            reliefShadow: tokens.reliefShadow,
            reliefLight: tokens.reliefLight,
            reliefCore: tokens.reliefCore,
          ),
        ),
      ),
    );
  }
}

/// Ganch o'ymasi — [GirihPattern] ning yorug' zamin uchun nomi.
///
/// 🔑 YORUG' ZAMINDA NAQSHNI QUYUQLASHTIRMA (egasi, 2026-08-31:
/// «sayt oq bo'lganda naqshlar bilinmay qolyapti»). Quyuqlashtirsang
/// matnga raqib bo'ladi va sahifa iflos ko'rinadi. Buxoro va Samarqand
/// devorlarida ganch OQ ustiga OQ o'yiladi va u RANG bilan emas,
/// YORUG'LIK bilan ko'rinadi: o'yiq chetida soya, qirrasida yorug'
/// chiziq. O'rtacha yorqinligi zamin bilan bir xil — shuning uchun
/// matnni bosmaydi.
class GanchPattern extends StatelessWidget {
  const GanchPattern({super.key, this.cell = 104, this.depth = 1});

  final double cell;

  /// Relyef kuchi. Sarlavha blokida kuchli (1.0–1.1), mazmun
  /// bo'limlarida yengil (0.5–0.65) — aks holda kartalar naqsh bilan
  /// raqobat qiladi va ekran charchatadi.
  final double depth;

  @override
  Widget build(BuildContext context) =>
      GirihPattern.ganch(cell: cell, depth: depth);
}

/// Bitta tasma — cheksiz to'g'ri chiziq (nuqta + yo'nalish).
///
/// Girihda tasma katakning ichida tugamaydi: u butun panjara bo'ylab
/// o'tadi va boshqa tasmalar bilan kesishadi. Shuning uchun bu yerda
/// «katak» degan tushuncha yo'q — chiziqlar OILALARI bor.
class _Strap {
  const _Strap(this.origin, this.dir, this.family);

  final Offset origin;
  final Offset dir;

  /// 0 — tik, 1 — yotiq, 2 va 3 — diagonallar. Kesishuvda qaysi tasma
  /// ustidan o'tishini shu raqam hal qiladi.
  final int family;

  Offset at(double t) => origin + dir * t;
}

class _Crossing {
  const _Crossing(this.point, this.overDir, this.underDir);

  final Offset point;
  final Offset overDir;
  final Offset underDir;
}

/// Tayyor panjara — narxi qimmat, shuning uchun bir marta hisoblanadi.
class _Lattice {
  const _Lattice(this.straps, this.crossings, this.span);

  final List<_Strap> straps;
  final List<_Crossing> crossings;

  /// Har tasmaning ko'rinadigan uzunligi.
  final double span;
}

final Map<String, _Lattice> _latticeCache = {};

class _GirihPainter extends CustomPainter {
  _GirihPainter({
    required this.cell,
    required this.opacity,
    required this.relief,
    required this.band,
    required this.cut,
    required this.reliefShadow,
    required this.reliefLight,
    required this.reliefCore,
  });

  final double cell;
  final double opacity;
  final bool relief;
  final Color band;
  final Color cut;
  final Color reliefShadow;
  final Color reliefLight;
  final Color reliefCore;

  /// Tasma qalinligi katakka nisbatan.
  ///
  /// ⚠️ O'LCHAB TOPILDI: 0.052 da tasmalar qo'shni chiziqqa tegib
  /// ketardi (chiziqlar orasi atigi 0.29·S) va butun panjara «to'r»ga
  /// aylanib qolardi — sakkizburchak ko'rinmasdi.
  static const double _bandRatio = 0.032;

  /// Kesim tasmadan shuncha marta keng — tagidagi tasmani UZADI.
  ///
  /// ⚠️ Bu qiymat KO'NDALANG kenglik. Katta qo'yilsa kesim qo'shni
  /// kesishuvga yetib boradi va tasma butunlay yeyiladi: birinchi
  /// urinishda (2.7) naqsh uzuq-yuluq chiziqchalarga aylangandi.
  static const double _cutFactor = 1.9;

  /// XATAM PANJARASI — sakkizburchak va kichik kvadrat.
  ///
  /// 🔑 NEGA AYNAN SHU QURILISH (birinchi urinish rad etildi: u
  /// «sakkizburchak to'ri» bo'lib chiqqandi, girih emas).
  ///
  /// Haqiqiy girih FIGURALARDAN yig'ilmaydi — u CHIZIQLAR to'ridan
  /// kelib chiqadi. To'rtta oila bor va har biri butun panjara bo'ylab
  /// uzluksiz o'tadi:
  ///
  ///     tik      x = S·(k ± 0.1464)      — juft-juft, «kvadrat» yonlari
  ///     yotiq    y = S·(k ± 0.1464)
  ///     diagonal x + y = S·(m + 0.5)
  ///     diagonal x − y = S·(m + 0.5)
  ///
  /// Shu 4 oila kesishganda o'z-o'zidan hosil bo'ladi:
  ///   • katak MARKAZIDA — muntazam SAKKIZBURCHAK (xatam tuguni);
  ///   • katak BURCHAGIDA — kichik kvadrat (45° ga burilgan);
  ///   • ular orasida — cho'zinchoq «bodomcha» bo'shliqlar.
  ///
  /// Registon va Shohi Zinda panjaralarida aynan shu naqsh bor. Muhimi
  /// shundaki, HECH BIR shakl chizilmagan: hammasi tasmalar kesishuvidan
  /// «ochilgan» — girihni girih qiladigan narsa shu.
  static _Lattice _lattice(Size size, double cell) {
    final key = '${size.width}x${size.height}/$cell';
    final cached = _latticeCache[key];
    if (cached != null) return cached;

    final s = cell;
    final w = size.width;
    final h = size.height;
    // Chekkadan tashqarida ham chiziladi: naqsh ekran chetida uzilmasin.
    final pad = s;
    final straps = <_Strap>[];

    // Sakkizburchakning yon tomonlari — markazdan 0.3536·S da.
    // (Ikkita kvadratning ustma-ust tushishidan chiqadigan nisbat:
    // 1/(2√2). Boshqa qiymat olsang sakkizburchak muntazam bo'lmaydi.)
    const a = 0.35355339;

    for (var k = -1; k * s < w + pad; k++) {
      for (final d in const [a, 1 - a]) {
        straps.add(_Strap(Offset((k + d) * s, 0), const Offset(0, 1), 0));
      }
    }
    for (var k = -1; k * s < h + pad; k++) {
      for (final d in const [a, 1 - a]) {
        straps.add(_Strap(Offset(0, (k + d) * s), const Offset(1, 0), 1));
      }
    }
    const diag = math.sqrt1_2;
    // x + y = c
    for (var m = -1; (m + 0.5) * s < w + h + pad; m++) {
      straps.add(
        _Strap(Offset((m + 0.5) * s, 0), const Offset(-diag, diag), 2),
      );
    }
    // x − y = c
    for (var m = -(h / s).ceil() - 1; (m + 0.5) * s < w + pad; m++) {
      straps.add(_Strap(Offset((m + 0.5) * s, 0), const Offset(diag, diag), 3));
    }

    // ── KESISHUVLAR VA O'RALISH ────────────────────────────────────
    //
    // 🔑 O'ralish girihning MOHIYATI: tasma goh ustidan, goh ostidan
    // o'tadi. Shuning uchun har kesishuvda «kim ustidan» degan savolga
    // javob kerak va u IKKALA tasma uchun bir xil chiqishi shart —
    // aks holda bitta joyda ikkalasi ham «ustida» bo'lib qoladi va
    // naqsh yolg'on ko'rinadi.
    //
    // Qoida faqat NUQTAning o'ziga tayanadi (tasma tartibiga emas):
    // kesishuv koordinatasining panjaradagi juft-toqligi. Shu sababli
    // javob simmetrik va tasma bo'ylab navbatlashib boradi.
    final crossings = <_Crossing>[];
    final bounds = Rect.fromLTWH(-pad, -pad, w + 2 * pad, h + 2 * pad);
    for (var i = 0; i < straps.length; i++) {
      for (var j = i + 1; j < straps.length; j++) {
        final p = straps[i];
        final q = straps[j];
        final cross = p.dir.dx * q.dir.dy - p.dir.dy * q.dir.dx;
        if (cross.abs() < 1e-6) continue;
        final delta = q.origin - p.origin;
        final t = (delta.dx * q.dir.dy - delta.dy * q.dir.dx) / cross;
        final point = p.at(t);
        if (!bounds.contains(point)) continue;
        final n = ((point.dx + point.dy) / (s * 0.25)).round();
        final first = p.family < q.family;
        final pOver = n.isEven == first;
        crossings.add(
          _Crossing(point, pOver ? p.dir : q.dir, pOver ? q.dir : p.dir),
        );
      }
    }

    final lattice = _Lattice(straps, crossings, (w + h) * 2);
    // Kesh ekran o'lchamiga bog'liq — bir nechta o'lcham yetadi.
    if (_latticeCache.length > 12) _latticeCache.clear();
    _latticeCache[key] = lattice;
    return lattice;
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.butt;

  /// Bitta qatlam: hamma tasma chiziladi, so'ng kesishuvlarda pastdagi
  /// tasma UZILADI va ustidagisi qayta chiziladi.
  ///
  /// [cut] `null` bo'lsa o'ralish chizilmaydi — bu relyefning soya va
  /// qirra qatlamlari uchun: ular naqshning HAJMI, o'ralishi emas.
  void _weave(
    Canvas canvas,
    _Lattice lattice,
    Color color,
    Color? cutColor,
    double w,
    Offset shift,
  ) {
    canvas.save();
    canvas.translate(shift.dx, shift.dy);

    final bandPaint = _stroke(color, w);
    final half = lattice.span / 2;
    for (final strap in lattice.straps) {
      canvas.drawLine(strap.at(-half), strap.at(half), bandPaint);
    }

    if (cutColor != null) {
      final cutPaint = _stroke(cutColor, w * _cutFactor);
      // Uzilish UZUNLIGI: ustidagi tasma (eni `w`) 45° da o'tganda
      // pastdagini `w·√2` masofada to'sadi, ikki yonida esa zamin
      // ko'rinib turishi kerak — shundan 1.25·w.
      final len = w * 1.25;
      final overLen = len + w;
      for (final c in lattice.crossings) {
        canvas.drawLine(
          c.point - c.underDir * len,
          c.point + c.underDir * len,
          cutPaint,
        );
        canvas.drawLine(
          c.point - c.overDir * overLen,
          c.point + c.overDir * overLen,
          bandPaint,
        );
      }
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;
    final lattice = _lattice(size, cell);
    final w = _bandRatio * cell;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (opacity < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0, 1)),
      );
    }

    if (relief) {
      // GANCH: o'yiq soyasi (pastga surilgan) va qirrasining yorug'i
      // (tepaga surilgan), o'rtada xira o'zak. Naqsh RANG bilan emas,
      // YORUG'LIK bilan ko'rinadi — shuning uchun matnni bosmaydi.
      final d = 0.015 * cell;
      _weave(canvas, lattice, reliefShadow, null, w, Offset(d, d));
      _weave(canvas, lattice, reliefLight, null, w, Offset(-d, -d));
      _weave(canvas, lattice, reliefCore, cut, w, Offset.zero);
    } else {
      _weave(canvas, lattice, band, cut, w, Offset.zero);
    }

    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GirihPainter old) =>
      old.cell != cell ||
      old.opacity != opacity ||
      old.relief != relief ||
      old.band != band ||
      old.cut != cut ||
      old.reliefShadow != reliefShadow ||
      old.reliefLight != reliefLight ||
      old.reliefCore != reliefCore;
}

// ═══════════════════════════════════════════════════════════════════
//  PAXTA GULI — ochilgan ko'sak
// ═══════════════════════════════════════════════════════════════════

/// Paxta guli — o'zbek naqshining eng tanish belgisi.
///
/// Beshta yumaloq barg va o'rtada urug'. Ro'yxat nuqtasi, bo'lim
/// belgisi va tugma bezagi sifatida ishlatiladi — ya'ni ilova bo'ylab
/// TAKRORLANIB, uni bir butun qiladi.
///
/// ⚠️ 16 px gul «changdek» ko'rinadi — eng kichigi 20, qulayi 24–28.
class Pakhta extends StatelessWidget {
  const Pakhta({super.key, this.size = 24, this.color, this.petals = 5});

  final double size;
  final Color? color;
  final int petals;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.square(size),
      painter: _PakhtaPainter(
        color ?? Theme.of(context).colorScheme.primary,
        petals,
      ),
    ),
  );
}

class _PakhtaPainter extends CustomPainter {
  const _PakhtaPainter(this.color, this.petals);

  final Color color;
  final int petals;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 100;
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    for (var i = 0; i < petals; i++) {
      final a = 2 * math.pi * i / petals - math.pi / 2;
      path.addOval(
        Rect.fromCircle(
          center: center + Offset(34 * k * math.cos(a), 34 * k * math.sin(a)),
          radius: 21 * k,
        ),
      );
    }
    // Urug' — markazda, barglar bilan qo'shilib butun gulni beradi.
    path.addOval(Rect.fromCircle(center: center, radius: 13 * k));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PakhtaPainter old) =>
      old.color != color || old.petals != petals;
}

// ═══════════════════════════════════════════════════════════════════
//  PESHTOQ — madrasa ravog'i
// ═══════════════════════════════════════════════════════════════════

/// Ravoq shakli — o'lchamga o'zi moslashadi.
///
/// 🔑 BU ENG KUCHLI MILLIY BELGI VA U BEZAK EMAS, SHAKL: surat shu
/// ravoq bo'ylab KESILADI. Registon, Bibixonim, Ko'kaldosh — hammasi
/// shu siluetda. Odam uni tushuntirishsiz taniydi.
///
/// 🔴 BIRINCHI URINISH RAD ETILDI: ravoq tepasi YUMALOQ edi va u
/// «qabr toshi»ga o'xshab qolgandi — hech qanday madrasa esga
/// tushmasdi. Peshtoqning butun ma'nosi UCHLI ravoqda.
///
/// Qurilishi — haqiqiy IKKI MARKAZLI ravoq (an'anaviy usul):
/// yon devorlar `0.62·h` gacha tik ko'tariladi, so'ng ikkita yoy
/// markazlari o'qdan `0.134·w` ga SURILGAN holda chizilib, tepada
/// uchrashadi. Markazlar mos kelsa yarim doira chiqadi — aynan
/// shuning uchun ular suriladi.
Path peshtoqPath(Size size) => pointedArch(size, spring: 0.62);

/// UCHLI RAVOQ — peshtoq ham, muqarnas uyasi ham shundan chiqadi.
///
/// [spring] — yon devor qayerda tugab, yoy boshlanishi (balandlikning
/// ulushi). 0.62 — peshtoq (yonlari bor), 1.0 — muqarnas uyasi (yoy
/// to'g'ridan-to'g'ri zamindan ko'tariladi).
///
/// ⚠️ Yoy markazlari o'qdan `d = spring² − 0.25` ga SURILADI. Surilmasa
/// yarim doira chiqadi — va aynan shu «qabr toshi» ko'rinishi birinchi
/// urinishni buzgandi.
Path pointedArch(Size size, {required double spring}) {
  final w = size.width;
  final h = size.height;
  final d = spring * spring - 0.25;
  final r = 0.5 + d;
  final sweep = math.atan2(spring, d);

  Rect arc(double cx) => Rect.fromCenter(
    center: Offset(cx * w, spring * h),
    width: 2 * r * w,
    height: 2 * r * h,
  );

  return Path()
    ..moveTo(0, h)
    ..lineTo(0, spring * h)
    ..arcTo(arc(0.5 + d), math.pi, sweep, false)
    ..arcTo(arc(0.5 - d), -sweep, sweep, false)
    ..lineTo(w, h)
    ..close();
}

/// Ravoq niqobi — bolani (odatda surat) peshtoq shaklida kesadi.
class PeshtoqClipper extends CustomClipper<Path> {
  const PeshtoqClipper();

  @override
  Path getClip(Size size) => peshtoqPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Peshtoq — `ShapeBorder` ko'rinishi.
///
/// `Material`, `Card` va `Container` ga to'g'ridan-to'g'ri berilishi
/// mumkin: shunda ravoqning o'zi ham, uning chegarasi ham, soyasi ham
/// bitta manbadan chiqadi.
class PeshtoqBorder extends OutlinedBorder {
  const PeshtoqBorder({super.side = BorderSide.none});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => peshtoqPath(
    rect.deflate(side.width).size,
  ).shift(rect.topLeft + Offset(side.width, side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      peshtoqPath(rect.size).shift(rect.topLeft);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(rect).shift(Offset(side.width / 2, side.width / 2)),
      side.toPaint(),
    );
  }

  @override
  PeshtoqBorder copyWith({BorderSide? side}) =>
      PeshtoqBorder(side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => PeshtoqBorder(side: side.scale(t));
}

/// Peshtoq ramkasi — surat, avatar yoki rangli zaminni ravoqqa soladi.
class PeshtoqFrame extends StatelessWidget {
  const PeshtoqFrame({super.key, required this.child, this.border});

  final Widget child;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final shape = PeshtoqBorder(side: border ?? BorderSide.none);
    return ClipPath(
      clipper: const PeshtoqClipper(),
      child: CustomPaint(
        foregroundPainter: _BorderPainter(shape),
        child: child,
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  const _BorderPainter(this.shape);

  final PeshtoqBorder shape;

  @override
  void paint(Canvas canvas, Size size) =>
      shape.paint(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_BorderPainter old) => old.shape.side != shape.side;
}

// ═══════════════════════════════════════════════════════════════════
//  ISLIMI — o'simlik novdasi
// ═══════════════════════════════════════════════════════════════════

/// Islimi — uzluksiz S-egri novda, undan burama barglar chiqadi.
///
/// Ganch o'ymakorligidagi eng keng tarqalgan naqsh. Girih GEOMETRIYA
/// bo'lsa, islimi — TIRIKLIK; an'anada ikkalasi doim yonma-yon
/// ishlatiladi va bir-birini to'ldiradi.
///
/// Bu yerda u BO'LIM AJRATGICHI: chiziq emas, novda.
class IslimiBand extends StatelessWidget {
  const IslimiBand({
    super.key,
    this.height = 26,
    this.color,
    this.opacity = 0.5,
    this.repeatWidth = 150,
  });

  final double height;
  final Color? color;
  final double opacity;

  /// Bitta takror eni. Naqsh CHO'ZILMAYDI — takrorlanadi.
  final double repeatWidth;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _IslimiPainter(
          color: color ?? Theme.of(context).colorScheme.secondary,
          opacity: opacity,
          repeatWidth: repeatWidth,
        ),
      ),
    ),
  );
}

class _IslimiPainter extends CustomPainter {
  const _IslimiPainter({
    required this.color,
    required this.opacity,
    required this.repeatWidth,
  });

  final Color color;
  final double opacity;
  final double repeatWidth;

  /// Naqshning ichki koordinatasi — saytdagi `viewBox="0 0 160 40"`.
  static const double _w = 160;
  static const double _h = 40;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = repeatWidth / _w;
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color.withValues(alpha: color.a * opacity);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Naqsh vertikal markazda tursin: balandlik takrorga bog'liq emas.
    canvas.translate(0, (size.height - _h * scale) / 2);
    canvas.scale(scale);

    for (var x = 0.0; x < size.width / scale + _w; x += _w) {
      canvas.save();
      canvas.translate(x, 0);

      // Asosiy novda — uzluksiz to'lqin.
      canvas.drawPath(
        Path()
          ..moveTo(0, 20)
          ..cubicTo(20, 4, 40, 4, 60, 20)
          ..cubicTo(80, 36, 100, 36, 120, 20)
          ..cubicTo(140, 4, 150, 6, 160, 20),
        paint,
      );
      // Burama barglar — novdaning cho'qqilaridan chiqadi.
      canvas.drawPath(
        Path()
          ..moveTo(30, 9)
          ..cubicTo(24, 2, 34, 0, 36, 6)
          ..cubicTo(37, 10, 32, 12, 30, 9)
          ..close(),
        fill,
      );
      canvas.drawPath(
        Path()
          ..moveTo(90, 31)
          ..cubicTo(84, 38, 94, 40, 96, 34)
          ..cubicTo(97, 30, 92, 28, 90, 31)
          ..close(),
        fill,
      );
      // G'unchalar
      canvas.drawCircle(const Offset(60, 20), 2.6, fill);
      canvas.drawCircle(const Offset(120, 20), 2, fill);
      // Yon novdachalar
      canvas.drawPath(
        Path()
          ..moveTo(60, 20)
          ..cubicTo(66, 12, 74, 12, 78, 18),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(120, 20)
          ..cubicTo(126, 28, 134, 28, 138, 22),
        paint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IslimiPainter old) =>
      old.color != color ||
      old.opacity != opacity ||
      old.repeatWidth != repeatWidth;
}

// ═══════════════════════════════════════════════════════════════════
//  QO'CHQOR SHOXI — juft burama
// ═══════════════════════════════════════════════════════════════════

/// Qo'chqor shoxi — kuch va farovonlik belgisi.
///
/// Chorvador xalq naqshi: gilamda ham, so'zanada ham, ganchda ham bor.
/// Bu yerda u RAQAM MEDALYONI bo'lib ishlaydi — qadam raqamlari shu
/// shoxlar orasida turadi.
///
/// ⚠️ O'rovchiga QAT'IY kenglik berilsin: shox mutlaq joylashgani
/// uchun o'rovchi raqam eniga qisqarib, sarlavha raqamga yopishib
/// qolardi (saytda o'lchab topilgan).
class QochqorShox extends StatelessWidget {
  const QochqorShox({super.key, this.width = 44, this.color, this.opacity = 1});

  final double width;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size(width, width * 0.6),
      painter: _QochqorPainter(
        (color ?? Theme.of(context).colorScheme.primary).withValues(
          alpha: opacity,
        ),
      ),
    ),
  );
}

class _QochqorPainter extends CustomPainter {
  const _QochqorPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * k
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.scale(k);
    // Chap shox — ichkariga o'ralgan.
    canvas.drawPath(
      Path()
        ..moveTo(50, 52)
        ..cubicTo(30, 52, 12, 44, 10, 28)
        ..cubicTo(9, 16, 20, 10, 27, 16)
        ..cubicTo(33, 21, 28, 30, 20, 28),
      paint,
    );
    // O'ng shox — ko'zgu aksi.
    canvas.drawPath(
      Path()
        ..moveTo(50, 52)
        ..cubicTo(70, 52, 88, 44, 90, 28)
        ..cubicTo(91, 16, 80, 10, 73, 16)
        ..cubicTo(67, 21, 72, 30, 80, 28),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QochqorPainter old) => old.color != color;
}

/// Qadam medalyoni — raqam qo'chqor shoxlari orasida.
class QochqorStep extends StatelessWidget {
  const QochqorStep({super.key, required this.number, this.color});

  final int number;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    // ⚠️ QAT'IY kenglik — izohi `QochqorShox` da.
    return SizedBox(
      width: 48,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: QochqorShox(width: 48, color: tone, opacity: 0.55),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PALAK ROZETKASI — so'zananing markaziy doirasi
// ═══════════════════════════════════════════════════════════════════

/// Palak rozetkasi — so'zanadagi eng yirik motiv.
///
/// Quyoshni bildiruvchi doira, atrofida ikki qator barg. Ekranda u
/// KATTA VA XIRA — «suv belgisi» bo'lib turadi, ya'ni mazmun ostidan
/// sezilib turadigan mato.
///
/// ⚠️ Kichraytirib ishlatma. Naqshni KICHRAYTIRISH — saytda o'lchab
/// topilgan xato: har o'lchamga o'z naqshi bor (yirik maydonga palak,
/// mayda joyga paxta).
class PalakRosette extends StatelessWidget {
  const PalakRosette({
    super.key,
    this.size = 220,
    this.color,
    this.opacity = 0.08,
  });

  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.square(size),
      painter: _PalakPainter(
        (color ?? Theme.of(context).colorScheme.onSurface).withValues(
          alpha: opacity,
        ),
      ),
    ),
  );
}

class _PalakPainter extends CustomPainter {
  const _PalakPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 200;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * k;

    void petal(int i, int n, double r, double rx, double ry) {
      final a = 2 * math.pi * i / n - math.pi / 2;
      final cx = 100 + r * math.cos(a);
      final cy = 100 + r * math.sin(a);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(2 * math.pi * i / n);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        paint,
      );
      canvas.restore();
    }

    canvas.save();
    canvas.scale(k);
    // Tashqi va ichki barg qatorlari.
    for (var i = 0; i < 16; i++) {
      petal(i, 16, 78, 9, 20);
    }
    for (var i = 0; i < 10; i++) {
      petal(i, 10, 48, 8, 16);
    }
    // Markaz — quyosh.
    canvas.drawCircle(const Offset(100, 100), 22, paint);
    canvas.drawCircle(const Offset(100, 100), 12, paint);
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 4 * i;
      canvas.drawLine(
        Offset(100 + 12 * math.cos(a), 100 + 12 * math.sin(a)),
        Offset(100 + 22 * math.cos(a), 100 + 22 * math.sin(a)),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PalakPainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  MUQARNAS — asal uyasi ravoqchalar
// ═══════════════════════════════════════════════════════════════════

/// Muqarnas — peshtoq ostidagi «stalaktit» qatorlari.
///
/// Registon, Bibixonim va Sherdorning eng tanish tafsiloti. Bo'limlar
/// orasidagi O'TISH sifatida ishlatiladi: bir zamindan ikkinchisiga
/// o'tishda tekis chiziq emas, ravoqchalar qatori bo'ladi.
class MuqarnasBand extends StatelessWidget {
  const MuqarnasBand({
    super.key,
    required this.color,
    this.cell = 40,
    this.flip = false,
  });

  /// Ravoqchalar rangi — QAYERGA o'tayotgan bo'lsa, o'sha zamin rangi.
  final Color color;

  /// Bitta ravoqcha eni.
  final double cell;

  /// Pastga qaragan holat (bo'lim TEPASIDA).
  final bool flip;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: cell * 0.9,
      width: double.infinity,
      child: Transform.scale(
        scaleY: flip ? -1 : 1,
        child: CustomPaint(painter: _MuqarnasPainter(color, cell)),
      ),
    ),
  );
}

class _MuqarnasPainter extends CustomPainter {
  const _MuqarnasPainter(this.color, this.cell);

  final Color color;
  final double cell;

  /// Muqarnasning bitta uyasi — peshtoq ravog'ining kichraytirilgani.
  ///
  /// 🔴 Birinchi urinishda bu yarim DOIRA edi va butun tasma «bulutli
  /// chekka» bo'lib ko'rinardi. Muqarnas uyasi DOIM uchli — shuning
  /// uchun u peshtoq bilan bitta quruvchidan chiqadi ([pointedArch]):
  /// ikkalasi ajralib ketmasin.
  static Path _cellArch(double x, double w, double top, double bottom) =>
      pointedArch(Size(w, bottom - top), spring: 1).shift(Offset(x, top));

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final w = cell;
    final h = size.height;

    // ORQA QATOR — kichikroq va xira: u chuqurroqda turadi.
    //
    // ⚠️ IKKI QATOR HAM TO'LIQ CHIZILADI, keyin oldingisi ustidan
    // o'tadi. Birinchi urinishda ular bitta siklda chizilgandi va
    // keyingi katakning oldingi ravoqchasi orqa qatorni O'CHIRIB
    // ketardi — natijada faqat bitta qator ko'rinardi.
    final back = Paint()..color = color.withValues(alpha: color.a * 0.5);
    for (var x = -w; x < size.width + w; x += w) {
      canvas.drawPath(_cellArch(x, w, 0, h), back);
    }

    // OLDINGI QATOR — yarim katakka surilgan, to'la rangda va pastroq
    // boshlanadi: shunda orqa qator tepadan ko'rinib turadi.
    final front = Paint()..color = color;
    for (var x = -w - w / 2; x < size.width + w; x += w) {
      canvas.drawPath(_cellArch(x, w, h * 0.38, h), front);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MuqarnasPainter old) =>
      old.color != color || old.cell != cell;
}

// ═══════════════════════════════════════════════════════════════════
//  BO'LIM BELGISI
// ═══════════════════════════════════════════════════════════════════

/// Bo'lim belgisi — paxta guli va ikki yon chizig'i.
///
/// 🔴 Ilgari bu yerda rozetkali `SuzaniDivider` turardi va u faqat
/// bo'sh holatlarda ishlatilardi. Naqsh esa aynan shu vazifa uchun:
/// u tinish belgisi — bo'limlar orasida nafas.
class OrnamentMark extends StatelessWidget {
  const OrnamentMark({super.key, this.color, this.flower = 26});

  final Color? color;
  final double flower;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    Widget line(bool toRight) => Expanded(
      child: Container(
        height: 1,
        constraints: const BoxConstraints(maxWidth: 84),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
            end: toRight ? Alignment.centerRight : Alignment.centerLeft,
            colors: [tone.withValues(alpha: 0), tone.withValues(alpha: 0.45)],
          ),
        ),
      ),
    );

    return IgnorePointer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line(true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Pakhta(size: flower, color: tone),
          ),
          line(false),
        ],
      ),
    );
  }
}
