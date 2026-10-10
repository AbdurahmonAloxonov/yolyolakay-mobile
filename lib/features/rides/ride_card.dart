import 'package:flutter/material.dart';
import 'seat_map.dart';

import '../../core/format.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import 'journey_view.dart';
import 'ride_hero.dart';
import '../../app/dimens.dart';

/// Ro'yxatda ko'rsatiladigan belgilarning eng ko'p soni — qolgani "+N".
/// Kartochkada ko'rsatiladigan belgilar soni.
///
/// 🔴 4 ta edi va 360px ekranda haydovchi ismini "Muxammad …" gacha siqib
/// qo'yardi (qurilmada ko'rildi 2026-08-14). Ism — yo'lovchi uchun belgidan
/// muhimroq: qolganini safarni ochib ko'radi.
const _maxBadges = 3;

/// Qidiruv natijasi / safarlarim ro'yxati uchun karta.
///
/// QOIDA: ro'yxatdagi karta "bu safar menikimi?" degan savolga javob beradi,
/// hammasini emas. Batafsil ma'lumot — safar ochilganda. Shuning uchun bu
/// yerda matnli belgilar, oraliq shaharlar ro'yxati va boshqa "to'ldirgich"
/// yo'q: ekranga imkon qadar ko'p safar sig'ishi kerak.
class RideCard extends StatelessWidget {
  const RideCard({
    super.key,
    required this.ride,
    this.onTap,
    this.distanceKm,
    this.mine = false,
    this.medianPrice,
    this.routeDuration,
  });

  final Ride ride;
  final VoidCallback? onTap;

  /// Yo'lovchi tanlagan jo'nash nuqtasidan safar boshlanishigacha (km).
  /// Faqat qidiruv natijalarida beriladi.
  final double? distanceKm;

  /// SHU QIDIRUV natijalarining o'rtacha (median) narxi — "arzon/qimmat"
  /// ishorasi uchun.
  ///
  /// 🔴 NEGA MEDIAN VA O'RTACHA EMAS: bitta juda qimmat e'lon o'rtachani
  /// tortib ketadi va qolgan hammasi "arzon" bo'lib chiqadi. Median bunga
  /// bardosh beradi.
  ///
  /// ⚠️ Bu raqam TO'QIB CHIQARILMAYDI va bozor narxi ham DEYILMAYDI: u
  /// ayni ekrandagi natijalardan hisoblanadi. Natija kam bo'lsa (3 tadan
  /// oz) ishora umuman ko'rsatilmaydi — ikkita e'lon orasidagi "o'rtacha"
  /// ma'nosiz.
  final double? medianPrice;

  /// Yo'l davomiyligi — EKRANDAN uzatiladi, kartaning o'zi so'ramaydi.
  ///
  /// 🔴 NEGA SHUNDAY: karta `ConsumerWidget` bo'lsa, ro'yxatdagi har bir
  /// element alohida provider kuzatardi va `ProviderScope`siz umuman
  /// chizilmasdi (layout testlari shundan yiqildi). Karta "soqov" bo'lib
  /// qolgani ma'qul: ma'lumotni kim yig'ayotgani bitta joyda ko'rinadi.
  final Duration? routeDuration;

  /// Bu MENING e'lonim (haydovchi ro'yxati).
  ///
  /// 🔴 Qurilmada ko'rildi (2026-08-13): o'z e'lonim kartochkasida pastda
  /// "Haydovchi" degan qator turardi — ya'ni ilova menga o'zimni haydovchi
  /// deb tanishtirardi (ism kelmaganda umumiy so'z chiqadi). Bu qator
  /// yo'lovchi uchun kerak, o'z e'lonimda esa ortiqcha. O'rniga e'lon
  /// FAOLLIGI ko'rsatiladi — qidiruvda ko'rinadimi yoki yo'q.
  final bool mine;

