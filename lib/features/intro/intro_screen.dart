import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/haptics.dart';
import '../shared/screen_title.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../shared/brand/brand_panels.dart';
import '../shared/brand/ornament.dart';
import '../../core/motion.dart';

/// BIRINCHI OCHILISH TANISHTIRUVI (yangi foydalanuvchi uchun).
///
/// 🔴 NEGA KERAK (egasi, 2026-08-20): ilova birinchi ochilganda odam to'g'ridan
/// login ekraniga tushardi va nima qila olishini bilmasdi — safar qidirish,
/// haydovchi bo'lish, xavfsizlik. Uch ekranli qisqa tanishtiruv yo'nalish
/// beradi.
///
/// FAQAT BIR MARTA: ko'rilgach `intro_seen` bayrog'i saqlanadi
/// (`SharedPreferences`), router uni tekshiradi. "O'tkazib yuborish" ham
/// ko'rilgan deb hisoblanadi — odam qayta-qayta bir narsani ko'rmasin.
///
/// Bu `Routes.onboarding` (profil to'ldirish) dan BOSHQA: u nomi band, shu
/// sabab bu ekran `intro` deb ataladi.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  /// Router `intro_seen` ni O'QIY olishi uchun kalit shu yerda yagona manba.
  static const seenKey = 'intro_seen';

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(sharedPrefsProvider).setBool(IntroScreen.seenKey, true);
    if (mounted) context.go(Routes.login);
  }

  void _next(int total) {
    if (_page >= total - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    final pages = <_IntroPage>[
      _IntroPage(
        icon: Icons.search_rounded,
        title: t.introFindTitle,
        body: t.introFindBody,
        palette: 0,
      ),
      _IntroPage(
        icon: Icons.directions_car_filled,
        title: t.introDriveTitle,
        body: t.introDriveBody,
        palette: 1,
      ),
      _IntroPage(
        icon: Icons.verified_user_outlined,
        title: t.introSafeTitle,
        body: t.introSafeBody,
        palette: 2,
      ),
      // 🔴 Yangi funksiyalarni odam TASODIFAN topardi yoki umuman
      // topmasdi: ovozli qidiruv, xarita, yo'nalish kuzatuvchisi —
      // hech biri ko'zga tashlanmaydi. Intro ularni bir marta aytadi.
      _IntroPage(
        icon: Icons.mic_none,
        title: t.introVoiceTitle,
        body: t.introVoiceBody,
        palette: 1,
      ),
    ];
    final isLast = _page >= pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              // 🔴 `Spacer` OLIB TASHLANDI (2026-08-30 auditi): u
              // «O'tkazib yuborish» tugmasini ekrandan chiqarib
              // yuborardi — 320 px da 120 piksel, 360 px da 80 piksel
              // toshish. Ya'ni ilovaning ENG BIRINCHI ekranida
              // o'tkazib yuborish tugmasi ko'rinmasdi.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /*
                 * TIL — ENG BIRINCHI ekranda (2026-08-25).
                 *
                 * 🔴 Standart til o'zbekcha, tanlov esa profil ichida
                 * KO'MILGAN. Ruszabon odam ilovani ochadi, o'zbekcha
                 * ekranni ko'radi va tilni qayerdan almashtirishni
                 * bilmaydi — ko'pchilik shu yerda ketadi.
                 *
                 * Bu yerda u eng ko'rinadigan joyda: birinchi ekranda,
                 * hech narsa qilishdan oldin.
                 */
                const Padding(
                  padding: EdgeInsets.only(left: AppSpace.sm),
                  child: _LanguagePicker(),
                ),
                // O'tkazib yuborish — kam urg'u bilan.
                // `Flexible`: uzun tarjimada tugma qisqarsin, qator
                // toshib ketmasin.
                Flexible(
                  child: TextButton(
                    onPressed: _finish,
                    // ⚠️ Ichki chekka kichraytirildi (o'lchandi 2026-09-04):
                    // standart 16+16 px tufayli yozuvga 96 px qolardi,
                    // kerak esa 110 — «O'tkazib yubor…» bo'lib kesilardi.
                    // Bosiladigan maydon 48 px balandligicha qoladi.
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                    ),
                    // ⚠️ Chekka kichraytirilgandan keyin ham 320 px
                    // o'zbekchada yozuvga 104 px qolardi, kerak esa 110.
                    // `ScreenTitle` matnni bir oz KICHRAYTIRADI — uch
                    // nuqta bilan kesishdan yaxshiroq, chunki bu
                    // tugmaning butun ma'nosi uning nomida.
                    child: ScreenTitle(t.introSkip),
                  ),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (context, i) => pages[i],
              ),
            ),

            // Sahifa nuqtalari.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                    width: i == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                0,
                AppSpace.xl,
                AppSpace.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppSize.buttonHeight,
                child: FilledButton(
                  onPressed: () => _next(pages.length),
                  child: Text(isLast ? t.introStart : t.continueButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Atlas termasi — har sahifada boshqacha. Bitta terma to'rt marta
  /// takrorlansa mato emas, shablon bo'lib ko'rinadi.
  final int palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    /*
     * 🔴 SURILADIGAN QILINDI (2026-08-30 auditi).
     *
     * Ilgari bu qattiq `Column` edi va 320×568 telefonda o'zbekcha
     * matn bilan pastdan 2 piksel toshardi — ya'ni matnning oxirgi
     * qatori kesilardi. Bu chegara holat emas: ilova KATTA MATN
     * rejimini (1.6 baravar) qo'llab-quvvatlaydi va o'shanda bu
     * ekran butunlay yorilib ketardi.
     *
     * `Center` + `SingleChildScrollView`: matn sig'sa markazda
     * turadi, sig'masa suriladi. Ikkala holat ham to'g'ri.
     */
    // `minHeight` — sig'adigan matn MARKAZDA qolsin. Busiz suriladigan
    // qism mazmunga qarab qisqaradi va ekran tepasiga yopishib qoladi.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xxl,
              vertical: AppSpace.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Suzani gul ASTA OCHILADI (scale+fade), ustida ma'no ikonkasi.
                // Reduce-motion'da darrov to'liq ko'rinadi (izoh `AppMotion`).
                _ArchIcon(icon: icon, seed: title, palette: palette),
                const SizedBox(height: AppSpace.xl),
                const SizedBox(width: 200, child: OrnamentMark()),
                const SizedBox(height: AppSpace.xl),
                // Slaydning sarlavhasi — ekran o'qigich uchun ham
                // sarlavha (izohi `SectionLabel` da).
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: displayFontStyle(
                      theme.textTheme.headlineSmall,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.outline,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tanishtiruv belgisi — PESHTOQ ravog'i ichidagi ikonka.
///
/// 🔴 NEGA ALMASHTIRILDI (2026-09-03): ilgari bu yerda `SuzaniAvatar`
/// turardi — sarlavha matnidan hosil qilinadigan GENERATIV gul. Ya'ni
/// ilovaning eng birinchi ekranida tasodifiy shakl chizilardi va
/// uning ustiga ikonka qo'yilgani uchun ikkalasi ham yarim ko'rinardi.
/// Bu «milliy» emas, shunchaki rangli dog' edi.
///
/// Endi ikonka MADRASA RAVOG'I ichida turadi: shakl har sahifada bir
/// xil (ya'ni tanib olinadi), ichidagi girih naqshi ravoqni to'ldiradi,
/// ostidagi atlas jiyagi esa poydevor bo'ladi.
///
/// Ravoq asta ko'tariladi (scale+fade). Reduce-motion'da darrov to'liq.
class _ArchIcon extends StatelessWidget {
  const _ArchIcon({
    required this.icon,
    required this.seed,
    required this.palette,
  });

  final IconData icon;
  final String seed;
  final int palette;

  @override
  Widget build(BuildContext context) {
    final animate = AppMotion.on(context);
    final arch = PeshtoqMedallion(
      width: 164,
      palette: palette,
      child: Icon(icon),
    );
    if (!animate) return arch;
    return TweenAnimationBuilder<double>(
      key: ValueKey(seed),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        // Ravoq PASTDAN ko'tariladi — devor qurilayotgandek.
        child: Transform.scale(
          scale: 0.82 + 0.18 * v,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: arch,
    );
  }
}

/// Til tanlagich — intro ekranidagi uchta tugma.
///
/// Segment tugmalar ATAYIN (ochiluvchi ro'yxat emas): uchta variant
/// darhol ko'rinsin. Ruszabon odam «RU» ni ko'rmasa, uni qidirmaydi —
/// u shunchaki ilovani yopadi.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;

    return SegmentedButton<String>(
      showSelectedIcon: false,
      // 🔴 `VisualDensity.compact` OLIB TASHLANDI (2026-09-04 o'lchovi):
      // u segment balandligini 40 px ga tushirardi, Android qoidasi esa
      // 48. Bu ilovaning ENG BIRINCHI ekranidagi eng birinchi tanlov —
      // odam tilni tanlay olmasa, boshqa hech narsaga yetmaydi.
      // Uch banddan iborat qator 320 px ga ham bemalol sig'adi
      // (`ui_narrow_audit_test` tekshiradi).
      style: const ButtonStyle(),
      segments: const [
        // Nomlar TARJIMA QILINMAYDI: har til o'z nomida yozilsa,
        // o'sha tilda gapiradigan odam uni tanidi.
        ButtonSegment(value: 'uz', label: Text('UZ')),
        // Kirill — «ЎЗ», chunki «UZ» bilan yonma-yon turganda farqi
        // yozuvning O'ZIDA ko'rinishi kerak.
        ButtonSegment(value: 'uz-Cyrl', label: Text('ЎЗ')),
        ButtonSegment(value: 'ru', label: Text('RU')),
        ButtonSegment(value: 'en', label: Text('EN')),
      ],
      selected: {current},
      onSelectionChanged: (value) {
        AppHaptics.select();
        ref.read(localeProvider.notifier).set(value.first);
      },
    );
  }
}
