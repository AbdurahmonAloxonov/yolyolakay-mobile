import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/haptics.dart';
import '../../core/motion.dart';
import '../../l10n/strings.dart';

/// O'RINDIQ SXEMASI — "3 joy" raqami o'rniga KO'RINADIGAN o'rindiqlar.
///
/// 🔴 NEGA KERAK: "3 joy" degan raqam ikki xil o'qiladi — mashinada uchta
/// joy bormi yoki uchtasi BO'SHMI? Sxemada savol qolmaydi: to'lgan
/// o'rindiq boshqacha ko'rinadi, bo'shi esa brend rangida.
///
/// Haydovchi o'rindig'i ATAYIN chizilgan: usiz qator "mashina" bo'lib
/// ko'rinmaydi, shunchaki nuqtalar bo'lib qoladi. U hech qachon
/// tanlanmaydi va sanoqqa kirmaydi.
///
/// ⚠️ Jonlanish DEKORATIV: o'rindiqlar navbat bilan "joyiga tushadi".
/// Tizimda "harakatni kamaytir" yoqilgan bo'lsa (`AppMotion`) — darhol,
/// animatsiyasiz chiziladi. Bu qoida butun ilovada bir xil.
///
/// ═══ TANLASH (2026-08-25 da qo'shildi) ═══
///
/// 🔴 NEGA: joy soni ekranning ENG PASTIDA, «−  2  +» tugmalari bilan
/// tanlanardi. Ya'ni odam o'rindiqlarni yuqorida KO'RIB turib, ularni
/// pastdagi mavhum raqam orqali tanlardi — ko'z bir joyda, barmoq
/// boshqa joyda. Endi o'rindiqning O'ZIGA bosiladi.
///
/// [onSelect] berilmasa vidjet avvalgidek FAQAT ko'rsatadi (haydovchi
/// ekranida yoki bron qilingandan keyin tanlashning ma'nosi yo'q).
///
/// ⚠️ Pastdagi «− N +» qatori OLIB TASHLANMADI: u raqamni aniq ko'rsatadi
/// va ekran o'quvchisi bilan ishlaydigan odam uchun asosiy yo'l bo'lib
/// qoladi. Sxema — qulayroq muqobil, yagona yo'l emas.
class SeatMap extends StatelessWidget {
  const SeatMap({
    super.key,
    required this.totalSeats,
    required this.availableSeats,
    this.selected = 0,
    this.maxSelectable = 0,
    this.onSelect,
    this.maxTwoBack = false,
    this.compact = false,
  });

  final int totalSeats;
  final int availableSeats;

  /// Nechta bo'sh o'rindiq TANLANGAN.
  final int selected;

  /// Eng ko'pi nechta tanlash mumkin (tarif/qoida chegarasi).
  final int maxSelectable;

  /// Tanlov o'zgarganda. `null` — vidjet faqat ko'rsatadi.
  final void Function(int seats)? onSelect;

  /// Haydovchi «orqada 2 kishi» qoidasini qo'ygan (`max_two_back`).
  final bool maxTwoBack;

  /// Ixcham ko'rinish — qidiruv kartasi va haydovchi ekrani uchun.
  ///
  /// Sarlavha, qator yorliqlari va matnli hisob CHIQARIB TASHLANADI:
  /// kartada joy tor va u yerda sxema «bu safarda joy bormi» degan
  /// savolga BIR QARASHDA javob berishi kerak, o'qishga emas.
  final bool compact;

  /// IXCHAM sxema qancha en egallaydi.
  ///
  /// 🔴 NEGA KERAK (2026-09-02): safar kartasi sarlavha qatorida sxemaga
  /// joy yetadimi-yo'qmi degan qarorni qabul qiladi. Bu son shu yerda
  /// hisoblanadi — kartada takrorlansa, sxema o'zgarganda ikkinchi joy
  /// unutilib, qaror yolg'on bo'lib qolardi.
  ///
  /// Ikonkalar matn kattaligi bilan O'SMAYDI, shuning uchun bu qat'iy son.
  static double compactWidth(int totalSeats) {
    final total = totalSeats.clamp(1, 8);
    const seat = 15.0; // `seatSize`, compact
    // haydovchi + ajratgich + o'rindiqlar + ular orasidagi oraliqlar
    return seat + AppSpace.md + total * seat + (total - 1) * AppSpace.xs;
  }

