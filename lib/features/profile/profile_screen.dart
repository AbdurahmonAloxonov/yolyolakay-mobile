import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/active_role.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../data/models/user.dart';
import '../../l10n/strings.dart';
import '../shared/yol_refresh.dart';
import '../shared/photo_source_sheet.dart';

import '../../core/media_url.dart';
import '../shared/image_viewer.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../shared/notification_bell.dart';
import '../shared/settings_button.dart';
import '../shared/brand/ornament.dart';
import '../../app/theme.dart';
import '../../core/local_cache.dart';
import '../shared/cached_note.dart';
import '../shared/trust_ladder.dart';
import 'my_roads_map.dart';
import 'my_stuff_section.dart';
import 'profile_completeness.dart';
import '../../app/dimens.dart';
import '../shared/brand/loom_loader.dart';
import '../shared/brand/suzani_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final me = ref.watch(meProvider);

    // Ma'lumot kelganda AppBar YO'Q: u `_ProfileBody` ichida SliverAppBar
    // bo'lib, hero blok bilan birga siljiydi (profil ma'lumoti navbarga
    // "kirib ketadi"). Yuklanish/xato holatlarida oddiy AppBar qoladi —
    // aks holda bildirishnoma qo'ng'irog'i yo'qolardi.
    /*
     * 🔴 TORTIB-YANGILASH YUKLANISH VA XATODA HAM (egasi, 2026-09-04:
     * «profilda refresh yo'q»). Va u HAQ edi: `YolRefresh` faqat
     * `data:` shoxida — ya'ni ma'lumot KELGANDA — chizilardi.
     * Ma'lumot kelmagan paytda esa tortadigan narsaning O'ZI yo'q
     * edi: yuklanish `Center(LoomLoader())`, xato `ErrorView` —
     * ikkalasi ham SURILMAYDI, `RefreshIndicator` esa tortishni
     * faqat suriladigan qismdan eshitadi.
     *
     * Odam aynan o'shanda tortadi — bu uning birinchi refleksi.
     * Saytda bu 30-avgustda tuzatilgan edi (`YolRefreshable`),
     * ilovada esa profil, safarlarim, mashinalar, daromad, tariflar
     * va yana beshta ekran eski holida qolgan ekan.
     */
    Future<void> refreshAll() async {
      await Future.wait([
        ref.refresh(meProvider.future),
        ref.refresh(billingPlansProvider.future),
      ]);
    }

    Scaffold shell(Widget body) => Scaffold(
      appBar: AppBar(
        title: Text(t.profileTitle),
        actions: const [NotificationBell(), SettingsButton()],
      ),
      // Mazmun SURILADIGAN bo'lishi shart — izohi `YolRefreshable` da.
      body: YolRefresh(
        onRefresh: refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [body],
        ),
      ),
    );

    return me.when(
      loading: () => shell(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.huge),
          child: Center(child: LoomLoader()),
        ),
      ),
      error: (error, _) => shell(ErrorView(error: error, onRetry: refreshAll)),
      data: (data) => Scaffold(body: _ProfileBody(data: data)),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.data});

  final MeResponse data;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _uploadingAvatar = false;

  /// Avatar tanlash — GALEREYA.
  ///
  /// Kamera ATAYIN emas: kamera ruxsati Play'da alohida asoslash talab qiladi,
  /// galereya esa Android 13+ da tizim "Photo Picker" orqali RUXSATSIZ ishlaydi
  /// (`become_driver_screen` da ham shu qaror).
  ///
  /// Ikki qadam: `media/upload` URL qaytaradi, keyin o'sha URL profilga
  /// `PUT /users/profile` bilan yoziladi — backendda avatar uchun alohida
  /// endpoint YO'Q.
  Future<void> _pickAvatar() async {
    final t = AppStrings.of(context);
    final user = widget.data.user;

    // Backend ism/familiyani MAJBURIY talab qiladi — ularsiz PUT 400 beradi va
    // avatar "sababsiz" yiqilgandek ko'rinardi. Sababini oldindan aytamiz.
    if (!user.hasName) {
      showMessage(context, t.nameRequiredForAvatar);
      return;
    }

    // Avatar uchun ham tanlov: selfi olish galereyada rasm izlashdan
    // tezroq (izohi `pickPhotoSource` da).
    final picked = await pickPhotoSource(context, maxWidth: 800);
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await ref
          .read(mediaRepositoryProvider)
          .upload(picked.path, fileName: picked.name);
      if (url == null) {
        if (mounted) showMessage(context, t.photoFailed);
        return;
      }
      await ref
          .read(usersRepositoryProvider)
          .updateProfile(
            firstName: user.firstName ?? '',
            lastName: user.lastName ?? '',
            gender: user.gender,
            avatarUrl: url,
          );
      ref.invalidate(meProvider);
      if (mounted) showMessage(context, t.avatarUpdated);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final data = widget.data;
    final user = data.user;
    // Profil ham rolga bo'ysunadi: haydovchining narsalari (mashina, tarif
    // paketi, daromad) yo'lovchi rejimida ko'rsatilmaydi.

    // Hero to'liq kenglikda (chetdan chetgacha) bo'lishi uchun ListView'ning
    // O'ZIDA yon padding YO'Q — qolgan bo'limlar o'zi padding oladi.
    // Hero endi SliverAppBar ichida: pastga siljitilganda kichrayadi va ism
    // navbarda qolib ketadi. Ilgari AppBar'da "Profil" so'zi turardi va uning
    // ostida yana hero — bir xil joyni ikki marta egallardi.
    // Hero balandligi. Ilgari qat'iy 268 edi va mazmun (avatar + ism + telefon
    // + uchta raqam + "Tahrirlash") unga SIG'MASDI — tugmaning ostki chizig'i
    // qirqilib turardi (shrift masshtabi 1.0 da ham, ya'ni hamma qurilmada).
    // Tizim shrifti kattalashtirilganda ichidagi yozuvlar yanada o'sadi,
    // shuning uchun balandlik o'sha masshtabga bog'landi; juda cho'zilib
    // ketmasligi uchun yuqoridan cheklangan.
    final textScale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
      1.0,
      1.5,
    );
    // 🔴 296 edi va ba'zi o'lchamlarda ichidagi ustun 24px ga toshib
    // ketardi (sinovda topildi 2026-08-14): avatar + ism + telefon +
    // statistika + tugma yig'ilib, ajratilgan balandlikdan oshib ketadi.
    // Zaxira bilan 320 qilindi.
    // `kToolbarHeight` qo'shildi (2026-08-28): hero mazmuni endi tepadagi
    // panel (qo'ng'iroq tugmasi turgan qator) OSTIDAN boshlanadi. Usiz
    // avatar panel ostiga kirib qolar va bosish ham unga TUSHMASDI —
    // `profile_avatar_test` da tap "missed" bo'lib chiqdi.
    final heroHeight = 320 * textScale + kToolbarHeight;

    // TORTIB-YANGILASH — balans, tarif va tekshiruv holati serverdan
    // keladi va ular O'ZGARADI. Odam «yangilandimi?» degan savolga
    // javob olish uchun ekrandan chiqib qaytishga majbur edi.
    return YolRefresh(
      // ⚠️ `invalidate` EMAS, `refresh(...future)` — izohi
      // `user_profile_screen` da va `refresh_awaits_test` da.
      onRefresh: () async {
        await Future.wait([
          ref.refresh(meProvider.future),
          ref.refresh(billingPlansProvider.future),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: heroHeight,
            backgroundColor: BrandColors.wineAsh,
            foregroundColor: _ProfileHero.onDark,
            actions: [
              const NotificationBell(),
              // ⚙️ SOZLAMALAR — profildan ajratilgan bo'lim (2026-09-02).
              //
              // 🔴 Egasi: «profilga hamma narsa tiqilib ketgan». Mashina,
              // tarif, daromad, til, tema, parol, xavfsizlik, taklif,
              // xizmat holati, chiqish, hisobni o'chirish — hammasi
              // shu ekranda edi va odam o'z ismini ko'rish uchun
              // ro'yxatni varaqlashi kerak edi.
              // Endi umumiy vidjet — u hamma tabda bir xil (izohi
              // `SettingsButton` da).
              const SettingsButton(),
            ],
            // ⚠ `FlexibleSpaceBar.title` ni Flutter FAQAT yig'ilganda emas, YOYILGAN
            // holatda ham chizadi (kattalashtirib, pastki chetga qo'yib). Hero
            // ichida ham ism borligi uchun u ikki marta ko'rinardi va ikkinchisi
            // "Tahrirlash" tugmasi ustiga tushib qolardi. Shuning uchun sarlavhani
            // yig'ilish darajasiga bog'laymiz.
            flexibleSpace: Builder(
              builder: (context) {
                final settings = context
                    .dependOnInheritedWidgetOfExactType<
                      FlexibleSpaceBarSettings
                    >();
                final range = settings == null
                    ? 0.0
                    : settings.maxExtent - settings.minExtent;
                // 1 — to'liq yoyilgan, 0 — navbargacha yig'ilgan.
                final expanded = settings == null || range <= 0
                    ? 1.0
                    : ((settings.currentExtent - settings.minExtent) / range)
                          .clamp(0.0, 1.0);
                // Ism oxirgi 30% da paydo bo'ladi — bunda hero'dagi ism allaqachon
                // ekrandan chiqib ketgan bo'ladi, ya'ni ikkitasi bir vaqtda
                // ko'rinmaydi.
                final titleOpacity = ((0.3 - expanded) / 0.3).clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  // Yig'ilganda ism ko'rinadi; yozuv qo'ng'iroq tugmasi ostiga
                  // kirib ketmasligi uchun ikki tomondan joy qoldiramiz.
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 56,
                    bottom: 14,
                    end: 56,
                  ),
                  // Kattalashtirish o'chirilgan: aks holda paydo bo'lish paytida
                  // yozuv o'lchami sakrab ko'rinadi.
                  expandedTitleScale: 1,
                  title: Opacity(
                    opacity: titleOpacity,
                    child: Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfileHero.onDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  background: _ProfileHero(
                    user: user,
                    uploading: _uploadingAvatar,
                    onAvatarTap: _pickAvatar,
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔴 UZILISHDA PROFIL ENDI KO'RINADI (2026-08-25): ilgari
                  // bu ekran aloqasiz joyda BUTUNLAY singan holatga tushardi —
                  // ism ham, mashina ham, tasdiq holati ham yo'q edi. Endi
                  // oxirgi ma'lum profil ko'rsatiladi va U QACHONLIGI AYTILADI:
                  // eski ma'lumotni yangi deb o'ylab qaror qabul qilmasin.
                  const CachedNote(cacheKey: CacheKeys.me),

                  /*
                   * 🔴 TARTIB (28.09.2026, egasi: «profil betartib turibdi»).
                   *
                   * Bo'limlar tasodifiy qo'shilgan tartibda turgandi:
                   * allaqachon 4/4 bo'lgan «Ishonch» eng tepada, uning
                   * OSTIDA esa bajarilishi KERAK bo'lgan ish («surat
                   * qo'shing»). Sarlavhalar ham ikki xil edi — ba'zisi
                   * karta ichida, ba'zisi karta ustida.
                   *
                   * Endi uch qavat, har biri bitta savolga javob:
                   *   1. NIMA QILISHIM KERAK — to'liqlik, tekshiruv holati
                   *      (bajarilgach o'zi yo'qoladi);
                   *   2. NIMANI BOSHQARAMAN — rejim, mening narsalarim;
                   *   3. MENI QANDAY KO'RISHADI — ishonch, yo'llarim
                   *      (natija: o'qiladi, bosilmaydi).
                   * Har bo'lim sarlavhasi KARTA USTIDA (`SectionLabel`).
                   */

                  // PROFIL TO'LIQLIGI — eng tepada, chunki u ODAMNING
                  // BRON OLISHIGA ta'sir qiladi (izohi
                  // `ProfileCompleteness` da). To'liq bo'lsa chizilmaydi.
                  const SizedBox(height: AppSpace.md),
                  ProfileCompleteness(
                    user: user,
                    hasCar: data.cars.isNotEmpty,
                    onAvatar: _pickAvatar,
                    onName: () => context.push(Routes.editProfile),
                    onCar: () => context.push(Routes.cars),
                  ),

                  // TEKSHIRUV HOLATI — hujjat yuborgan har kimga. Odam
                  // hujjat yuborgach «nima bo'ldi?» degan javobni birinchi
                  // shu yerdan izlaydi.
                  if (user.hasKycState) ...[
                    const SizedBox(height: AppSpace.lg),
                    _KycStatusCard(user: user),
                  ],

                  // 🔴 REJIM ALMASHTIRISH — YAGONA joy (egasi tanladi,
                  // 2026-08-13: "inDrive/Yandex uslubi"). Faqat haydovchida.
                  if (user.isDriver) ...[
                    const SizedBox(height: AppSpace.lg),
                    SectionLabel(t.roleSwitchTitle),
                    const SizedBox(height: AppSpace.sm),
                    const _RoleSwitch(),
                  ],

                  /*
                   * «MENING NARSALARIM» — 18.09.2026 da SOZLAMALARDAN
                   * ko'chirildi. Rejimdan KEYIN: qatorlar rejimga qarab
                   * o'zgaradi. Izohi `my_stuff_section.dart` da.
                   */
                  const SizedBox(height: AppSpace.lg),
                  MyStuffSection(cars: data.cars),

                  // Haydovchi bo'lmaganlarga — asosiy taklif, ro'yxatga qo'shilmaydi.
                  if (!user.isDriver) ...[
                    const SizedBox(height: AppSpace.lg),
                    FilledButton.icon(
                      onPressed: () => context.push(Routes.becomeDriver),
                      icon: const Icon(Icons.directions_car),
                      label: Text(t.becomeDriver),
                    ),
                  ],

                  // ISHONCH NARVONI — bitta ro'yxat va bitta raqam
                  // (izohi `core/trust.dart` da). Bu NATIJA, ish emas —
                  // shuning uchun pastda.
                  const SizedBox(height: AppSpace.xl),
                  TrustLadder(user: user, cars: data.cars),

                  /*
                   * «YO'LLARIM» — 16.09.2026 (egasi: «karta to'liq
                   * ishlatilsin»). Safar bo'lmasa `MyRoadsMap` o'zi
                   * chizilmaydi — sarlavha ham u bilan birga yo'qoladi.
                   */
                  MyRoadsMap(title: t.sectionMyRoads),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil "hero" sarlavhasi.
///
/// NEGA SHUNDAY: ilgari profil bir xil kartalar to'plami edi — ko'z hech
/// narsaga tayanmasdi ("hammasi yoyilib bir joyda turibdi", egasi bahosi).
/// Endi tepada to'q wine-ash blok: ikat naqshi, katta avatar, Fraunces
/// shriftidagi ism va uchta raqam. Qolgan ro'yxat ATAYIN tinch qoladi.
///
/// ⚠️ RANGLAR QAT'IY: blok HAR DOIM to'q (yorug' temada ham), shuning uchun
/// ichidagi matn ranglari `colorScheme` dan OLINMAYDI — ular ochiq rangda
/// qat'iy belgilangan. Aks holda yorug' temada oq fonda oq matn chiqardi.
///
/// ⚠️ RAQAMLAR HAQIQIY: "safarlar soni" backend modelida YO'Q, shuning uchun
/// o'ylab topilmadi. Ko'rsatiladigani — reyting, sharhlar soni va tarifdan
/// qolgan safar. Ma'lumot bo'lmasa "—" chiziladi.
class _ProfileHero extends ConsumerWidget {
  const _ProfileHero({
    required this.user,
    required this.uploading,
    required this.onAvatarTap,
  });

  final User user;
  final bool uploading;
  final VoidCallback onAvatarTap;

  /// Sliver sarlavhasi ham shu rangdan foydalanadi — shuning uchun ochiq.
  static const onDark = Color(0xFFF2EEF1);
  static const onDarkMuted = Color(0xFFB9AEB5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final subscription = ref.watch(subscriptionProvider).valueOrNull;
    final plans = ref.watch(billingPlansProvider).valueOrNull ?? const [];
    // Nisbiy manzil ham hisobga olinsin — izohi `core/media_url.dart` da.
    final hasPhoto = mediaUrl(user.avatarUrl) != null;

    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.wineAsh,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.sheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          /*
           * GIRIH — profil sarlavhasining zamini.
           *
           * 🔴 Ilgari bu yerda ROMB teksturasi (`IkatTexture`) turardi —
           * aynan egasi saytda «romb har madaniyatda bor, girih esa
           * bizning me'morchiligimizniki» deb OLIB TASHLATGAN motiv.
           * Ilovada u tirik qolgan va profil ilovaning eng «milliy»
           * ekrani bo'lib turgandi, holbuki naqshi begona edi.
           *
           * ⚠️ Kesim rangi zamin bilan bir xil (`wineAsh`): tema emas,
           * shu blokning O'Z rangi — sarlavha to'rt temada ham to'q
           * qoladi.
           */
          Positioned.fill(
            child: GirihPattern(
              cell: 92,
              color: BrandColors.turquoise.withValues(alpha: 0.10),
              cut: BrandColors.wineAsh,
            ),
          ),
          // 🔴 `top: true` (egasi, 2026-08-28): ilgari `false` edi va avatar
          // ekranning eng tepasidan 24px da turardi — o'yiqli (notch) yoki
          // teshikli kamerali telefonlarda surat aynan kamera ostiga tushib
          // qolardi.
          //
          // 🔑 Balandlik BUZILMAYDI: `SliverAppBar` da
          // `maxExtent = topPadding + expandedHeight` (Flutter manbasida
          // tekshirildi), ya'ni tepa chekinishi mazmun uchun ajratilgan
          // balandlikdan TASHQARIDA. Fon esa `Container` da qolgani uchun
          // avvalgidek chetdan chetgacha, status paneli ostiga kiradi.
          //
          // Tepadagi `kToolbarHeight` — qo'ng'iroq tugmasi turgan qator.
          // U hero ustiga chiziladi va bosishni O'ZIGA OLADI, shuning
          // uchun avatar undan pastda boshlanishi shart (`heroHeight` ham
          // shu qiymatga oshirilgan).
          SafeArea(
            top: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                kToolbarHeight + 8,
                24,
                20,
              ),
              child: Column(
                children: [
                  // 🔴 IKKI XIL AMAL, IKKI XIL NISHON (egasi, 2026-08-28):
                  // ilgari BUTUN blok suratni o'zgartirishga bog'langan edi —
                  // odam o'z suratini kattalashtirib ko'rmoqchi bo'lsa,
                  // o'rniga "yangi rasm qo'yish" oynasi ochilardi.
                  //
                  // Endi: suratning O'ZI — ko'rish (begona profilda ham
                  // shunday, `PersonAvatar(tapToView)`), kamera nishoni —
                  // o'zgartirish. Surat YO'Q bo'lsa ko'rsatadigan narsa ham
                  // yo'q, shuning uchun bosish to'g'ridan-to'g'ri tanlashga
                  // olib boradi (aks holda bosish javobsiz qolardi).
                  Stack(
                    children: [
                      Semantics(
                        button: true,
                        label: hasPhoto ? t.viewPhoto : t.changePhoto,
                        child: GestureDetector(
                          onTap: uploading
                              ? null
                              : (hasPhoto
                                    ? () => showImageViewer(
                                        context,
                                        user.avatarUrl,
                                      )
                                    : onAvatarTap),
                          child: _Avatar(user: user, radius: 44),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Semantics(
                          button: true,
                          label: t.changePhoto,
                          child: GestureDetector(
                            // Ko'rinadigan nishon 30px (14 ikonka + 8+8
                            // chekinish) — barmoq uchun kichik, shuning
                            // uchun shaffof maydon ichiga olindi.
                            //
                            // 🔴 40px, 44 EMAS: avatar 88px va nishon uning
                            // o'ng-pastki burchagida turadi. 44px'lik maydon
                            // suratning AYNAN MARKAZIGACHA yetib borardi —
                            // odam suratning o'rtasiga bosса ham "rasm
                            // qo'yish" ochilardi (test shuni tutdi).
                            // 40px da maydon 48px dan boshlanadi, ya'ni
                            // markaz suratning o'ziga qoladi.
                            behavior: HitTestBehavior.opaque,
                            onTap: uploading ? null : onAvatarTap,
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpace.sm),
                                decoration: const BoxDecoration(
                                  color: BrandColors.pink,
                                  shape: BoxShape.circle,
                                ),
                                child: uploading
                                    ? const SizedBox(
                                        height: 12,
                                        width: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.photo_camera,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          // Fraunces — brend sarlavha shrifti. Kirill nomlar
                          // uchun theme'dagi fallback ishlaydi.
                          style: displayFontStyle(
                            theme.textTheme.titleLarge,
                          ).copyWith(color: onDark),
                        ),
                      ),
                    ],
                  ),
                  if (user.hasName) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      user.phoneNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onDarkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  /*
                   * 🔴 AJRATGICHLAR YARIM BALANDLIKDA EDI (2026-09-03).
                   *
                   * Ular QAT'IY 28 piksel bo'lib, ustunlar esa ~40:
                   * qatorning markazida turgani uchun har ajratgich
                   * raqamning yarmidan yorliqning yarmigacha cho'zilib,
                   * hech qayerda tugamasdi — uchta ustun ajratilgandek
                   * emas, chizilib qo'yilgandek ko'rinardi.
                   *
                   * `IntrinsicHeight` + `stretch`: endi ajratgich
                   * ustunlarning BUTUN balandligini oladi va matn
                   * shkalasi o'zgarsa ham shunday qoladi.
                   */
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroStat(
                          value: user.showRating
                              ? user.rating!.toStringAsFixed(1)
                              : '—',
                          label: t.statRating,
                        ),
                        const _HeroStatDivider(),
                        _HeroStat(
                          value: user.ratingCount?.toString() ?? '—',
                          label: t.statReviews,
                        ),
                        // "Safar qoldi" — TARIF paketidan qolgani, ya'ni
                        // haydovchining raqami. Yo'lovchi rejimida u
                        // ko'rsatilmaydi (rol = mazmun qoidasi).
                        if (ref.watch(isDriverModeProvider) &&
                            user.isDriver) ...[
                          const _HeroStatDivider(),
                          _HeroStat(
                            value: subscription == null
                                ? '—'
                                : subscription.ridesLeftLabel(
                                    plans,
                                    t.unlimited,
                                  ),
                            label: t.statRidesLeft,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  OutlinedButton(
                    onPressed: () => context.push(Routes.editProfile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onDark,
                      side: BorderSide(color: onDark.withValues(alpha: 0.35)),
                      minimumSize: const Size(160, AppSize.buttonHeightCompact),
                    ),
                    child: Text(t.edit),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _ProfileHero.onDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        // 🔴 BITTA QATOR: haydovchi rejimida uchta ustun bo'ladi va tor
        // ekranda "safar qoldi" ikkiga bo'linib, butun sarlavha blokini
        // toshirib yuborardi (sinovda topildi 2026-08-14).
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _ProfileHero.onDarkMuted),
        ),
      ],
    ),
  );
}

class _HeroStatDivider extends StatelessWidget {
  const _HeroStatDivider();

  @override
  // Balandlik BERILMAYDI: qator `IntrinsicHeight` + `stretch` bilan
  // quriladi, ya'ni ajratgich ustunlar bilan bir xil bo'yda bo'ladi.
  Widget build(BuildContext context) => Container(
    width: 1,
    color: _ProfileHero.onDarkMuted.withValues(alpha: 0.25),
  );
}

/// Guruh sarlavhasi — profil "ombor"ga aylanib qolmasligi uchun.
///
/// Ilgari sarlavhalar deyarli yo'q edi (faqat "Mening mashinalarim") va 12 ta
/// band bir xil kartalarda ketma-ket turardi: odam kerakligini topolmasdi.

/// Profil avatari — rasm YUKLANMASA ham bo'sh qolmaydi.
///
/// 🔴 Nima buzilgan edi (qurilmada, 2026-08-13): rasm yuklangach ilova
/// "Rasm yangilandi" deb xabar berdi, lekin doira BUTUNLAY bo'sh bo'lib
/// qoldi — hatto ismning bosh harfi ham yo'qoldi. Sabab: `hasAvatar` rost
/// bo'lgani uchun zaxira belgi umuman chizilmasdi, `CircleAvatar` esa
/// yuklanmagan rasm haqida hech narsa demaydi. Natijada odam "rasm
/// qo'yilmadi" deb o'ylaydi, aslida saqlangan manzil ochilmayapti.
///
/// Endi manzil ochilmasa BOSH HARF qaytadi — ekran hech qachon bo'sh
/// doira ko'rsatmaydi.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.radius});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final background = BrandColors.pink.withValues(alpha: 0.25);

    // Rasmsiz — bosh harf o'rniga shaxsiy suzani muhri (id'dan).
    Widget fallback() => ClipOval(
      child: SuzaniAvatar(seed: user.id, size: radius * 2),
    );

    // Nisbiy manzilni to'liqlashtiramiz — izohi `core/media_url.dart` da.
    final url = mediaUrl(user.avatarUrl);
    if (url == null) {
      return SizedBox(width: radius * 2, height: radius * 2, child: fallback());
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Yuklanayotganda ham bo'sh qolmasin.
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : fallback(),
          errorBuilder: (_, _, _) => fallback(),
        ),
      ),
    );
  }
}

/// Yo'lovchi / Haydovchi almashtirgichi.
///
/// `SegmentedButton` ATAYIN: ikki holatli tanlov uchun eng tushunarli
/// ko'rinish — qaysi rol faolligi bir qarashda ko'rinadi. Almashtirilgach
/// pastki menyu va "Safarlarim"/"Pochta" yorliqlari darhol o'zgaradi.
class _RoleSwitch extends ConsumerWidget {
  const _RoleSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final driverMode = ref.watch(isDriverModeProvider);

    // 🔴 `ListTile` + `trailing: tugma` ISHLAMADI: sarlavha bilan tugma
    // enni bo'lishib olardi va matn HARFMA-HARF pastga tushib ketardi
    // (qurilmada ko'rildi 2026-08-13). Shuning uchun ustun: yozuv tepada,
    // tugma butun enda pastda.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  driverMode ? Icons.directions_car : Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    driverMode ? t.roleDriver : t.rolePassenger,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              driverMode ? t.switchToPassengerHint : t.switchToDriverHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FilledButton.tonalIcon(
              onPressed: () {
                final next = driverMode ? AppRole.passenger : AppRole.driver;
                ref.read(activeRoleProvider.notifier).set(next);
                // Yangi "dunyo" O'Z bosh ekranidan ochiladi: haydovchida
                // e'lonlarim, yo'lovchida qidiruv. Aks holda odam eski
                // ekranda qolib, nima o'zgarganini tushunmaydi.
                context.go(
                  next == AppRole.driver ? Routes.trips : Routes.search,
                );
              },
              icon: Icon(
                driverMode ? Icons.person_outline : Icons.directions_car,
              ),
              label: Text(driverMode ? t.switchToPassenger : t.switchToDriver),
            ),
          ],
        ),
      ),
    );
  }
}

