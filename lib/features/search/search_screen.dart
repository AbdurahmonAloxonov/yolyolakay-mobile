import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/cities.dart';
import '../../core/format.dart';
import '../../core/voice_route.dart';
import '../../data/models/ride.dart';
import '../../app/theme.dart';
import '../shared/yol_refresh.dart';
import '../shared/city_field.dart';
import '../shared/ui.dart';
import '../../l10n/strings.dart';
import '../shared/away_card.dart';
import '../shared/brand/brand_panels.dart';
import '../shared/state_views.dart';
import 'recommendations_block.dart';
import '../shared/notification_bell.dart';
import '../shared/settings_button.dart';
import 'city_picker.dart';
import 'past_drivers_row.dart';
import 'voice_route_button.dart';
import '../rides/ride_card.dart';
import '../rides/today_card.dart';
import '../../../app/dimens.dart';
import '../shared/yol_button.dart';

/// Safar qidirish formasi.
///
/// Gateway qidiruvi koordinata bilan ishlaydi — shahar tanlanadi, markaz
/// koordinatasi + `radius_km` yuboriladi. Sana filtri backend'da yo'q,
/// repozitoriy klientda saralaydi.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

/// Ovoz natijasi qaysi maydonga tegishli ekani.
enum _VoiceField { from, to }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Place? _from;
  Place? _to;
  DateTime? _date;
  int _seats = 1;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      // 🔴 KECHAGI KUN EMAS (10.09.2026): `now.subtract(1 kun)` turardi va
      // taqvimda kechagi sanani tanlash mumkin edi. O'tgan kunga hamroh
      // qidirish hech qachon ma'noli emas — natija doim bo'sh bo'lardi.
      // Bugundan boshlaymiz, lekin SOATNI tashlaymiz: `now` da soat bor
      // va u bugungi kunni ba'zan tanlab bo'lmaydigan qilib qo'yardi.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _search() async {
    final t = AppStrings.of(context);
    final from = _from;
    final to = _to;

    if (from == null || to == null) {
      showMessage(context, t.pickBothCities);
      return;
    }
    if (from.name == to.name) {
      showMessage(context, t.sameCityError);
      return;
    }

    await ref.read(recentRoutesProvider.notifier).add(from, to);

    await ref
        .read(searchControllerProvider.notifier)
        .run(
          RideSearchParams(
            originLat: from.lat,
            originLon: from.lon,
            destLat: to.lat,
            destLon: to.lon,
            // Natijalar ekranidagi sarlavha uchun — serverga ketmaydi.
            originName: from.name,
            destName: to.name,
            minSeats: _seats,
            date: _date,
            // Filtr qatoridan MEROS: "faqat ayollar" natijalar ekranida
            // yoqilib qolgan bo'lishi mumkin, u esa endi SERVER filtri.
            // Bu yerda uzatilmasa yangi qidiruv uni jimgina tashlab ketardi —
            // chip yoqiq turadi-yu, ro'yxatda erkak haydovchilar chiqardi.
          ),
        );
    if (mounted) context.push(Routes.searchResults);
  }

  /// Oxirgi yo'nalish chipi bosilganda darhol qayta qidiramiz.
  ///
  /// Koordinata yozuv ichida saqlangan — joy xaritadan yoki geokoderdan
  /// tanlangan bo'lsa ham ishlaydi (ilgari `resolvePlace` uni ro'yxatdan
  /// topolmay, chip jim qolardi).
  void _applyRecent(RecentRoute route) {
    setState(() {
      _from = route.from;
      _to = route.to;
    });
    _search();
  }

  /// Tavsiya bosilganda. Yangi shahar tavsiyasida `from` bo'lmaydi —
  /// mavjud tanlovni saqlaymiz, faqat manzilni almashtiramiz.
  void _applyRecommendation(Place? from, Place to) {
    setState(() {
      if (from != null) _from = from;
      _to = to;
    });
    if (_from != null) _search();
  }

  /// Ovoz bilan aytilgan yo'nalish.
  ///
  /// 🔴 NEGA QAYTA YOZILDI (egasi, 2026-08-25: «ovozdan olingan natija
  /// qidiruvga qo'yilmayapti»): ilgari yarim tanilganda ekranga faqat
  /// «yarmi tushunildi» degan xabar chiqardi va SHU BILAN tugardi. Odam
  /// gapirdi, ilova eshitdi va uni yana qo'lda shahar tanlashga qaytardi —
  /// ya'ni ovoz tugmasi ish qilgandek KO'RINARDI, aslida esa hech nima.
  ///
  /// Endi ovoz HECH QACHON tupikka olib bormaydi: tanilgani maydonga
  /// qo'yiladi, YETISHMAGANI uchun esa ro'yxat darhol ochiladi.
  void _applyVoiceRoute(VoiceRoute route) {
    setState(() {
      if (route.from != null) _from = route.from;
      if (route.to != null) _to = route.to;
    });

    // Ikkalasi ham tanildi — qidiruvni KUTIB O'TIRMAYMIZ. Odam aytgan
    // gapning oxiri "…ga" edi, ya'ni buyruq to'liq: yana "Qidirish"
    // tugmasini bosish ortiqcha.
    if (_from != null && _to != null) {
      _search();
      return;
    }

    // Yarmi tanildi — yetishmagan maydonning ro'yxatini O'ZIMIZ ochamiz.
    _pickMissing();
  }

  /// Bitta ham shahar tanilmadi — eshitilgan matn ro'yxat filtriga tushadi.
  ///
  /// Matn tashlab yuborilmaydi: nutqni tanish "Chilonzo" yoki "Samarkand"
  /// deb yozgan bo'lishi mumkin — ro'yxat buni baribir topadi, odam esa
  /// bir tegishda tanlaydi.
  Future<void> _applyVoiceText(String text) async {
    final target = _from == null ? _VoiceField.from : _VoiceField.to;
    final place = await showPlacePicker(
      context,
      exclude: target == _VoiceField.from ? _to : _from,
      initialQuery: text,
    );
    if (place == null || !mounted) return;
    setState(() {
      if (target == _VoiceField.from) {
        _from = place;
      } else {
        _to = place;
      }
    });
    if (_from != null && _to != null) _search();
  }

  /// Yetishmagan shaharni so'raydi va to'lgach darhol qidiradi.
  Future<void> _pickMissing() async {
    final needFrom = _from == null;
    final place = await showPlacePicker(
      context,
      exclude: needFrom ? _to : _from,
    );
    if (place == null || !mounted) return;
    setState(() {
      if (needFrom) {
        _from = place;
      } else {
        _to = place;
      }
    });
    if (_from != null && _to != null) _search();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final recent = ref.watch(recentRoutesProvider);
    final favorites = ref.watch(favoriteRoutesProvider);
    final recentRides = ref.watch(recentRidesProvider);

    return Scaffold(
      /*
       * 🔴 TORTIB-YANGILASH SHU YERDA HAM (egasi, 2026-09-04: «asosiy
       * qidirish qismida ham yo'q»). Bu ekran forma emas: unda
       * SERVERDAN keladigan uchta blok bor — so'nggi yo'nalishlar,
       * saqlanganlar va oxirgi ko'rilgan safarlar. Ular eskiradi, odam
       * esa yangilash uchun ekrandan chiqib qaytishga majbur edi.
       *
       * ⚠️ Forma maydonlari TEGILMAYDI: tortish faqat ro'yxatlarni
       * qayta so'raydi, kiritilgan shahar va sana o'z joyida qoladi.
       */
      body: YolRefresh(
        onRefresh: () async {
          /*
           * ⚠️ HALOL BO'LAYLIK: bu ekrandagi uchala ro'yxat ham
           * SERVERDAN emas, MAHALLIY keshdan keladi (so'nggi
           * yo'nalishlar, saqlanganlar, oxirgi ko'rilgan safarlar —
           * hammasi `localCache` da). Shuning uchun bu yerda
           * `ref.refresh(...future)` YO'Q: so'raladigan tarmoq
           * chaqiruvining o'zi yo'q.
           *
           * Tortish esa baribir haqiqiy ish qiladi — ro'yxatlar
           * keshdan QAYTA o'qiladi. Boshqa ekranda (masalan safar
           * ochilganda) o'zgargan bo'lsa, shu yerda ko'rinadi.
           *
           * Qisqa pauza — aylanma «yaltirab» o'tib ketmasligi uchun:
           * mahalliy o'qish bir zumda tugaydi va odam harakatining
           * natijasini KO'RA olmaydi.
           */
          ref.invalidate(recentRoutesProvider);
          ref.invalidate(favoriteRoutesProvider);
          ref.invalidate(recentRidesProvider);
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            /*
           * TO'Q SARLAVHA BLOKI — ekranning BAYONOTI (2026-09-02,
           * «YO'L» dizayn tili).
           *
           * 🔴 Ilgari bu ekran oddiy `AppBar` va ikkita kulrang
           * chegarali karta edi. Uchta muammo bir joyda:
           *   • «Safar qidirish» sarlavhasi pastdagi «Qidirish»
           *     tugmasi bilan bir gapni ikki marta aytardi;
           *   • ekranda eng katta va eng qalin matn TANLANMAGAN
           *     shahar joyi edi — bo'sh forma to'ldirilgandek
           *     ko'rinardi;
           *   • birinchi ochilishda ekranning yarmi bo'sh qolardi.
           *
           * Endi tepada savol turadi, qidiruv paneli esa uning ichida
           * — ya'ni ekran «nima qilishim kerak» degan savolga birinchi
           * qarashda javob beradi.
           */
            OrnamentHeader(
              // Blok ostida ATLAS JIYAGI va MUQARNAS: bosh ekran ilovaning
              // peshtoqi, ya'ni naqsh bu yerda eng kuchli bo'ladi.
              //
              // 🔴 Ilgari blok shunchaki yumaloq burchakli to'q quti edi.
              // Yumaloq burchak — «kesish»; muqarnas esa O'TISH: to'q
              // zamindan yorug'iga o'tish joyi me'morchilikda har doim
              // shu qatorlar bilan bezatiladi.
              jiyak: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        // 🔴 EKRAN O'QIGICH UCHUN — SAHIFANING SARLAVHASI (2026-09-04,
                        // o'lchandi): bu ekranda `AppBar` yo'q, ya'ni «header» belgisi
                        // hech qayerdan kelmasdi va TalkBack bo'limlar bo'ylab sakray
                        // olmasdi. Izohi `SectionLabel` da.
                        child: Semantics(
                          header: true,
                          child: Text(
                            t.searchHeadline,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: onHeroSurface(theme),
                            ),
                          ),
                        ),
                      ),
                      // ⚠️ Qo'ng'iroq va ⚙️ to'q fonda — o'z rangini oladi.
                      IconTheme(
                        data: IconThemeData(color: onHeroSurface(theme)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [NotificationBell(), SettingsButton()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _searchPanel(t, theme),
                  const SizedBox(height: AppSpace.md),
                  // Ilovaning ENG KO'P bosiladigan tugmasi — brend
                  // tugmasi (izohi `yol_button.dart` da).
                  YolButton(
                    onPressed: _search,
                    icon: Icons.search,
                    label: t.searchButton,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /*
           * «YAQIN SAFAR» — formadan OLDIN.
           *
           * 🔴 Ilgari bu ekran bo'sh forma bilan ochilardi: bir soatdan
           * keyin jo'naydigan odam ham shahar/sana tanlashdan boshlardi.
           * Endi safari bor bo'lsa u eng tepada turadi. Bo'lmasa karta
           * umuman chizilmaydi va ekran avvalgidek qoladi.
           */
                  /*
           * «SIZSIZ NIMA BO'LDI» — «Yaqin safar»dan ham TEPADA.
           *
           * Backend push yubormaydi (`core/away_digest.dart`), ya'ni odam
           * yo'q paytida kelgan xabar hech qanday belgi qoldirmaydi.
           * Shuning uchun bu birinchi ko'zga tashlanadigan joyda turadi.
           * Yangilik bo'lmasa umuman chizilmaydi.
           */
                  const AwayCard(),
                  const TodayCard(),
                  // SEVIMLI YO'NALISHLAR — o'zi qadagan (uy<->ish). So'nggilardan
                  // ustun turadi: doim ko'rinadi, o'chmaydi.
                  if (favorites.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xl),
                    SectionLabel(t.favoriteRoutes),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final route in favorites)
                          _RouteChip(
                            route: route,
                            favorite: true,
                            icon: Icons.star,
                            onTap: () => _applyRecent(route),
                            onStar: () => ref
                                .read(favoriteRoutesProvider.notifier)
                                .toggle(route.from, route.to),
                          ),
                      ],
                    ),
                  ],
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xl),
                    SectionLabel(t.recentRoutes),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final route in recent)
                          _RouteChip(
                            route: route,
                            favorite: ref
                                .read(favoriteRoutesProvider.notifier)
                                .contains(route.from, route.to),
                            icon: Icons.near_me_outlined,
                            onTap: () => _applyRecent(route),
                            onStar: () => ref
                                .read(favoriteRoutesProvider.notifier)
                                .toggle(route.from, route.to),
                          ),
                      ],
                    ),
                  ],
                  /*
           * SO'NGGI KO'RILGAN SAFARLAR — yo'nalishlardan KEYIN.
           *
           * 🔴 Odam safarni ochadi, «o'ylab ko'raman» deb chiqadi va uni
           * qayta topa olmaydi: qidiruvni boshidan takrorlashi kerak
           * bo'lardi (shahar, sana, filtr) — ko'pchilik takrorlamaydi.
           *
           * Yo'nalish chiplaridan FARQI: chip «qayerdan qayerga» ni
           * qaytaradi, bu esa AYNAN O'SHA safarni (narxi, vaqti,
           * haydovchisi bilan).
           */
                  /*
           * «YANA O'SHA HAYDOVCHI BILAN» — so'nggi ko'rilganlardan OLDIN.
           *
           * Sabab `pastDriversProvider` izohida: bir marta yoqqan
           * haydovchini qayta topish O'zbekistonda eng tabiiy xatti-harakat
           * edi, lekin ilovada bunga yo'l yo'q edi. Ro'yxat KESHDAN keladi
           * — bu ekranga birorta ham so'rov qo'shmaydi.
           */
                  PastDriversRow(
                    onRoute: (from, to) {
                      setState(() {
                        _from = from;
                        _to = to;
                      });
                      _search();
                    },
                  ),

                  if (recentRides.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xl),
                    SectionLabel(t.recentlyViewed),
                    const SizedBox(height: AppSpace.sm),
                    for (final ride in recentRides) ...[
                      RideCard(
                        ride: ride,
                        onTap: () => context.push(Routes.ride, extra: ride),
                      ),
                      const SizedBox(height: AppSpace.sm),
                    ],
                  ],
                  // Tavsiyalar — oxirgi yo'nalishlardan PASTDA: o'z tarixi ustun,
                  // tavsiya esa "boshqa nima bor" degan qo'shimcha.
                  RecommendationsBlock(onPick: _applyRecommendation),
                  /*
                   * BOSHLANG'ICH YO'NALISHLAR — FAQAT tarixi yo'q odamga.
                   *
                   * 🔴 NEGA QO'SHILDI (10.09.2026). Yuqoridagi bloklarning
                   * HAMMASI ma'lumotga bog'liq: sevimli yo'nalish, oxirgi
                   * qidiruv, ko'rilgan safar, tavsiya. Yangi odamda
                   * ularning bittasi ham yo'q va ekranning pastki yarmi
                   * BO'M-BO'SH qolardi — tungi rejimda qop-qora. Ilova
                   * «yuklanmagan» yoki «buzuq» bo'lib ko'rinardi.
                   *
                   * HIG `layout.md`: «suriladigan maket ekranning
                   * PASTIGACHA davom etsin».
                   *
                   * ⚠️ BU TAVSIYA EMAS va bu yerda safar SONI
                   * KO'RSATILMAYDI. Bizda mahalliy ma'lumot yo'q,
                   * serverdan so'rash esa mehmonga yopiq
                   * (`/rides/recommendations` → 401, 10.09.2026 da
                   * o'lchandi). Bu shunchaki BOSHLASH NUQTASI: bosilganda
                   * qidiruv to'ldiriladi va odam HAQIQIY natijani ko'radi.
                   * Bo'sh natija ham javob — yolg'on va'dadan yaxshiroq.
                   */
                  if (favorites.isEmpty &&
                      recent.isEmpty &&
                      recentRides.isEmpty)
                    _StarterRoutes(onPick: _applyRecent),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),
          ],
        ),
      ),
    );
  }

  /// QIDIRUV PANELI — to'q sarlavha bloki ichidagi oq karta.
  ///
  /// 🔴 Ilgari bu ikkita alohida karta edi (shaharlar + sana/yo'lovchi)
  /// va ular 380 pikseldan ortiq joy egallardi: ikkita `ListTile`
  /// sarlavha-tagsarlavha juftligi bilan, orasida chiziq va havoda
  /// osilib turgan almashtirish tugmasi. Amalda esa bu yerda ATIGI
  /// TO'RTTA qiymat bor: qayerdan, qayerga, qachon, necha kishi.
  ///
  /// Endi ular bitta panelda va yo'l chizig'i ko'rinishida — ilovaning
  /// imzo shakli qidiruvning O'ZIDAN boshlanadi.
  Widget _searchPanel(AppStrings t, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CityField(
                      label: t.from,
                      city: _from,
                      // 🔴 NEYTRAL (10.09.2026) — `JourneyLine` dagi
                      // jo'nash nuqtasi bilan bir xil qoida: pushti
                      // faqat AMAL va NARXda qoladi, «qayerdan»
                      // esa neytral. Sabab `journey_view.dart` da.
                      dot: theme.colorScheme.onSurfaceVariant,
                      dense: true,
                      // Yo'l chizig'i — endi maydonning O'ZIDA
                      // (izohi `CityField.railDown` da).
                      railDown: true,
                      onTap: () async {
                        final city = await showPlacePicker(
                          context,
                          exclude: _to,
                        );
                        if (city != null) setState(() => _from = city);
                      },
                    ),
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                    CityField(
                      label: t.to,
                      city: _to,
                      dot: theme.colorScheme.secondary,
                      dense: true,
                      railUp: true,
                      onTap: () async {
                        final city = await showPlacePicker(
                          context,
                          exclude: _from,
                        );
                        if (city != null) setState(() => _to = city);
                      },
                    ),
                  ],
                ),
              ),
              // 🔴 ALMASHTIRISH TUGMASI CHIZIQ USTIDA. Ilgari u alohida
              // qatorda, chiziqning yonida havoda osilib turardi va nima
              // bilan bog'liqligi ko'rinmasdi.
              IconButton(
                tooltip: t.swapPlaces,
                icon: const Icon(Icons.swap_vert),
                onPressed: () => setState(() {
                  final temp = _from;
                  _from = _to;
                  _to = temp;
                }),
              ),
            ],
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          /*
           * SANA VA YO'LOVCHILAR — odatda bitta qatorda: ikkisi ham bir
           * so'zli qiymat va yonma-yon turgani joyni tejaydi.
           *
           * 🔴 TOR EKRAN + KATTA MATNDA IKKI QATORGA BO'LINADI
           * (2026-09-04, ko'rikda ko'rildi): 320 px va 1.3 shkalada sana
           * yozuvi «Istalg…» bo'lib qolardi — maydon o'z NOMINI ayta
           * olmasdi, chunki qatorning yarmini yo'lovchi sanagichi
           * egallaydi.
           *
           * ⚠️ Qaror `MediaQuery.sizeOf` dan EMAS, `LayoutBuilder`
           * CHEGARASIDAN olinadi: test muhitida `setSurfaceSize` dan
           * keyin ham `MediaQuery` eski 800 px ni qaytarardi (o'lchandi
           * — shu sababdan birinchi urinish ishlamadi), qolaversa kartaning
           * haqiqiy eni ekran enidan har doim kichik.
           */
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              /*
               * Kerakli enni TAXMIN qilamiz — o'lchov emas, lekin
               * qismlari haqiqiy:
               *   sanagich — ikonka (24) + ikkita 48 px tugma + raqam;
               *     tugmalar matn bilan kattalashmaydi, raqam esa ha;
               *   sana     — ikonka (18) + bo'shliq + «Istalgan sana»
               *     yozuvi (14 px da ~85 px, shkala bilan o'sadi).
               * Ular orasida vertikal ajratgich (`AppSpace.lg`).
               */
              final seatsWidth = 24.0 + 48.0 * 2 + 24.0 * scale;
              final dateWidth = 18.0 + AppSpace.sm + 85.0 * scale;
              final tight =
                  constraints.maxWidth < seatsWidth + dateWidth + AppSpace.lg;
              if (tight) {
                return Column(
                  children: [
                    _dateField(theme, t),
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xs,
                      ),
                      child: Row(children: _seatsField(theme, t)),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _dateField(theme, t)),
                  SizedBox(
                    height: AppSize.buttonHeightCompact,
                    child: VerticalDivider(
                      width: AppSpace.lg,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  ..._seatsField(theme, t),
                ],
              );
            },
          ),
          /*
           * OVOZ — butun yo'nalish bitta gapda.
           *
           * Ataylab IKKALA maydondan KEYIN turadi: u bittasiga emas,
           * ikkalasiga ham tegishli. Maydon yonida tursa odam faqat
           * o'sha maydonning shahrini aytadi (egasi, 2026-08-24).
           *
           * Nutqni tanish xizmati bo'lmasa vidjet o'zi chizilmaydi.
           */
          VoiceRouteButton(
            onRoute: _applyVoiceRoute,
            onRawText: _applyVoiceText,
          ),
        ],
      ),
    );
  }

  /// SANA MAYDONI — qator ham, ustun ham shu bitta ko'rinishdan foydalanadi.
  ///
  /// ⚠️ `minHeight: 48` — o'lchandi (2026-09-04): qator 44 px edi.
  /// Bu qidiruvning ikkinchi eng ko'p bosiladigan joyi.
  Widget _dateField(ThemeData theme, AppStrings t) {
    return InkWell(
      onTap: _pickDate,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  _date == null ? t.anyDate : formatDate(_date, t.lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (_date != null)
                IconButton(
                  tooltip: t.clearDate,
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _date = null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// YO'LOVCHILAR SANAGICHI.
  ///
  /// 🔴 `visualDensity: compact` ATAYIN YO'Q (2026-09-02): u bosiladigan
  /// maydonni 48 dan 40 pikselgacha tushiradi. Yo'lovchi soni — bu
  /// ekrandagi eng ko'p bosiladigan tugmalardan, ularni siqish arzimas
  /// joy yutug'iga arzimaydi.
  List<Widget> _seatsField(ThemeData theme, AppStrings t) {
    return [
      const Icon(Icons.person_outline, size: 18),
      IconButton(
        tooltip: t.seatsDecrease,
        icon: const Icon(Icons.remove_circle_outline, size: 20),
        onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
      ),
      Text('$_seats', style: theme.textTheme.titleMedium),
      IconButton(
        tooltip: t.seatsIncrease,
        icon: const Icon(Icons.add_circle_outline, size: 20),
        onPressed: _seats < 4 ? () => setState(() => _seats++) : null,
      ),
    ];
  }
}

/// Yo'nalish chipi — asosiy qism bosilsa qidiradi, yulduz sevimliga qo'shади/
/// oladi. Sevimlида yulduz to'lган, so'nggida bo'sh (qadash taklifи).
class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.route,
    required this.favorite,
    required this.icon,
    required this.onTap,
    required this.onStar,
  });

  final RecentRoute route;
  final bool favorite;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onStar;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.xs,
                AppSpace.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: scheme.primary),
                  const SizedBox(width: AppSpace.xs),
                  Text('${route.from.name} → ${route.to.name}'),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onStar,
            tooltip: favorite ? t.removeFromFavorites : t.addToFavorites,
            icon: Icon(
              favorite ? Icons.star : Icons.star_border,
              color: favorite ? BrandColors.star : scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yo'l relsi — qidiruv panelidagi ikkita nuqta va bog'lovchi chiziq.
///
/// Ilovaning imzo shakli (`JourneyLine`) bilan bir tilda: pushti nuqta —
/// jo'nash, feruza — manzil. Qidiruv ham «yo'l» bo'lib ko'rinadi.

/// BOSHLANG'ICH YO'NALISHLAR — ilovani endi ochgan odam uchun.
///
/// Izohi `search_screen.dart` dagi chaqiruv joyida. Qisqasi: bu tavsiya
/// emas, ekranni to'ldiradigan BOSHLASH NUQTASI.
///
/// 🔑 Yo'nalishlar mamlakat bo'ylab tanlangan — hammasi Toshkentdan
/// boshlanmaydi. Ro'yxat MAHALLIY (`core/cities.dart`), ya'ni tarmoqsiz
/// ham ishlaydi va hech qanday so'rov yubormaydi.
class _StarterRoutes extends StatelessWidget {
  const _StarterRoutes({required this.onPick});

  final void Function(RecentRoute) onPick;

  static const _pairs = [
    ('Toshkent', 'Samarqand'),
    ('Toshkent', 'Andijon'),
    ('Samarqand', 'Buxoro'),
    ('Toshkent', 'Namangan'),
    ('Buxoro', 'Urganch'),
    ('Qarshi', 'Termiz'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    final routes = <RecentRoute>[];
    for (final (from, to) in _pairs) {
      // Nomi ro'yxatdan topilmasa — chip UMUMAN chizilmaydi. Bosilganda
      // hech nima qilmaydigan tugma bo'shliqdan yomonroq.
      final a = resolvePlace(from);
      final b = resolvePlace(to);
      if (a != null && b != null) routes.add(RecentRoute(from: a, to: b));
    }
    if (routes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.xl),
        SectionLabel(t.popularRoutes),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final route in routes)
              ActionChip(
                onPressed: () => onPick(route),
                // ⚠️ NEYTRAL ZAMIN, feruza EMAS. `ActionChip` standart
                // holda `secondaryContainer` (feruza) oladi, bizda esa
                // feruza «bor / tasdiqlangan» degan MA'NOGA ega —
                // yo'nalish nomida u yolg'on signal berardi. Rang
                // roli qoidasi: `journey_view.dart` izohiga qarang.
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                avatar: Icon(
                  Icons.route_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                label: Text('${route.from.name} — ${route.to.name}'),
              ),
          ],
        ),
      ],
    );
  }
}