  /// Salon taqsimoti: [oldingi yo'lovchi o'rindig'i soni, orqa qator].
  ///
  /// 🔴 NEGA QO'LDA HISOBLANADI: backend faqat SONNI beradi
  /// (`total_seats`), salon chizmasini emas. O'zbekistonda sotiladigan
  /// mashinalarning deyarli hammasi — oldida BITTA yo'lovchi o'rindig'i,
  /// qolgani orqada (Cobalt, Nexia, Malibu). Shuning uchun qoida oddiy:
  /// birinchi o'rindiq — oldinda, qolgani — orqada.
  ///
  /// ⚠️ 4 dan ko'p o'rindiq (Damas, minivan) bo'lsa orqa qator ikkiga
  /// bo'linadi — aks holda sakkizta belgi bitta qatorga tiqilib, hech
  /// nima o'qilmay qolardi.
  static List<int> _rows(int total) {
    if (total <= 1) return [total];
    if (total <= 4) return [1, total - 1];
    final rest = total - 1;
    return [1, (rest / 2).ceil(), rest ~/ 2];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // Ma'lumot yaroqsiz bo'lsa hech nima chizmaymiz: bo'sh ramka
    // "ilova buzuq" degandek ko'rinadi.
    if (totalSeats <= 0) return const SizedBox.shrink();

    final total = totalSeats.clamp(1, 8);
    final free = availableSeats.clamp(0, total);
    final animate = AppMotion.on(context);
    /*
     * IXCHAM ko'rinishda salon IKKI QATORGA BO'LINMAYDI.
     *
     * 🔴 SABAB O'LCHOVDAN: qidiruv kartasi balandligi 170 px dan oshmasligi
     * kerak («ekranga kamida uchta safar sig'sin» — `search_ui_test`), va
     * u yerda bo'sh vertikal joy YO'Q. Ikki qatorli sxema kartani 203 px
     * ga chiqarib yubordi, test darhol ushladi.
     *
     * Kartada kerak bo'lgan javob — «joy bormi», salon chizmasi emas.
     * Chizma to'liq ko'rinishda (safar detali, haydovchi ekrani) qoladi.
     */
    final rows = compact ? [total] : _rows(total);

    /*
     * BAND O'RINDIQLAR ORQADAN TO'LADI.
     *
     * 🔴 HALOL CHEKLOV: backend kim qayerda o'tirishini SAQLAMAYDI —
     * bronda faqat `seats_booked` (SON) bor, pozitsiya yo'q. Ya'ni
     * "Ali — 2-o'rindiq" deb yozsak, buni O'ZIMIZ o'ylab topgan
     * bo'lardik va odam mashinaga kelib boshqa manzara ko'rardi.
     *
     * Shuning uchun sxema faqat NECHTASI bandligini ko'rsatadi. Old
     * o'rindiq oxirida to'ladi: amalda haydovchi yonidagi joy odatda
     * oxirgi bo'lib beriladi va bo'sh joy qidirayotgan odam avvalo
     * orqaga qaraydi. Bu — ko'rsatish tartibi, VA'DA EMAS.
     */
    final taken = total - free;
    var takenLeft = taken;
    final backCount = compact ? 0 : total - rows.first;
    final backTaken = takenLeft.clamp(0, backCount);
    takenLeft -= backTaken;
    final frontTaken = takenLeft.clamp(0, rows.first);

    // Tanlangan o'rindiqlar bo'shlaridan OLDINDAN boshlab belgilanadi —
    // odam «2 ta oldim» deganda ikkitasi darhol yonadi.
    var selectedLeft = selected.clamp(0, free);

    final seatSize = compact ? 15.0 : 22.0;
    /*
     * KATAK — ixchamda belgining o'zi, to'liq sxemada 44 px.
     *
     * 🔴 36 — barmoq nishoni (ilgari 30 edi: 22 px belgi + 4 px chekka).
     * 44 sinab ko'rildi va RAD ETILDI: kataklar shunchalik kengayadiki,
     * ikki qator o'rindiq bir-biridan uzoqlashib «mashina» bo'lib
     * ko'rinmay qoladi — sxemaning butun ma'nosi shunda edi.
     * O'rindiqni tanlashning ikkinchi yo'li («− N +» qatori) ATAYIN
     * saqlangan, ya'ni bu yagona yo'l emas.
     *
     * Ixcham ko'rinishda o'rindiq BOSILMAYDI (faqat ko'rsatadi) —
     * u yerda katak kattalashtirilmaydi, aks holda karta balandligi
     * budjetdan chiqib ketardi (`search_ui_test`).
     */
    final cell = compact ? seatSize : 36.0;
    var drawn = 0;
    Widget seatFor(int rowIndex, int posInRow) {
      final isBack = rowIndex > 0;
      final rowTaken = isBack ? backTaken : frontTaken;
      // Orqa qator bo'linganda (5+ o'rindiq) bandlar birinchi orqa
      // qatordan boshlab sanaladi — bitta uzluksiz oqim.
      final takenInThisRow = isBack
          ? (rowTaken - _takenBefore(rows, rowIndex, backTaken)).clamp(
              0,
              rows[rowIndex],
            )
          : rowTaken;
      final isFree = posInRow >= takenInThisRow;
      final isSelected = isFree && selectedLeft > 0;
      if (isSelected) selectedLeft--;

      final rowName = isBack ? t.seatRowBack : t.seatRowFront;
      final selectable = onSelect != null && isFree && maxSelectable > 0;
      final myIndex = drawn++;

      return _Seat(
        icon: Icons.event_seat,
        cell: cell,
        /*
         * RANGLAR — 2026-09-02 ko'rigida QAYTA O'LCHANDI.
         *
         * 🔴 Ilgari bo'sh o'rindiq brend rangining 32% i, band o'rindiq
         * esa `surfaceContainerHighest` edi. Oq zaminda ikkalasi ham
         * deyarli OQ bo'lib chiqardi: rasmda band va bo'sh o'rindiqni
         * ajratib bo'lmasdi. Sxemaning YAGONA vazifasi «joy bormi»
         * degan savolga bir qarashda javob berish edi — u bajarilmasdi.
         *
         * Endi farq FAQAT ochlikda emas, RANGDA ham: bo'sh — pushti,
         * band — kulrang. Ikkisi bir-biriga aylanib ketmaydi.
         */
        color: isSelected
            // Tanlangan — to'liq brend rangi.
            ? theme.colorScheme.primary
            : isFree
            // Bo'sh — brend rangi, lekin tanlangandan ochroq.
            ? theme.colorScheme.primary.withValues(alpha: 0.70)
            // Band — KULRANG: pushti oilasidan butunlay chiqadi.
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        index: myIndex + 1,
        animate: animate,
        selected: isSelected,
        label: isFree ? t.seatFreeIn(rowName) : t.seatTakenIn(rowName),
        size: seatSize,
        onTap: !selectable
            ? null
            : () {
                // Bosilgan o'rindiqqacha tanlanadi. Allaqachon oxirgi
                // tanlangan bo'lsa — bittaga kamayadi (ikkinchi bosish
                // "bekor qilish" degani).
                final want = _freeRank(
                  rows,
                  backTaken,
                  frontTaken,
                  rowIndex,
                  posInRow,
                );
                final next = selected == want ? want - 1 : want;
                onSelect!(next.clamp(0, maxSelectable));
              },
      );
    }

    final car = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // OLD QATOR — haydovchi + yonidagi o'rindiq.
        Row(
          children: [
            _Seat(
              icon: Icons.airline_seat_recline_extra,
              cell: cell,
              // Haydovchi o'rindig'i — neytral, "band" ham emas, "bo'sh"
              // ham. Usiz qator "mashina" bo'lib ko'rinmaydi.
              color: theme.colorScheme.outlineVariant,
              index: 0,
              animate: animate,
              label: t.seatDriver,
              size: seatSize,
            ),
            const SizedBox(width: AppSpace.md),
            for (var i = 0; i < rows.first; i++) ...[
              seatFor(0, i),
              if (i != rows.first - 1 && compact)
                const SizedBox(width: AppSpace.xs),
            ],
          ],
        ),
        // ORQA QATOR(LAR) — old qatordan bo'sh joy bilan ajratiladi,
        // shunda ikkisi bitta mashina bo'lib o'qiladi.
        for (var r = 1; r < rows.length; r++) ...[
          // To'liq sxemada kataklarning o'zida chekka bor — qo'shimcha
          // oraliq qatorlarni bir-biridan uzoqlashtirib yuborardi.
          if (compact) const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              for (var i = 0; i < rows[r]; i++) ...[
                seatFor(r, i),
                if (i != rows[r] - 1 && compact)
                  const SizedBox(width: AppSpace.xs),
              ],
            ],
          ),
        ],
      ],
    );

    if (compact) return car;

    /*
     * SALON KONTURI — o'rindiqlar «mashina» bo'lib o'qilishi uchun.
     *
     * 🔴 NEGA QO'SHILDI (2026-09-03 ko'rigi): konturisiz sxema
     * SOCHILGAN IKONKALAR bo'lib ko'rinardi — old qatorda ikkita,
     * orqasida uchta belgi va ular orasida hech qanday bog'liqlik
     * yo'q edi. Vidjetning o'z izohi ham shuni aytadi: «usiz qator
     * mashina bo'lib ko'rinmaydi».
     *
     * Kontur tepadan kengroq yumaloq (old oyna), pastdan tor —
     * ya'ni bu tepadan qaralgan salon. Rang neytral: sxemada
     * MA'NONI o'rindiqlar aytadi, kontur emas.
     */
    final salon = Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.salonTop),
          bottom: Radius.circular(AppRadius.salonBottom),
        ),
      ),
      child: car,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.seatsTitle,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        // 🔴 YOZUV TEPAGA TEKISLANADI (2026-09-02 ko'rigi).
        //
        // `center` da u ikki qator o'rindiq ORASIDAGI bo'shliqqa tushib
        // qolardi — hech narsaga tegishli bo'lmagan, havoda osilgan matn
        // bo'lib ko'rinardi. Tepada esa u birinchi qator bilan bir
        // chiziqda turadi va sxemaning YORLIG'I bo'lib o'qiladi.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            salon,
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.seatsFreeOfTotal(free, total),
                    // ⚠️ Ikki qator: 320 px va 1.3 shkalada «2 из 4
                    // свободно» 118/127 px bo'lib kesilardi — bo'sh
                    // joylar SONI yo'qolardi (o'lchandi 2026-09-04).
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  // «Orqada 2 kishi» qoidasi AYNAN shu yerda aytiladi:
                  // odam orqa qatorga qarab turib o'qiydi. Ilgari u
                  // belgilar orasida yo'qolib ketardi.
                  if (maxTwoBack) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      t.maxTwoBack,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shu qatorgacha nechta band o'rindiq sanalgan (orqa qator bo'linganda).
  static int _takenBefore(List<int> rows, int rowIndex, int backTaken) {
    var before = 0;
    for (var r = 1; r < rowIndex; r++) {
      before += rows[r];
    }
    return before.clamp(0, backTaken);
  }

  /// Bosilgan BO'SH o'rindiq bo'shlar orasida nechanchisi — tanlov shunga
  /// qarab o'rnatiladi.
  static int _freeRank(
    List<int> rows,
    int backTaken,
    int frontTaken,
    int rowIndex,
    int posInRow,
  ) {
    var rank = 0;
    for (var r = 1; r < rows.length; r++) {
      final rowTaken = (backTaken - _takenBefore(rows, r, backTaken)).clamp(
        0,
        rows[r],
      );
      for (var i = 0; i < rows[r]; i++) {
        if (i < rowTaken) continue;
        rank++;
        if (r == rowIndex && i == posInRow) return rank;
      }
    }
    for (var i = 0; i < rows.first; i++) {
      if (i < frontTaken) continue;
      rank++;
      if (rowIndex == 0 && i == posInRow) return rank;
    }
    return rank;
  }
}

