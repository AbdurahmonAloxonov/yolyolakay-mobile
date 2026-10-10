import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/env.dart';
import '../../core/format.dart';
import '../../l10n/strings.dart';
import '../shared/brand/brand_panels.dart';
import '../support/support_entry.dart';
import '../shared/brand/ornament.dart';
import '../shared/password_field.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';

/// Kirish — telefon raqam.
///
/// Alohida "ro'yxatdan o'tish" ekrani YO'Q: `verify-otp` raqam bazada
/// bo'lmasa hisobni o'zi yaratadi.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;

  /// Shu ekranda kamida bitta xato bo'ldimi.
  ///
  /// 🔴 NEGA HOLAT SAQLANADI (22.09.2026): xabar (snackbar) 4 soniyada
  /// so'nadi va odam xato bilan YOLG'IZ qoladi — «SMS kelmadi» holatida
  /// aynan shunday bo'lardi. Xatodan keyin yordam havolasi sokin
  /// yozuvdan KO'RINADIGAN tugmaga aylanadi va shundayligicha qoladi.
  bool _hadError = false;

  /// Parol rejimi — SMS'siz kirish.
  ///
  /// NEGA KERAK: OTP kunlik 5 ta bilan cheklangan va har SMS pul turadi.
  /// Parolsiz odam limitga urilsa ilovaga UMUMAN kira olmaydi. Repozitoriyda
  /// `loginWithPassword` allaqachon bor edi, faqat bu ekranda yo'li yo'q edi.
  bool _passwordMode = false;

  @override
  void dispose() {
    _controller.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.length == 9;

  Future<void> _submit() async {
    final t = AppStrings.of(context);
    if (!_isValid) {
      showMessage(context, t.invalidPhone);
      return;
    }

    final phone = toE164(_controller.text);
    setState(() => _sending = true);
    try {
      await ref.read(authControllerProvider.notifier).sendOtp(phone);
      if (!mounted) return;
      context.push(Routes.otp, extra: phone);
    } catch (error) {
      if (!mounted) return;
      setState(() => _hadError = true);
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitPassword() async {
    final t = AppStrings.of(context);
    if (!_isValid) {
      showMessage(context, t.invalidPhone);
      return;
    }
    if (_password.text.length < 6) {
      showMessage(context, t.passwordTooShort);
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithPassword(toE164(_controller.text), _password.text);
      // Router `isAuthenticated` o'zgarishini o'zi ushlaydi — qo'lda o'tkazmaymiz.
    } on NewDeviceException {
      // Parol TO'G'RI, shunchaki qurilma notanish — backend SMS'ni O'ZI yubordi.
      // Qizil xato ko'rsatsak odam "parolim noto'g'ri" deb o'ylaydi. Qayta
      // `sendOtp` ham QILMAYMIZ: kod ketgan, ikkinchisi 429 ga olib boradi.
      if (!mounted) return;
      context.push(
        '${Routes.otp}?new_device=1',
        extra: toE164(_controller.text),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _hadError = true);
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    /*
     * 🔴 SURILADIGAN QILINDI (2026-08-30 auditi).
     *
     * Ilgari bu qattiq `Column` edi: katta matn rejimida (1.3 baravar)
     * 320 pikselli telefonda pastdan 84 piksel toshardi — ya'ni til
     * almashtirgich, ba'zan esa kirish tugmasi ham ekrandan tushib
     * qolardi. Klaviatura ochilganda ham ayni hol.
     *
     * 🔴 IKKINCHI MARTA TUZATILDI (10.09.2026, o'lchandi). O'sha kuni
     * qo'yilgan yechim — `minHeight` + `IntrinsicHeight` + `Spacer`
     * (til almashtirgich pastda tursin degan maqsadda) — o'zi YANGI
     * toshish yasagan ekan: 320 px, ruscha, matn shkalasi 1.3 da
     * pastdan 25 px. Sabab: `IntrinsicHeight` matn balandligini BIR
     * QATOR deb hisoblaydi (u eng katta ichki ENni oladi), haqiqiy
     * enda esa peshtoqdagi shior ruschada IKKI qatorga o'ralardi.
     *
     * Nega ikki hafta ko'rinmadi: testlarda ilova o'zining shriftida
     * chizilmasdi (`ThemeData` dagi `fontFamily` ishlamayotgan edi,
     * `theme_font_test.dart`), yuklanmagan shriftda esa shior bir
     * qatorga sig'ardi.
     *
     * Endi `IntrinsicHeight` ham, `Spacer` ham YO'Q — ustun o'z
     * tabiiy balandligida va shunchaki suriladi. Til almashtirgich
     * ekran pastida emas, formadan keyin turadi: bu yo'qotish, lekin
     * kirish ekranining HAR TILDA va har qanday matn kattaligida
     * butun ko'rinishi muhimroq.
     */
    /*
     * DARVOZA (2026-09-03, milliylashtirish to'lqini).
     *
     * 🔴 Ilgari bu ekran BO'M-BO'SH edi: pushti yozuv, maydon, tugma
     * va ekranning yarmidan ko'pi oq bo'shliq. Ilova bilan birinchi
     * uchrashuv aynan shu yerda bo'ladi va u hech narsa aytmasdi —
     * na kimligimizni, na qayerdanligimizni.
     *
     * Endi ekran PESHTOQ bilan ochiladi: tepasida atlas jiyagi
     * (ilovaning tikuv chizig'i), to'q blokda girih naqshi va palak
     * rozetkasi, ostida esa muqarnas qatori yorug' zaminga o'tadi.
     * Ya'ni odam darvozadan kirib kelayotgandek bo'ladi.
     *
     * ⚠️ Brend nomi PUSHTI EMAS, oq: bu ekranda pushti faqat «Kod
     * yuborish» tugmasiga tegishli («bitta bo'lakda bitta pushti»).
     */
    return Scaffold(
      body: Stack(
        children: [
          // GANCH — o'yma naqsh, endi BUTUN EKRAN foni. Ilgari u
          // formaning `Expanded` i ichidagi `Stack` da turardi va
          // «qolgan joyni to'ldir» vazifasi forma ustunini qat'iy
          // balandlikka qamab qo'yardi (yuqoridagi izoh). Fon sifatida
          // u hech kimning balandligini cheklamaydi; tepasini shaffof
          // bo'lmagan peshtoq o'zi yopadi.
          //
          // ⚠️ KUCHI O'LCHAB TANLANDI: 0.55 da naqsh oq to'r bo'lib
          // maydon va tugma bilan raqobatlashardi — sahifa bezovta
          // ko'rinardi. 0.32 da u faqat yorug'lik o'yini bo'lib
          // qoladi, ya'ni ganch aynan shunday ishlaydi.
          const Positioned.fill(child: GanchPattern(cell: 132, depth: 0.32)),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrnamentHeader(
                  jiyak: true,
                  rosette: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xl,
                    AppSpace.xl,
                    AppSpace.xl,
                    AppSpace.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          t.appName,
                          style: displayFontStyle(
                            theme.textTheme.displaySmall,
                          ).copyWith(color: onHeroSurface(theme)),
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        // Uch tilda — `AppStrings` da (ilgari bu yerda
                        // ikkilik ternar edi va inglizcha interfeysda
                        // ruscha chiqardi).
                        t.splashTagline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: onHeroSurface(theme).withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpace.xl),
                      Text(t.phoneLabel, style: theme.textTheme.labelLarge),
                      const SizedBox(height: AppSpace.sm),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                        decoration: InputDecoration(
                          prefixText: '+998  ',
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: '90 123 45 67',
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_passwordMode) ...[
                        const SizedBox(height: AppSpace.lg),
                        PasswordField(
                          controller: _password,
                          labelText: t.passwordLabel,
                          autofillHints: const [AutofillHints.password],
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submitPassword(),
                        ),
                      ],
                      const SizedBox(height: AppSpace.xl),
                      FilledButton(
                        onPressed: _sending || !_isValid
                            ? null
                            : (_passwordMode ? _submitPassword : _submit),
                        child: _sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_passwordMode ? t.loginTitle : t.sendCode),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      // SMS kelmasa yoki kunlik limit tugasa — yagona
                      // zaxira yo'l.
                      TextButton(
                        onPressed: _sending
                            ? null
                            : () => setState(() {
                                _passwordMode = !_passwordMode;
                                _password.clear();
                              }),
                        child: Text(
                          _passwordMode ? t.loginWithCode : t.loginWithPassword,
                        ),
                      ),
                      /*
                       * YORDAM — KIRISHDAN OLDIN HAM (22.09.2026).
                       *
                       * Ilgari bu ekranda yordamga chiqish yo'li UMUMAN
                       * yo'q edi: «Yordam» profil ostida turardi, profilga
                       * esa kirish kerak. Ya'ni kira olmayotgan odam —
                       * aynan yordamga muhtoj odam — bizga yozolmasdi.
                       */
                      const SizedBox(height: AppSpace.sm),
                      SupportLink(highlight: _hadError),
                      if (Env.mockAuth) ...[
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          'MOCK_AUTH yoqilgan — kod: 11111',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.xxl),
                      _LanguageSwitch(),
                      const SizedBox(height: AppSpace.lg),
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

/// Kirish ekranidagi til tanlash.
///
/// 🔴 2026-08-16: INGLIZ TILI YO'Q EDI. Ilova uchta tilni qo'llab-quvvatlaydi
/// va profilda "English" tanlash mumkin — lekin chiqib ketgan odam kirish
/// ekranida faqat o'zbek/rus tugmasini ko'rardi, ya'ni tanlagan tiliga
/// QAYTA OLMASDI. Yangi foydalanuvchi esa inglizchani umuman topolmasdi.
///
/// Ro'yxat `Lang` enumidan quriladi: yangi til qo'shilsa bu yer o'zgarmaydi.
class _LanguageSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(langProvider);
    // HAR TIL O'Z YOZUVIDA: kirillda o'qiydigan odam «Ўзбекча» ni
    // ko'rib taniydi, «Uzbek (Cyrillic)» ni esa qidirishi kerak bo'ladi.
    const names = {
      Lang.uz: "O'zbekcha",
      Lang.uzCyrl: 'Ўзбекча',
      Lang.ru: 'Русский',
      Lang.en: 'English',
    };

    /*
     * 🔴 `Row` EMAS, `Wrap` (2026-08-30 auditi).
     *
     * Uchta til nomi bitta qatorga SIG'MASDI: 360 piksellik ekranda
     * qator o'ngdan 113 piksel toshardi (320 px da 153). Ya'ni eng
     * keng tarqalgan Android telefonida «English» ekrandan chiqib
     * ketgan va uni BOSIB BO'LMAGAN.
     *
     * Bu shunchaki chiroylilik masalasi emas: til almashtirgich
     * ATAYIN kirish ekraniga qo'yilgan edi (2026-08-25) — «ruszabon
     * odam o'zbekcha ekranni ko'rib ketib qoladi». O'sha maqsad
     * jimgina buzilgan edi.
     */
    /*
     * 🔴 RANGLAR TESKARI EDI (2026-09-02 ko'rigi).
     *
     * Joriy til `onPressed: null` bilan berilardi — ya'ni u O'CHIQ
     * tugmaga aylanardi va KULRANG chizilardi. Qolgan ikkitasi esa
     * oddiy `TextButton` bo'lgani uchun BREND rangida turardi.
     *
     * Ekranda shunday ko'rinardi: «O'zbekcha» so'nik, «Русский» va
     * «English» esa yorqin pushti. Odam buni «o'zbekcha o'chirilgan»
     * deb o'qiydi — ya'ni holat TESKARI aytilgan edi.
     *
     * Endi: tanlangan til ENG KUCHLI (qalin, to'q, yumshoq zaminda),
     * qolganlari esa sokin va neytral. Pushti bu ekranda faqat
     * «Kod yuborish» tugmasiga tegishli.
     */
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.xs,
      children: [
        for (final lang in Lang.values)
          if (lang == current)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                names[lang]!,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            )
          else
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              // ⚠️ `lang.name` EMAS: u `uzCyrl` beradi, saqlanadigan
              // kod esa `uz-Cyrl` (backend ham shuni kutadi).
              onPressed: () =>
                  ref.read(localeProvider.notifier).set(langCode(lang)),
              child: Text(names[lang]!),
            ),
      ],
    );
  }
}
