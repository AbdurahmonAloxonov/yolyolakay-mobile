import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../core/app_update.dart';
import '../core/deep_links.dart';
import '../features/shared/brand/brand_splash.dart';
import '../features/shared/connection_banner.dart';
import '../features/shared/in_app_banner.dart';
import 'home_widget_sync.dart';
import 'lifecycle_refresh.dart';
import '../features/shared/whats_new.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class YolYolakayApp extends ConsumerWidget {
  const YolYolakayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // MyID callback deep link'ini kuzatish shu yerda boshlanadi (`DeepLinks`).
    ref.watch(deepLinksProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(themeStyleProvider);

    return MaterialApp.router(
      title: 'YolYolakay',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Banner MaterialApp USTIDA — qaysi ekran ochiq bo'lishidan qat'i nazar
      // ko'rinadi va navigatsiya bilan yo'qolmaydi.
      // LifecycleRefresh — ilova fondan qaytganda ro'yxatlarni yangilaydi
      // (hech narsa chizmaydi, faqat kuzatadi).
      builder: (context, child) {
        // 🔴 SHRIFT KATTALIGINI CHEKLAYMIZ (egasi qurilmada, 2026-08-20:
        // "telefon shriftlari kattalashtirilgan bo'lsa ekran tuzilishi
        // o'zgarib qolyapti").
        //
        // Tizimda "eng katta shrift" tanlangan telefonda `textScaler` 1.3–2.0
        // gacha yetadi. Bunda ikonka+yozuvli qatorlar, narx, tugmalar ekranga
        // sig'may "RenderFlex overflowed" beradi (biz allaqachon bir necha
        // joyda `Flexible`/`ellipsis` bilan yamаganmiz, lekin har qatorni
        // alohida yamash mumkin emas).
        //
        // Butunlay o'chirmaymiz — bu ko'zi xira odam uchun kerak. 1.3 gacha
        // RUXSAT beramiz (matn sezilarli kattaroq), undan narisiga qotiramiz:
        // shu chegara ichida layout butun qoladi.
        //
        // «Katta matn» yoqilgan bo'lsa chegara 1.6 ga ko'tariladi
        // (izohi `BigTextController` da): tizim sozlamasini topa
        // olmaydigan odam ilovaning O'ZIDAN kattalashtira olsin.
        final mq = MediaQuery.of(context);
        final bigText = ref.watch(bigTextProvider);
        final scaled = mq.copyWith(
          textScaler: mq.textScaler.clamp(
            // Yoqilganda PASTKI chegara ham ko'tariladi: odam tugmani
            // bosdi va natijani DARHOL ko'rishi kerak — tizimda shrift
            // standart bo'lsa ham.
            minScaleFactor: bigText ? BigTextController.maxScale : 1.0,
            maxScaleFactor: bigText ? BigTextController.maxScale : 1.3,
          ),
        );
        return MediaQuery(
          data: scaled,
          child: LifecycleRefresh(
            // Bosh ekran vidjeti — hech narsa chizmaydi, faqat
            // ro'yxatlarni kuzatib telefon ekraniga uzatadi.
            child: HomeWidgetSync(
              child: ConnectionBanner(
                child: InAppBanner(
                  child: _StartupGate(child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          ),
        );
      },
      locale: locale,
      // `uz` Flutter'ning material tarjimalarida yo'q — sana tanlash kabi
      // tizim matnlari uchun `ru` ga tushamiz, ilova matnlari AppStrings'dan.
      supportedLocales: const [
        Locale('uz'),
        Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
        Locale('ru'),
        Locale('en'),
      ],
      localeResolutionCallback: (locale, supported) =>
          switch (locale?.languageCode) {
            'ru' => const Locale('ru'),
            'en' => const Locale('en'),
            _ => const Locale('uz'),
          },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(brightness: Brightness.light, style: themeStyle),
      darkTheme: buildTheme(brightness: Brightness.dark, style: themeStyle),
      themeMode: themeMode,
    );
  }
}

/// Ilova ochilishida BREND ekranini ushlab turadi.
///
/// Tizim splash'i Flutter tayyor bo'lishi bilan yo'qoladi, lekin o'sha
/// paytda profil hali yuklanmagan bo'ladi. Bu darcha o'sha oraliqni
/// to'ldiradi — aks holda ilova yarim bo'sh ekran bilan ochilardi.
///
/// ⚠️ IKKI QO'RIQCHI bor, chunki yuklanish ekrani ILOVANI QULFLAB QO'YISHI
/// mumkin — bu bo'sh ekrandan ham yomon:
///   1. Profil kelishi bilan (yoki XATO bilan tugashi bilan) darhol ochiladi;
///   2. Baribir kelmasa — [_maxWait] dan keyin majburan ochiladi. Server
///      javob bermayotgan bo'lsa odam hech bo'lmasa ekranni ko'radi va
///      xatosini o'sha yerda o'qiydi.
///
/// Kirmagan foydalanuvchida umuman ko'rsatilmaydi: login ekrani hech narsa
/// kutmaydi va darhol chizilishi kerak.
class _StartupGate extends ConsumerStatefulWidget {
  const _StartupGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<_StartupGate> {
  static const _maxWait = Duration(seconds: 3);

  bool _elapsed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_maxWait, () {
      if (mounted) setState(() => _elapsed = true);
    });
    // Play'da yangi versiya bor-yo'qligini tekshiramiz (izoh `AppUpdate` da).
    // `addPostFrameCallback`: birinchi kadr chizilgach, splashni ushlamasin.
    // Natijani KUTMAYMIZ — Play o'z modalini o'zi ko'rsatadi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdate.checkOnStartup();
      // «Nima yangilandi» — yangilanishdan keyin BIR MARTA. Play modalidan
      // KEYIN chaqiriladi va u ochilgan bo'lsa navbatda turadi (ikkalasi
      // bir vaqtda chiqmaydi: modal ustidagi varaq ko'rinmasdi).
      if (!mounted) return;
      /*
       * 🔴 VARAQ HECH QACHON CHIQMAGAN (28.09.2026, qurilma logida:
       * «Null check operator used on a null value» — `Navigator.of`).
       * Bu darvoza Navigator'dan TASHQARIDA (router `builder` ining
       * o'rovchisi), ya'ni uning `context` ida varaq ochib bo'lmaydi va
       * har ishga tushishda ushlanmagan xato otilardi. Varaq router'ning
       * O'Z navigatori kontekstida ochiladi.
       */
      final navContext = ref
          .read(routerProvider)
          .routerDelegate
          .navigatorKey
          .currentContext;
      if (navContext == null) return;
      if (ref.read(whatsNewProvider).shouldShow()) {
        showWhatsNew(navContext, ref);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_elapsed) return widget.child;

    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) return widget.child;

    // `isLoading` — birinchi so'rov. Xato bo'lsa ham o'tkazamiz: ekranlar
    // o'z xato holatini ko'rsatadi, splash esa uni yashirardi.
    final me = ref.watch(meProvider);
    if (!me.isLoading) return widget.child;

    return const BrandSplash();
  }
}
