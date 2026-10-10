import 'package:yolyolakay/features/shared/screen_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/geo.dart';
import '../../core/format.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../rides/ride_card.dart';
import '../shared/state_views.dart';
import 'date_strip.dart';
import 'filter_bar.dart';
import 'map_first_results.dart';
import 'search_filters.dart';
import '../../../app/dimens.dart';
import '../shared/refreshable.dart';
import '../shared/skeleton.dart';
import '../../core/cities.dart';
import '../../core/haptics.dart';
import '../../core/route_watch.dart';
import '../shared/brand/brand_panels.dart';
import '../shared/brand/ornament.dart';
import '../shared/scroll_top_fab.dart';

/// Qidiruvni SHU kunda qayta yugurtiradi.
///
/// Ikki joydan chaqiriladi — sana lentasi va bo'sh natijadagi «boshqa
/// kunlar» chiplari — shuning uchun top-level: nusxa qilinsa ikkisi
/// bir-biridan chetga chiqib ketardi.
Future<void> searchOnDay(WidgetRef ref, DateTime day) async {
  final base = ref.read(searchControllerProvider.notifier).lastParams;
  if (base == null) return;
  await ref
      .read(searchControllerProvider.notifier)
      .run(base.copyWith(date: day));
}

/// Qidiruv natijalari + filtr/saralash.
///
/// Filtrlar ham, saralash ham KLIENTDA: backend `/rides/search` faqat
/// koordinata + radius + min_seats ni biladi.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  // "Yuqoriga" tugмаsi va ro'yxат bitta scroll'ni bo'lishadi.
  final _scroll = ScrollController();

  /// RO'YXAT yoki XARITA. Standart — ro'yxat: u tezroq o'qiladi va odam
  /// aynan shunga o'rgangan. Xarita ATAYIN tanlanadigan holat.
  ///
  /// 🔴 XARITA STANDART EMAS (21.09.2026, egasi: «karta integratsiya
  /// qilingandan keyin ilovadagi qismi umuman yoqmadi»). 18.09 da bu
  /// yerda standart XARITAga o'tkazilgan va tanlov `SharedPreferences`
  /// ga yozilgandi — endi yana oddiy holat: ro'yxat.
  bool _mapView = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Ro'yxatni boshiga qaytaradi (silliq).
  ///
  /// `hasClients` tekshiruvi SHART: ro'yxat hali chizilmagan bo'lishi
  /// mumkin (masalan xato holatida) va o'shanda `animateTo` tashlaydi.
  void _backToTop() {
    if (!_scroll.hasClients) return;
    if (_scroll.offset <= 0) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    // FILTR/SARALASH o'zgarsa ham ro'yxat TEPADAN boshlansin.
    //
    // 🔴 Egasi (2026-08-21) yangilanishda shuni aytdi, lekin muammo
    // kengroq: filtr almashganda ro'yxat butunlay boshqa bo'ladi-yu,
    // siljish o'sha joyda qolardi — odam yangi ro'yxatning o'rtasidan
    // chiqib, birinchi (eng mos) natijalarni ko'rmasdi.
    ref.listen(searchFiltersProvider, (_, _) => _backToTop());
    ref.listen(searchSortProvider, (_, _) => _backToTop());
    // Yangi qidiruv ham xuddi shunday: bu boshqa yo'nalish, boshqa ro'yxat.
    ref.listen(searchControllerProvider, (_, _) => _backToTop());

    final results = ref.watch(searchControllerProvider);
    final filters = ref.watch(searchFiltersProvider);
    final sort = ref.watch(searchSortProvider);
    final params = ref.read(searchControllerProvider.notifier).lastParams;
    final hasMapContent =
        results.valueOrNull
            ?.where(SearchFilters.isBookable)
            .any(filters.matches) ??
        false;

    return Scaffold(
      appBar: AppBar(
        /*
         * SARLAVHA — QAYSI YO'NALISH QIDIRILGANI (2026-09-02, «YO'L»).
         *
         * 🔴 Ilgari bu yerda «Natijalar» degan umumiy so'z turardi.
         * Ya'ni ekran o'zi haqida hech nima aytmasdi: odam boshqa
         * yo'nalishga o'tib, keyin qaysi ro'yxatga qarayotganini
         * unutishi mumkin edi (ayniqsa «boshqa manzil» taklifidan
         * keyin — u yo'nalishni JIMGINA almashtiradi).
         *
         * Endi sarlavha yo'nalishni, ostidagi qator esa sana va
         * natija sonini aytadi.
         */
        toolbarHeight: AppSize.resultsToolbar,
        title: _ResultsTitle(
          params: params,
          // 🔴 XOM SON EMAS (10.09.2026): ilgari bu yerda serverdan
          // kelgan hamma narsa sanalardi va sarlavha «5 ta safar
          // topildi» derdi, ro'yxatda esa 2 ta karta turardi —
          // qolgan uchtasi jo'nab ketgan edi. Sarlavha ro'yxat bilan
          // BIR XIL narsani sanashi kerak.
          count: results.valueOrNull?.where(SearchFilters.isBookable).length,
        ),
        actions: [
          // RO'YXAT ⇄ XARITA: bizda uchrashuv nuqtasi hal qiluvchi, ro'yxat
          // esa uni ko'rsatmaydi (manzil — haydovchi yozgan erkin matn).
          //
          // 🔴 FAQAT XARITAGA QO'YADIGAN NARSA BO'LSA (28.09.2026, egasi
          // qurilmada: «karta ochilmayapti»). Xarita faqat KO'RINADIGAN
          // natija bo'lsa chiziladi, tugma esa doim turardi: safar yo'q
          // (yoki filtr hammasini yashirgan) yo'nalishda uni bosganda
          // belgi almashardi-yu, ekranda hech narsa o'zgarmasdi.
          if (hasMapContent)
            IconButton(
              tooltip: _mapView ? t.viewList : t.viewMap,
              icon: Icon(
                _mapView ? Icons.view_list_outlined : Icons.map_outlined,
              ),
              onPressed: () => setState(() => _mapView = !_mapView),
            ),
        ],
        bottom: const JiyakLine(),
      ),
      // Xaritada "yuqoriga" tugmasining ma'nosi yo'q — ro'yxat yo'q.
      floatingActionButton: _mapView ? null : ScrollTopFab(controller: _scroll),
      // Tortib-yangilash YUKLANISH va XATO holatida ham ishlaydi
      // (izohi `YolRefreshable` da). Xarita ko'rinishida tortish o'zi
      // ishlamaydi — u suriladigan emas, ya'ni xaritaga xalaqit bermaydi.
      body: YolRefreshable<List<Ride>?>(
        value: results,
        onRefresh: () async =>
            ref.read(searchControllerProvider.notifier).refresh(),
        loading: const ListSkeleton(),
        builder: (rides) {
          if (rides == null || rides.isEmpty) {
            /*
              🔴 "Safar topilmadi" — boshi berk javob: odam nima qilishini
              bilmaydi va ilovadan chiqib ketadi. Ayni paytda platformada
              safar BOR, faqat boshqa yo'nalishda.

              Ilgari bu yerda "doirani 100 km ga kengaytirish" tugmasi bor
              edi. U ZARAR keltirardi: `radius_km` jo'nash VA manzilning
              ikkalasiga qo'llanadi, ya'ni kengaytirish BOSHQA MANZILLARNI
              ro'yxatga qo'shib yuborardi — Andijon so'ralganda Chortoq
              safari "natija" bo'lib chiqardi (egasi qurilmada topdi).

              Endi boshqa manzillar natijaga ARALASHMAYDI: ular ochiq,
              nomi va soni bilan taklif qilinadi (`_Alternatives`).
            */
            return _NoRidesView(params: params);
          }

          // Har safar uchun jo'nash nuqtasidan masofa — saralash va kartada
          // ko'rsatish uchun. Origin bo'lmasa (kutilmagan) masofa yo'q.
          final distances = <String, double>{};
          if (params != null) {
            for (final ride in rides) {
              distances[ride.id] = distanceKm(
                fromLat: params.originLat,
                fromLon: params.originLon,
                toLat: ride.originLat,
                toLon: ride.originLon,
              );
            }
          }

          // IKKI QADAM (izohi `SearchFilters.isBookable` da): avval umuman
          // yaroqsizini (tugagan, bekor qilingan, jo'nab ketgan) tashlaymiz —
          // u pastdagi «filtrlar tufayli yashirildi» hisobiga KIRMASLIGI
          // kerak; keyin foydalanuvchi filtrlarini qo'llaymiz.
          final bookable = rides.where(SearchFilters.isBookable).toList();
          final visible = bookable.where(filters.matches).toList()
            ..sort((a, b) => _compare(a, b, sort, distances));
          final hidden = bookable.length - visible.length;

          // Narx konteksti — MEDIAN (o'rtacha emas): bitta juda qimmat e'lon
          // o'rtachani tortib ketadi va qolgan hammasi "arzon" bo'lib
          // chiqardi. 3 tadan kam natijada umuman hisoblanmaydi — ikkita
          // e'lon orasidagi "o'rtacha" odamga hech nima aytmaydi.
          final median = _medianPrice(visible);

          /*
           * RO'YXAT KONTEKSTI — sarlavha AYTMAGAN narsa.
           *
           * Son sarlavhada bor, shuning uchun u bu yerda faqat FILTR
           * biror narsani yashirganda qaytadi: o'shanda «2 ta safar»
           * sarlavhadagi «5 ta safar topildi» dan farq qiladi va odam
           * filtr ishlayotganini ko'radi.
           */
          final listContext = [
            if (hidden > 0) t.ridesFound(visible.length),
            if (median != null)
              t.averagePrice('${formatPrice(median)} ${t.sum}'),
          ].join('  ·  ');

          // Yo'l davomiyligi — YO'NALISH bo'yicha bitta so'rov (izohi
          // `routeBetweenProvider` da). Natijalar deyarli har doim bitta
          // shahar juftligi bo'lgani uchun amalda bitta chaqiruv ketadi.
          final routeDuration = visible.isEmpty
              ? null
              : ref
                    .watch(routeBetweenProvider(routeKeyFor(visible.first)))
                    .valueOrNull
                    ?.duration;

          return Column(
            children: [
              const SizedBox(height: AppSpace.sm),
              /*
               * SANA LENTASI — filtrdan OLDIN.
               *
               * Sana o'zgartirish uchun odam orqaga qaytib, formani ochib,
               * kalendarni chaqirishi kerak edi — va o'sha kunda safar
               * bor-yo'qligini tanlagunicha BILMASDI. Endi son oldindan
               * ko'rinadi, bo'sh kun esa bosilmaydi.
               */
              DateStrip(onPick: (day) => searchOnDay(ref, day)),
              const SizedBox(height: AppSpace.sm),
              const FilterBar(),
              // Ro'yxat KONTEKSTI — narx darajasi va (filtr yashirgan
              // bo'lsa) ko'rinayotgan son.
              //
              // ⚠️ Matn BO'SH bo'lsa qator UMUMAN chizilmaydi. Ilgari
              // shart faqat «natija bormi» edi va matn bo'shab qolganda
              // ekranda YOLG'IZ LUPA IKONKASI osilib turardi — hech
              // narsa aytmaydigan bezak (2026-09-02 rasmda ko'rindi).
              if (visible.isNotEmpty && listContext.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.sm,
                    AppSpace.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        /*
                         * 🔴 SON IKKI MARTA YOZILARDI (2026-09-02).
                         *
                         * Sarlavha endi «Toshkent — Samarqand · 3 sentabr ·
                         * 2 ta safar topildi» deydi, bu qator esa AYNAN
                         * o'sha sonni takrorlardi. Takror ma'lumot emas —
                         * u shovqin va o'quvchini ishonchdan mahrum qiladi.
                         *
                         * Endi bu yerda faqat NARX KONTEKSTI qoladi.
                         * Son esa FILTR biror narsani yashirgandagina
                         * qaytadi — o'shanda u sarlavhadagidan FARQ
                         * qiladi va ma'no kasb etadi.
                         */
                        listContext,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpace.sm),
              Expanded(
                // XARITA ro'yxat O'RNIGA: ikkalasini bir vaqtda ko'rsatish
                // telefon ekranida ikkalasini ham foydasiz qilardi.
                // Filtr paneli va natija soni ikkala ko'rinishda ham qoladi.
                child: _mapView && visible.isNotEmpty
                    // XARITA-BIRINCHI: xarita to'liq ekran, ro'yxat uning
                    // USTIGA sudralib chiqadi (izohi `MapFirstResults` da).
                    // Ilgari ikkalasi bir-birini ALMASHTIRARDI va "qulay
                    // joydan chiqadigan eng arzoni qaysi?" degan savol
                    // hech qachon bitta ekranda javob olmasdi.
                    ? MapFirstResults(
                        rides: visible,
                        onTapRide: (ride) =>
                            context.push(Routes.ride, extra: ride),
                        itemBuilder: (context, ride, selected) => DecoratedBox(
                          // Xaritadan tanlangan karta ajratib turiladi:
                          // u ro'yxat boshiga chiqadi, lekin belgisiz
                          // "nega tartib o'zgardi?" degan savol qolardi.
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: selected
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: RideCard(
                            ride: ride,
                            distanceKm: distances[ride.id],
                            medianPrice: median,
                            routeDuration:
                                routeKeyFor(ride) == routeKeyFor(visible.first)
                                ? routeDuration
                                : null,
                            onTap: () => context.push(Routes.ride, extra: ride),
                          ),
                        ),
                      )
                    : visible.isEmpty
                    ? ListView(
                        children: [
                          EmptyView(
                            icon: Icons.filter_alt_off_outlined,
                            title: t.nothingMatchesFilters,
                            subtitle: t.hiddenByFilters(hidden),
                            // Sabab AYTILGAN edi, lekin uni bartaraf qilish
                            // yo'li berilmagandi: odam filtr shtorkasini
                            // ochib, yoqilganlarini birma-bir izlab
                            // o'chirishi kerak edi. Bu — bir bosish.
                            actionLabel: t.clearFilters,
                            onAction: () => ref
                                .read(searchFiltersProvider.notifier)
                                .reset(),
                          ),
                          // «Hammasini tozalash» BUTUN tanlovni yo'q qiladi,
                          // ko'pincha esa ortiqchasi BITTA filtr bo'ladi.
                          // Chiplar shuni bir bosishda olib tashlaydi.
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpace.lg,
                            ),
                            child: ActiveFilterChips(),
                          ),
                          const SizedBox(height: AppSpace.xl),
                        ],
                      )
                    : ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visible.length + (hidden > 0 ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpace.md),
                        itemBuilder: (context, index) {
                          if (index == visible.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                t.hiddenByFilters(hidden),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            );
                          }
                          final ride = visible[index];
                          return RideCard(
                            ride: ride,
                            distanceKm: distances[ride.id],
                            medianPrice: median,
                            // Bir xil yo'nalishdagi safarlar uchun bir xil
                            // davomiylik — kartochka uni o'zi so'ramaydi.
                            routeDuration:
                                routeKeyFor(ride) == routeKeyFor(visible.first)
                                ? routeDuration
                                : null,
                            onTap: () => context.push(Routes.ride, extra: ride),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _compare(Ride a, Ride b, SearchSort sort, Map<String, double> distances) {
    switch (sort) {
      case SearchSort.distance:
        // Masofasi noma'lumlar oxirida qolsin.
        final da = distances[a.id] ?? double.infinity;
        final db = distances[b.id] ?? double.infinity;
        return da.compareTo(db);
      case SearchSort.price:
        return a.pricePerSeat.compareTo(b.pricePerSeat);
      case SearchSort.time:
        final ta = a.departureTime;
        final tb = b.departureTime;
        if (ta == null || tb == null) return 0;
        return ta.compareTo(tb);
    }
  }
}

/// Bo'sh natija ekrani — «bu yo'nalishda safar yo'q, lekin bularga bor».
///
/// 🔴 Izohi `SearchResultsScreen` ichida: radiusni kengaytirish boshqa
/// manzillarni JIM aralashtirib yuborardi. Bu yerda ular ochiq taklif
/// qilinadi va tanlash odamda qoladi.
class _NoRidesView extends ConsumerWidget {
  const _NoRidesView({required this.params});

  final RideSearchParams? params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final alternatives = ref.watch(alternativeDestinationsProvider);
    final otherDays = ref.watch(alternativeDatesProvider);

    // Yo'nalish ATAYIN nomi bilan aytiladi: umumiy "safar topilmadi"
    // qaysi so'rovga javob ekanini noaniq qoldiradi va odam o'zi yozgan
    // shaharni xato yozdimmi deb o'ylaydi.
    final fromName = params == null
        ? null
        : nearestPlace(params!.originLat, params!.originLon)?.name;
    final toName = params == null
        ? null
        : nearestPlace(params!.destLat, params!.destLon)?.name;

    return ListView(
      padding: const EdgeInsets.all(AppSpace.xl),
      children: [
        const SizedBox(height: AppSpace.xl),
        Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
        const SizedBox(height: AppSpace.lg),
        Text(
          fromName != null && toName != null
              ? '$fromName → $toName: ${t.noRidesYet}'
              : t.noResults,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          t.noDriversYet,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),

        // ===== YO'NALISHNI KUZATISH =====
        // 🔴 Bo'sh natija — odam KETADIGAN nuqta. Uni chaqirib
        // qaytarishning yagona yo'li push, u esa hali yuborilmaydi
        // (backend xati §2). Shu sabab mahalliy kuzatuv: ilova o'zi
        // tekshiradi (izohi `core/route_watch.dart` da).
        if (params != null && fromName != null && toName != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xl),
            child: _WatchRouteButton(
              params: params!,
              fromName: fromName,
              toName: toName,
            ),
          ),

        // ===== BOSHQA KUNLAR =====
        // Bo'sh natijaning eng ko'p uchraydigan sababi — SANA, shuning
        // uchun bu blok manzillardan OLDIN turadi.
        otherDays.maybeWhen(
          data: (days) => days.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.ridesOnOtherDays,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        t.tapDayToSearch,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: [
                          for (final d in days)
                            ActionChip(
                              avatar: const Icon(
                                Icons.event_available_outlined,
                                size: 18,
                              ),
                              label: Text(
                                '${formatDate(d.day, t.lang)}  ·  ${d.count}',
                              ),
                              onPressed: () => _searchOn(context, ref, d.day),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
          orElse: () => const SizedBox.shrink(),
        ),

        // ===== MUQOBIL MANZILLAR =====
        // Yuklanayotgani yoki xato ko'rsatilmaydi: bu QO'SHIMCHA yordam,
        // uning yiqilishi bo'sh natija ekranini buzmasligi kerak.
        alternatives.maybeWhen(
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromName == null
                            ? t.ridesAvailableTo
                            : t.ridesAvailableFrom(fromName),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        t.tapCityToSearch,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: [
                          for (final alt in list)
                            ActionChip(
                              avatar: const Icon(
                                Icons.place_outlined,
                                size: 18,
                              ),
                              label: Text('${alt.name}  ·  ${alt.count}'),
                              onPressed: () =>
                                  _searchTo(context, ref, alt.name),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
          orElse: () => const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpace.xxl),
        const SizedBox(width: 220, child: OrnamentMark()),
        const SizedBox(height: AppSpace.xl),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(t.changeSearch),
        ),
      ],
    );
  }

  /// Tanlangan KUN bo'yicha qidiruvni qayta yugurtiradi — odam formaga
  /// qaytib, kalendarni ochib, sanani qo'lda tanlashi kerak emas.
  Future<void> _searchOn(BuildContext context, WidgetRef ref, DateTime day) =>
      searchOnDay(ref, day);

  /// Tanlangan shahar bo'yicha qidiruvni QAYTA yugurtiradi — odam formaga
  /// qaytib, qo'lda yozib, yana bosishi kerak emas.
  Future<void> _searchTo(
    BuildContext context,
    WidgetRef ref,
    String cityName,
  ) async {
    final base = params;
    final place = resolvePlace(cityName);
    if (base == null || place == null) return;

    await ref
        .read(searchControllerProvider.notifier)
        .run(
          RideSearchParams(
            originLat: base.originLat,
            originLon: base.originLon,
            destLat: place.lat,
            destLon: place.lon,
            radiusKm: base.radiusKm,
            minSeats: base.minSeats,
            date: base.date,
            priceMin: base.priceMin,
            priceMax: base.priceMax,
            // Boshqa manzilga o'tildi — sarlavha ham shuni ko'rsatsin.
            originName: base.originName,
            destName: place.name,
          ),
        );
  }
}

/// Natijalarning MEDIAN narxi — "arzon/qimmat" ishorasi uchun.
///
/// `null` qaytaradi, agar natija 3 tadan kam bo'lsa yoki narxlar yaroqsiz
/// bo'lsa: ikkita e'lon orasidagi "o'rtacha" odamga hech nima aytmaydi va
/// yolg'on ishonch beradi.
double? _medianPrice(List<Ride> rides) {
  final prices = [
    for (final ride in rides)
      if (ride.pricePerSeat > 0) ride.pricePerSeat,
  ]..sort();
  if (prices.length < 3) return null;
  final mid = prices.length ~/ 2;
  return prices.length.isOdd
      ? prices[mid]
      : (prices[mid - 1] + prices[mid]) / 2;
}

/// «Safar chiqsa xabar bering» — bo'sh natijadagi yagona ilinj.
///
/// Bitta tugma: bosilsa qo'shiladi, qayta bosilsa olib tashlanadi.
/// Cheklov OCHIQ yozilgan — bu push emas va uning o'rnini bosmaydi.
class _WatchRouteButton extends ConsumerStatefulWidget {
  const _WatchRouteButton({
    required this.params,
    required this.fromName,
    required this.toName,
  });

  final RideSearchParams params;
  final String fromName;
  final String toName;

  @override
  ConsumerState<_WatchRouteButton> createState() => _WatchRouteButtonState();
}

class _WatchRouteButtonState extends ConsumerState<_WatchRouteButton> {
  bool? _on;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final store = ref.watch(routeWatchStoreProvider);
    final on = _on ?? store.contains(widget.fromName, widget.toName);

    return Column(
      children: [
        FilledButton.tonalIcon(
          onPressed: () async {
            AppHaptics.select();
            final watch = RouteWatch(
              fromName: widget.fromName,
              fromLat: widget.params.originLat,
              fromLon: widget.params.originLon,
              toName: widget.toName,
              toLat: widget.params.destLat,
              toLon: widget.params.destLon,
              createdAt: DateTime.now(),
            );
            // O'CHIRILAYOTGAN bo'lsa serverdagi obunani ham topib olamiz —
            // `toggle` dan KEYIN mahalliy yozuv yo'q bo'ladi.
            final existing = store.find(watch.key);
            final now = await store.toggle(watch);
            // Tugma DARHOL javob beradi: server obunasi tarmoqni kutadi,
            // kuzatuvning o'zi esa mahalliy va allaqachon yozildi.
            if (mounted) setState(() => _on = now);

            final repo = ref.read(ridesRepositoryProvider);
            if (now) {
              final id = await repo.createRouteSubscription(
                originLat: watch.fromLat,
                originLon: watch.fromLon,
                destLat: watch.toLat,
                destLon: watch.toLon,
              );
              // ⚠️ Odam shu orada kuzatuvni o'chirgan bo'lishi mumkin —
              // unda obuna serverda yetim qolmasin.
              if (id != null) {
                if (store.contains(widget.fromName, widget.toName)) {
                  await store.setServerId(watch.key, id);
                } else {
                  await repo.deleteRouteSubscription(id);
                }
              }
            } else if (existing?.serverId != null) {
              await repo.deleteRouteSubscription(existing!.serverId!);
            }
          },
          icon: Icon(
            on ? Icons.notifications_active : Icons.notifications_none,
          ),
          label: Text(on ? t.routeWatchOn : t.routeWatchAdd),
        ),
        const SizedBox(height: AppSpace.xs),
        // Cheklov YASHIRILMAYDI: «xabar beramiz» deb va'da qilib, keyin
        // fon rejimida jim qolish ishonchni yo'qotadi.
        Text(
          t.routeWatchHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Natijalar sarlavhasi — yo'nalish va uning ostida sana/soni.
class _ResultsTitle extends StatelessWidget {
  const _ResultsTitle({required this.params, required this.count});

  final RideSearchParams? params;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final from = params?.originName;
    final to = params?.destName;

    // Nom bo'lmasa (masalan yo'nalish kuzatuvchisidan kelgan qidiruv)
    // eski umumiy sarlavha qoladi — bo'sh joy ko'rsatishdan yaxshiroq.
    if (from == null || to == null) return ScreenTitle(t.resultsTitle);

    /*
     * ⚠️ SANAGA «…dan boshlab» QO'SHMANG — O'LCHANDI (10.09.2026).
     *
     * Ma'no bo'yicha to'g'ri bo'lardi: sana serverga `date_from` bo'lib
     * ketadi va yuqori chegara YO'Q, ya'ni tanlangan kundan boshlab
     * hammasi qaytadi (qaror 16.08.2026, `RideSearchParams.toQuery`).
     * Odam 12-sentabrni tanlab ro'yxatda 15-sentabrni ham ko'radi.
     *
     * Lekin bu qatorga sig'maydi. O'lchov (`search_date_label_test`):
     * 320 px ekranda sarlavha uyasiga 240 px beriladi; matn shkalasi
     * 1.3 bo'lganda «12 sentabr 2027dan boshlab · 5 ta safar topildi»
     * 336 px talab qiladi va 65% ga kichrayib ketadi — o'qib
     * bo'lmaydigan darajada.
     *
     * Saytda bu ma'no MAYDON YORLIG'IGA chiqarildi («Qachondan») —
     * u yerda joy bor. Ilovada esa maydonda yorliq yo'q. Agar kerak
     * bo'lsa — yangi joy toping, bu qatorni uzaytirmang.
     */
    final meta = [
      if (params?.date != null) formatDate(params!.date, t.lang),
      if (count != null) t.ridesFound(count!),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$from — $to',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (meta.isNotEmpty)
          /*
           * 🔴 KESISH EMAS, KICHRAYTIRISH (10.09.2026, o'lchandi).
           *
           * Ilgari bu qator `ellipsis` bilan turardi va 320 px ekranda
           * matn shkalasi 1.3 bo'lsa KESILARDI — sarlavha uyasiga 240 px
           * beriladi, qator esa 336 px talab qiladi. Ya'ni katta matn
           * tanlagan odam (aynan o'qishi qiyin bo'lgan odam) sana va
           * natija sonining yarmini YO'QOTARDI, hech qanday belgi ham
           * ko'rmasdan — `ellipsis` toshishni jimgina yutadi.
           *
           * Yuqoridagi ekran sarlavhasi (`ScreenTitle`) allaqachon shu
           * qoida bilan ishlaydi. Ma'lumotni yo'qotgandan ko'ra kichik
           * yozgan yaxshi. O'lchovi: `search_date_label_test`.
           */
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              meta,
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}