/// ISHONCH BELGILARI — telefon va mashina tasdiqlari bir qatorda.
///
/// 🔴 Egasi (2026-08-20): bir qarashда "bu odam qanchalik tasdiqlanган".
/// Telefon DOIM tasdiqlanган (ro'yxatdan o'tish OTP bilan).
/// Mashina — moderatsiyadan o'tган (`approved`) mashina
/// bo'lса. Tasdiqlanмаган belgи ham ko'rsatilади (kuchsiz, kulrang) — nima
/// qolганини bildiradi, lekin "yolg'on yashил" bermaydi.

/// Shaxsni tasdiqlash holati — kutilmoqda / tasdiqlandi / rad etildi.
///
/// 🔴 NEGA KERAK: `kyc_status` backendda anchadan beri bor edi, lekin
/// hech qayerda ko'rsatilmasdi. Odam sakkizta hujjat suratini yuborardi
/// va keyin jimlik — "yubordimmi o'zi, kutayapmanmi yoki rad etilganmi"
/// degan savolga ilovada javob YO'Q edi.
///
/// 🔑 Holatlar RUXSAT ro'yxati bilan tekshirilmaydi (loyiha qoidasi):
/// backend yangi nom qo'shsa oq ro'yxat uni jimgina yashirardi. Shuning
/// uchun noma'lum holat "tekshirilmoqda" deb ko'rsatiladi — yashirilmaydi.
class _KycStatusCard extends StatelessWidget {
  const _KycStatusCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final approved = user.isKycApproved;
    final rejected = user.isKycRejected;