  /// «O'rtachadan arzon/qimmat» yozuvi — sezilarli farq BO'LGANDAGINA.
  ///
  /// 10% chegara ATAYIN: undan kichik farq odam uchun ahamiyatsiz, lekin
  /// deyarli har kartada yozuv chiqarib, ro'yxatni shovqinга to'ldirardi.
  String? _priceHint(AppStrings t) {
    final median = medianPrice;
    if (median == null || median <= 0) return null;
    final price = ride.pricePerSeat;
    if (price <= 0) return null;
    if (price <= median * 0.9) return t.belowAverage;
    if (price >= median * 1.1) return t.aboveAverage;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final badges = rideBadges(ride, t);

    /// «Oxirgi joylar» nishoni chiqadimi — 1-2 joy qolganda odam
    /// kechiktirmasligi kerak. Bu YOLG'ON shoshilinchlik emas, ro'yxatdagi
    /// haqiqiy holat.
    final showSeatsLeftBadge =
        ride.availableSeats > 0 && ride.availableSeats <= 2;

    /// Sarlavha qatoridagi meta matn: qachon · qancha uzoq · qancha vaqt.
    ///
    /// 🔴 O'ZGARUVCHIGA CHIQARILDI (2026-09-02): uning KERAKLI ENI
    /// o'lchanadi va bezakka joy qolganmi-yo'qmi shunga qarab hal
    /// qilinadi. Qat'iy piksel chegarasi ishlamaydi — matn tilga,
    /// shriftga va matn kattaligiga bog'liq.
    final metaText = [
      // 🔴 Yaqin safarda MUTLAQ sana o'rniga "qancha qoldi".
      // Ro'yxatni ko'z bilan skanerlayotgan odamga "2 soatdan keyin"
      // aniq sanadan foydaliroq; aniq vaqt safar tafsilotida qoladi.
      // Uzoq sanada yorliq BO'SH qaytadi — o'sha eski yozuv.
      // Holat bilan: jo'nash vaqti o'tgan-u safar boshlanmagan bo'lsa
      // «Jo'nab ketdi» degan gap YOLG'ON bo'lardi (izohi
      // `departureStatusLabel` da).
      if (departureStatusLabel(
        ride.departureTime,
        ride.status,
        t.lang,
      ).isNotEmpty)
        departureStatusLabel(ride.departureTime, ride.status, t.lang)
      else
        formatDateTime(ride.departureTime, t.lang),
      // 🔴 "0.0 km" ko'rsatilmaydi: qidiruv nuqtasi bilan safar
      // boshlanishi bir joy bo'lsa (shahar markazi — eng keng tarqalgan
      // holat) bu raqam ma'nosiz, lekin qatorni to'ldirib, keyingi
      // ma'lumotni kesib yuborardi (qurilmada ko'rildi 2026-08-14).
      if (distanceKm != null && distanceKm! >= 0.5)
        '${distanceKm!.toStringAsFixed(distanceKm! < 10 ? 1 : 0)} ${t.kmAway}',
      // 🔴 YO'L UZUNLIGI — narxdan keyingi ikkinchi savol ("qancha vaqt
      // ketadi?"). Ma'lumot serverda ALLAQACHON bor edi
      // (`/routing/route`), lekin faqat safar ochilganda ko'rsatilardi.
      if (routeDuration != null) '≈${formatDuration(routeDuration!, t.lang)}',
    ].join(' · ');

    /*
     * 🔴 KECHIKISH KARTOCHKADA SEZILMASDI (2026-09-03 ko'rigi).
     *
     * «Kechikmoqda — 6 soat 37 daqiqa» qolgan ma'lumot bilan bir xil
     * kulrangda yozilardi: odam kartochkaga qarab safar kechikayotganini
     * BILMASDI. Safar tafsilotida esa u nishon bilan ajratilgan —
     * bitta ma'lumot ikki joyda ikki xil ko'rinardi.
     *
     * Bu qatorda nishonga JOY YO'Q (eni o'lchab taqsimlangan, izohi
     * pastda), shuning uchun signal RANG bilan beriladi. Pushti EMAS —
     * u narxniki va yonma-yon turganda ikkalasi raqobatlashardi;
     * xato rangi esa «e'tibor ber» deydi va boshqa hech nima bilan
     * chalkashmaydi.
     */
    final needsAttention = departureNeedsAttention(
      ride.departureTime,
      ride.status,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: needsAttention
          ? theme.colorScheme.error
          : theme.colorScheme.outline,
      fontWeight: needsAttention ? FontWeight.w700 : null,
    );
    final priceText = '${formatPrice(ride.pricePerSeat)} ${t.sum}';
    final priceStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*
               * SARLAVHA QATORI — USTUVORLIK TARTIBI (2026-09-02 ko'rigi).
               *
               * Qatorda to'rt narsa bor edi: jo'nash vaqti, o'rindiq
               * sxemasi, «N joy qoldi» nishoni va narx. Sxema ham,
               * nishon ham ~95 pikseldan QAT'IY joy egallaydi — matn
               * ularni qisqartira olmaydi. O'LCHANDI:
               *
               *   jo'nash vaqti  →  eni 0.0 px (320, 360 VA 412 px,
               *                     uz ham, ru ham) — ya'ni safar
               *                     QACHON ekani HECH QAYSI telefonda
               *                     ko'rinmasdi;
               *   narx           →  110 px kerak, 55–92 px berilardi
               *                     («150 000 s…» bo'lib kesilardi).
               *
               * 🔑 Hech qanday test tutmagan, chunki matn KESILGAN,
               * TOSHMAGAN: `TextOverflow.ellipsis` toshishni yutadi va
               * `RenderFlex overflowed` chiqmaydi. `find.text` esa eni
               * nol bo'lgan vidjetni ham topadi.
               *
               * Endi tartib qat'iy:
               *   1. NARX o'z enini oladi (flex poygasida qatnashmaydi,
               *      lekin yarim endan oshmaydi);
               *   2. VAQT qolganini oladi;
               *   3. Sxema/nishon — FAQAT qolgan joy yetsa.
               *
               * Sxema qatordan tushib qolsa ham ma'lumot yo'qolmaydi:
               * bo'sh joy soni safar tafsilotida to'liq sxema bilan,
               * 1-2 joy qolganda esa nishon bilan ko'rsatiladi.
               */
              LayoutBuilder(
                builder: (context, box) {
                  // Narx qatorning YARMIDAN oshmasin — qolgan yarmi
                  // vaqtga qoladi. Katta matn rejimida ham shu chegara
                  // qatorni toshishdan saqlaydi.
                  final maxPriceWidth = box.maxWidth * 0.5;

                  /*
                   * Bezakka joy YETADIMI.
                   *
                   * 🔴 O'lchamlar MATN KATTALIGIGA bog'liq: 1.3 rejimida
                   * ham vaqt, ham narx ~30% kengayadi va uchinchi element
                   * uchun joy qolmaydi. Shuning uchun chegara ham
                   * kattalik bilan birga o'sadi — aks holda katta matnli
                   * telefonda vaqt yana qisilib qolardi.
                   *
                   * 300 — o'lchovdan: 360 px ekranda kartaning ichki eni
                   * 324 px (sxema sig'adi), 320 px ekranda esa 284 px
                   * (sig'maydi).
                   */
                  // Matn qancha joy TALAB QILADI — o'lchab ko'ramiz.
                  // Qat'iy piksel chegarasi yaramaydi: ruscha o'zbekchadan
                  // uzun, katta matn rejimida hammasi ~30% kengayadi.
                  final scaler = MediaQuery.textScalerOf(context);
                  double needed(String text, TextStyle? style) => (TextPainter(
                    text: TextSpan(text: text, style: style),
                    maxLines: 1,
                    textDirection: Directionality.of(context),
                    textScaler: scaler,
                  )..layout()).width;

                  final metaNeeds = needed(metaText, metaStyle);
                  final priceNeeds = needed(
                    priceText,
                    priceStyle,
                  ).clamp(0.0, maxPriceWidth);

                  // Bezakning eni: nishon — matn + ichki chekka; sxema —
                  // ikonkalar (ular matn bilan kattalashmaydi).
                  final extraNeeds = showSeatsLeftBadge
                      ? needed(
                              t.seatsLeft(ride.availableSeats),
                              theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ) +
                            AppSpace.sm * 2
                      : SeatMap.compactWidth(ride.totalSeats);

                  final leftForExtra =
                      box.maxWidth - priceNeeds - metaNeeds - AppSpace.sm * 2;
                  final roomForExtra = leftForExtra >= extraNeeds;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vaqt, bo'sh joy va masofa — BITTA qatorda. Ilgari ular
                      // uchta alohida qator edi va karta shundan cho'zilardi.
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                metaText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: metaStyle,
                              ),
                            ),
                            /*
                             * BEZAK — FAQAT JOY YETSA.
                             *
                             * Sxema va nishon bitta savolga javob beradi:
                             * nechta joy bo'sh. 1-2 joy qolganda nishon
                             * (matn — aniqroq va ekran o'quvchisi bilan
                             * ishlaydi), aks holda sxema.
                             *
                             * ⚠️ Ikkalasi ham ~95 pikselni QAT'IY oladi.
                             * Joy yetmasa TUSHIRILADI — vaqt va narx
                             * ulardan muhimroq (izohi yuqorida).
                             */
                            if (roomForExtra) ...[
                              const SizedBox(width: AppSpace.sm),
                              if (showSeatsLeftBadge)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    t.seatsLeft(ride.availableSeats),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                )
                              else
                                SeatMap(
                                  totalSeats: ride.totalSeats,
                                  availableSeats: ride.availableSeats,
                                  maxTwoBack: ride.maxTwoBack,
                                  compact: true,
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      // Narx — kartadagi eng "og'ir" element: odam ro'yxatni
                      // aynan shu bo'yicha ko'z bilan skanerlaydi.
                      //
                      // 🔴 NEGA `flex` EMAS (2026-09-02): `Flexible(flex: 2)`
                      // narxga qatorning atigi 2/5 qismini berardi — matn
                      // qanchalik keng bo'lishidan QAT'I NAZAR. O'lchov:
                      // «150 000 so'm» 110 px talab qiladi, lekin 320 px
                      // ekranda 55 px olardi va «150 000 s…» bo'lib kesilardi.
                      //
                      // Endi narx flex poygasida QATNASHMAYDI: `Row` avval
                      // flex'siz bolalarga o'z enini beradi, qolgani chapdagi
                      // `Expanded` ga o'tadi. Ya'ni narx to'liq chiqadi,
                      // qisqarish esa ikkinchi darajali matnga tushadi.
                      //
                      // 🔴 `ConstrainedBox` SHART: katta matn rejimida narx
                      // qatorni toshirib yuborardi ("overflowed by 76 pixels",
                      // 2026-08-14). Yarim endan oshsa — o'sha yerda kesiladi.
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxPriceWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Narx — ro'yxatning eng "og'ir" elementi, shuning
                            // uchun safar ochilganda u ham joyida qoladi:
                            // odam ko'zini boshqa joyga ko'chirmaydi.
                            RideHero(
                              rideId: ride.id,
                              part: RideHeroPart.price,
                              child: Text(
                                priceText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: priceStyle,
                              ),
                            ),
                            // 🔴 "Adolatli narx" NARX YONIGA ko'chdi (egasi
                            // qurilmada: "adolatli narx yomon ko'rinyapti").
                            // Ilgari u qulaylik ikonkalari orasida yozuvsiz
                            // `Icons.verified` (galochka) bo'lib turardi —
                            // "tasdiqlangan hisob" degan ma'no berardi, narxni
                            // emas, va belgilar orasida yo'qolardi. Endi u
                            // narx OSTIDA, tarozi belgisi (adolat ramzi) va
                            // yozuv bilan — nima haqida ekani ko'rinib turadi.
                            if (ride.hasFairPriceBadge)
                              const Padding(
                                padding: EdgeInsets.only(top: AppSpace.xs),
                                child: _FairPriceChip(),
                              ),
                            // Narx konteksti — backendning "adolatli narx"
                            // nishonidan FARQLI: u serverniki, bu esa ayni
                            // ro'yxatga nisbatan. Ikkalasi bir vaqtda chiqishi
                            // mumkin va bir-birini takrorlamaydi.
                            if (_priceHint(t) != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpace.xs,
                                ),
                                child: Text(
                                  _priceHint(t)!,
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: ride.pricePerSeat < medianPrice!
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpace.sm),
              const SizedBox(height: AppSpace.sm),
              // Oraliq shaharlar ilgari marshrutdan AJRALGAN qator edi
              // ("Yo'l-yo'lakay: Jizzax · Guliston"). Endi ular chiziqning
              // o'zida, jo'nash bilan manzil orasida turadi — qayerdan qayerga
              // o'tishi ko'rinib turadi.
              // Marshrut chizig'i safar ochilganda JOYIDA qoladi va
              // kattalashadi (`RideHero`) — ilgari u yo'qolib, tafsilotda
              // qaytadan chizilardi.
              RideHero(
                rideId: ride.id,
                part: RideHeroPart.journey,
                child: JourneyLine(
                  origin: ride.originAddress,
                  destination: ride.destinationAddress,
                  stops: [for (final s in ride.stops) s.address],
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: AppSpace.sm),

              // Pastki qator: haydovchi | bo'sh joy · masofa | belgilar.
              //
              // 🔴 Ilgari bu yerda `Spacer()` turardi va haydovchi ismi hech
              // narsa bilan cheklanmagan `Text` edi. Joy tugaganda Spacer
              // NOLGA siqiladi, ism esa qisqarmaydi — qurilmada
              // "0.0 kmMUXAMMAD RAXMATILLAY..." bo'lib chiqardi (Galaxy M13,
              // 2026-08-12). Endi ism `DriverRow` ichida, u qisqartiradi.
              // Haydovchi + belgilar — oxirgi qator.
              //
              // 🔴 BELGILAR ilgari to'liq matnli `Chip` edi: "Chekilmaydi",
              // "Konditsioner bor", "Yuk joyi bor"... Ular `Wrap` bo'lib
              // uch-to'rt qatorga yoyilardi va karta ikki barobar cho'zilib
              // ketardi — ekranga bittayu yarimta safar sig'ardi (egasi
              // qurilmada ko'rdi, 2026-08-12). Ro'yxatda belgi faqat
              // "shunaqasi bor" degan ishora bo'lishi kerak; to'liq nomlarni
              // odam safarni ochganda ko'radi.
              Row(
                children: [
                  Expanded(
                    child: mine
                        ? _MineStatus(ride: ride)
                        : DriverRow(
                            name: ride.driver?.name,
                            rating: ride.driver?.rating,
                            gender: ride.driver?.gender,
                            avatarUrl: ride.driver?.avatar,
                            seed: ride.driver?.id,
                            avatarRadius: 14,
                            inlineRating: true,
                          ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(width: AppSpace.sm),
                    for (final badge in badges.take(_maxBadges))
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpace.xs),
                        child: RideBadgeIcon(badge),
                      ),
                    if (badges.length > _maxBadges)
                      Text(
                        ' +${badges.length - _maxBadges}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O'z e'lonimning holati: qidiruvda ko'rinadimi.
///
/// Faollashmagan e'lon qidiruvda UMUMAN chiqmaydi, lekin ro'yxatda oddiy
/// e'londan farq qilmasdi — haydovchi uni joylandi deb o'ylab yurardi
/// (qurilmada ko'rildi 2026-08-13: paket tugagach e'lon yaratildi, lekin
/// faollashmadi).
class _MineStatus extends StatelessWidget {
  const _MineStatus({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final active = ride.status.toLowerCase() == 'active';

    return Row(
      children: [
        Icon(
          active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 16,
          color: active ? theme.colorScheme.outline : theme.colorScheme.error,
        ),
        const SizedBox(width: AppSpace.xs),
        Flexible(
          child: Text(
            active ? t.rideVisible : t.rideNotActive,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: active
                  ? theme.colorScheme.outline
                  : theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

/// Safar belgisi — IKONKA va yozuv.
///
/// 🔴 Ilgari bu yerda EMOJI turardi (🚭 🐾 ❄️ ...). Emoji har telefonda
/// boshqacha chiziladi (Samsung, Google, Xiaomi — uch xil rasm), rangi
/// mavzuga bo'ysunmaydi va yonidagi chiziqli ikonkalar bilan bir uslubda
/// ko'rinmaydi. Egasi buni qurilmada aytdi (2026-08-13): "chiroyli
/// chiqmayapti".
///
/// Material to'plami tanlandi: Flutter bilan birga keladi (qo'shimcha fayl
/// yo'q), chiziqli uslubi ilovaning qolgan ikonkalari bilan bir xil va
/// rangi mavzudan olinadi.
/// "Adolatli narx" belgisi — narx yonida, ishonch bildirgichi.
///
/// Qulaylik belgilaridan AJRATILGAN (narx haqida, konditsioner emas) va
/// yozuvli: ro'yxatда yozuvsiz ikonka nima ekanini aytmasdi.
class _FairPriceChip extends StatelessWidget {
  const _FairPriceChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.balance,
            size: 12,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpace.xs),
          // Shrift kattalashtirilgan telefonda ham qatorni toshirmasin.
          Flexible(
            child: Text(
              AppStrings.of(context).fairPrice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RideBadge {
  const RideBadge(this.icon, this.label, {this.prohibited = false});

  final IconData icon;
  final String label;

  /// "Mumkin emas" ma'nosi — ikonka ustidan chiziq tortiladi.
  /// Material'da tayyor "taqiqlangan" varianti faqat chekish uchun bor
  /// (`smoke_free`), qolganini o'zimiz chizamiz.
  final bool prohibited;
}

/// Belgi ikonkasi. [RideBadge.prohibited] bo'lsa ustidan qiya chiziq o'tadi —
/// aks holda "hayvon mumkin" va "hayvon mumkin emas" bir xil ko'rinardi.
class RideBadgeIcon extends StatelessWidget {
  const RideBadgeIcon(this.badge, {super.key, this.size = 16, this.color});

  final RideBadge badge;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = Icon(badge.icon, size: size, color: tint);
    if (!badge.prohibited) return icon;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          icon,
          Transform.rotate(
            angle: -0.7,
            child: Container(width: size * 1.05, height: 1.6, color: tint),
          ),
        ],
      ),
    );
  }
}

/// Safar belgilari — web'dagi to'plam bilan bir xil (BlaBlaCar uslubi).
/// [includeGender] — «Faqat ayollar» belgisi ro'yxatga kirsinmi.
///
/// 🔴 SAFAR SAHIFASIDA `false`: u yerda belgilar «Qulayliklar» bo'limi
/// ostida chiziladi, bu esa qulaylik EMAS — bron shartidir. Kartochkada
/// esa bo'lim yo'q va belgi yagona ko'rinish yo'li, shuning uchun
/// standart qiymat `true`.
List<RideBadge> rideBadges(
  Ride ride,
  AppStrings t, {
  bool includeGender = true,
}) => [
  // `smoke_free` — Material'ning O'ZIDA chizilgan taqiq belgisi.
  if (ride.noSmoking) RideBadge(Icons.smoke_free, t.noSmoking),
  if (ride.noPets) RideBadge(Icons.pets, t.noPets, prohibited: true),
  if (ride.maxTwoBack)
    RideBadge(Icons.airline_seat_recline_normal, t.maxTwoBack),
  if (ride.hasAc) RideBadge(Icons.ac_unit, t.hasAc),
  if (ride.hasLuggage) RideBadge(Icons.luggage, t.hasLuggage),
  if (ride.takesParcels) RideBadge(Icons.local_shipping, t.takesParcels),
  // Narx kelishiladi — "kelishuv" ma'nosi, suhbat emas.
  if (ride.isNegotiable) RideBadge(Icons.handshake, t.negotiable),
  // Haydash uslubi: uchtasi ham BIR-BIRIDAN ajralib turishi kerak, chunki
  // kartochkada faqat ikonka ko'rinadi (yozuvsiz).
  if (ride.drivingSpeed == DrivingSpeed.calm)
    RideBadge(Icons.slow_motion_video, t.speedCalm),
  if (ride.drivingSpeed == DrivingSpeed.normal)
    RideBadge(Icons.speed, t.speedNormal),
  if (ride.drivingSpeed == DrivingSpeed.fast)
    RideBadge(Icons.bolt, t.speedFast),
  // YO'LDA MUSIQA — IXTIYORIY. Belgilanmagan bo'lsa belgi UMUMAN
  // chizilmaydi: «did ko'rsatilmagan» degan bo'sh belgi kartani
  // to'ldiradi-yu, hech nima aytmaydi (izohi `Ride.musicTaste` da).
  //
  // ⚠️ «farqi yo'q» ham KO'RSATILMAYDI — u ham ma'lumot bermaydi.
  if (ride.musicTaste == 'quiet')
    RideBadge(Icons.volume_mute_outlined, t.musicQuiet),
  if (ride.musicTaste == 'loud')
    RideBadge(Icons.music_note_outlined, t.musicLoud),
  if (ride.musicTaste == 'talk') RideBadge(Icons.forum_outlined, t.musicTalk),
  /*
   * «FAQAT AYOLLAR» — haydovchining SALON haqidagi e'loni (qaytarildi
   * 08.09.2026; izohi `SearchFilters.womenOnly` da).
   *
   * ENG OXIRIDA turadi: qulaylik belgilari ko'p bo'lsa ham bu ko'zga
   * tashlanadigan joyda qolsin (kartochkada belgilar tartib bilan
   * chiziladi va oxirgisi qatorning boshiga tushmaydi).
   *
   * ⚠️ `male` uchun belgi ATAYIN YO'Q: e'lon formasida bunday tanlov
   * qolmadi. Eski e'londa qiymat uchrashi mumkin, lekin uni ko'rsatish
   * o'chirilgan cheklovni tiriltirgandek bo'lardi.
   */
  if (includeGender && ride.genderRestriction == 'female')
    RideBadge(Icons.female, t.forWomen),
];