/// Bitta o'rindiq — navbat bilan "joyiga tushadi".
class _Seat extends StatelessWidget {
  const _Seat({
    required this.icon,
    required this.color,
    required this.index,
    required this.animate,
    this.selected = false,
    this.label,
    this.onTap,
    this.size = 22,
    required this.cell,
  });

  final IconData icon;
  final Color color;

  /// Navbat raqami — kechikish shundan hisoblanadi.
  final int index;
  final bool animate;
  final bool selected;

  /// Ekran o'quvchisi uchun: «2-o'rindiq, bo'sh».
  final String? label;
  final VoidCallback? onTap;

  /// Belgi o'lchami — ixcham ko'rinishda kichikroq.
  final double size;

  /// Katak o'lchami — hamma o'rindiq uchun BIR XIL, shuning uchun qator
  /// tekis turadi va barmoq nishoni yetarli bo'ladi.
  final double cell;

  @override
  Widget build(BuildContext context) {
    /*
     * HAR O'RINDIQ BIR XIL KATAKDA — 2026-09-02 ko'rigi.
     *
     * 🔴 Ilgari faqat BOSILADIGAN o'rindiq `Padding` ichida edi. Ya'ni
     * bitta qatorda bo'sh (bosiladigan) va band (bosilmaydigan)
     * o'rindiqlar TURLI o'lchamda chizilardi va qator qiyshayib
     * ketardi — bo'sh joy boshqalaridan pastroq va yiriкроq
     * ko'rinardi. Bu «sxema» emas, tasodifiy belgilar to'plami
     * bo'lib qolardi.
     *
     * 🔴 Ikkinchi xato — BARMOQ NISHONI: 22 px belgi + 4 px chekka =
     * 30 px. Tavsiya etilgan eng kichik nishon — 44 px. Kichik
     * o'rindiqni birinchi urinishda bosib bo'lmasdi.
     *
     * Endi katak `cell` bilan beriladi: to'liq sxemada 44 px (barmoq
     * uchun), ixchamda esa belgi o'lchami (u yerda bosish yo'q).
     */
    Widget seat = SizedBox.square(
      dimension: cell,
      child: Center(
        child: Icon(icon, size: size, color: color),
      ),
    );

    if (onTap != null) {
      seat = Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () {
            // Bosish HIS qilinsin: o'rindiq kichkina, ko'z bilan
            // tasdiqlash qiyin.
            AppHaptics.select();
            onTap!();
          },
          radius: cell / 2,
          child: seat,
        ),
      );
    } else if (label != null) {
      seat = Semantics(label: label, excludeSemantics: true, child: seat);
    }

    if (!animate) return seat;

    return TweenAnimationBuilder<double>(
      // Kechikish o'rindiq raqamiga bog'liq — "to'lib borish" hissi.
      // 60 ms ATAYIN kichik: sakkizta o'rindiq ham yarim soniyada tugaydi,
      // aks holda ekran "kutayotgandek" ko'rinardi.
      duration: Duration(milliseconds: 220 + index * 60),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Transform.scale(
        // `easeOutBack` 1 dan oshib ketadi — masshtab manfiy bo'lmasligi
        // uchun pastdan qirqamiz.
        scale: value.clamp(0.0, 1.2),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: seat,
    );
  }
}