    // Modarator sababi bo'lsa umumiy maslahat («odatda xira surat»)
    // O'RNIGA kirish jumlasi turadi — taxmin bilan aniq sababni yonma-yon
    // qo'ysak, odam qaysi biriga ishonishni bilmaydi.
    final reason = user.kycReasonText;
    final (Color tone, IconData icon, String title, String hint) = rejected
        ? (
            scheme.error,
            Icons.error_outline,
            t.kycRejected,
            reason == null ? t.kycRejectedHint : t.kycRejectedFix,
          )
        : approved
        ? (
            scheme.primary,
            Icons.verified_outlined,
            t.kycApproved,
            t.kycApprovedHint,
          )
        : (
            scheme.tertiary,
            Icons.hourglass_top,
            t.kycPending,
            t.kycPendingHint,
          );

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 20),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(hint, style: theme.textTheme.bodySmall),
          // Modaratorning O'Z matni — bizning maslahatimizdan AJRATILGAN.
          // Uzunligi bizga bog'liq emas, shuning uchun o'ralishi erkin.
          if (rejected && reason != null) ...[
            const SizedBox(height: AppSpace.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: tone.withValues(alpha: 0.35)),
              ),
              child: Text(
                reason,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          // Rad etilganda — CHIQISH YO'LI. Sababsiz "rad etildi" degan
          // yozuv odamni boshi berk ko'chaga olib kiradi.
          if (rejected) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(Routes.becomeDriver),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(t.kycRetry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

