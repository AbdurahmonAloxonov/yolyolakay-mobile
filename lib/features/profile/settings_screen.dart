import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/env.dart';
import '../../core/haptics.dart';
import '../../l10n/strings.dart';
import '../shared/hold_to_confirm.dart';
import '../shared/skeleton.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../shared/yol_refresh.dart';
import '../support/support_sheet.dart';
import '../shared/brand/brand_panels.dart';
import 'password_sheet.dart';

/// SOZLAMALAR — profildan AJRATILGAN (2026-09-02).
///
/// 🔴 NEGA (egasi): «profilga hamma narsa tiqilib ketgan — profilda
/// profil ma'lumotlari qolsin, qolganini sozlamalar ikonkasiga
/// berkitamiz».
///
/// To'g'ri tanqid edi. Profil ekrani 1400 satrga yetgan va u yerda
/// bir-biriga umuman aloqasi yo'q narsalar yonma-yon turardi:
/// mashinalar, tariflar, daromad, til, tema, katta matn, ovozli
/// o'qish, parol, xavfsizlik, xotira kartasi, do'stni taklif qilish,
/// xizmat holati, chiqish, hisobni o'chirish, huquqiy havolalar va
/// ilova versiyasi. Odam o'z ismini ko'rish uchun shu ro'yxatni
/// varaqlashi kerak edi.
///
/// Endi profil — KIMLIGI haqida (surat, ism, ishonch, rol), bu ekran
/// esa BOSHQARUV haqida.
///
/// ⚠️ Bo'limlar tartibi ATAYIN: avval «mening narsalarim» (kunda
/// kerak bo'ladigan), keyin sozlamalar, oxirida hisob amallari —
/// chiqish va o'chirish eng pastda, chunki ular qaytarib bo'lmaydigan
/// yoki noqulay amallar.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Huquqiy sahifa brauzerda ochiladi — matn ilovada takrorlanmaydi, aks holda
  /// shartlar o'zgarganda eskisi ilovada qolib ketardi.
  Future<void> _openLegal(
    BuildContext context,
    String page,
    String langCode,
  ) async {
    final t = AppStrings.of(context);
    final opened = await launchUrl(
      Uri.parse(Env.legalUrl(page, langCode)),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) showMessage(context, t.linkOpenFailed);
  }

  /// Yordam — ILOVA ICHIDA murojaat oynasi.
  ///
  /// 🔴 2026-08-16 gacha bu tugma to'g'ridan Telegramga olib chiqardi.
  /// Ikki muammosi bor edi: odam ilovadan chiqib ketardi va ko'pincha
  /// qaytmasdi; operator esa "qaysi versiya, qanaqa telefon?" deb
  /// so'rashiga to'g'ri kelardi — odam buni bilmaydi yoki yozmaydi.
  /// Endi ilova texnik ma'lumotni O'ZI qo'shadi.
  ///
  /// Telegram YO'QOLMADI: u oyna tepasida shoshilinch yo'l sifatida
  /// turadi (yo'lda hodisa bo'lganda forma to'ldirilmaydi).
  Future<void> _openSupport(BuildContext context) => SupportSheet.show(context);

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  /// HISOBNI O'CHIRISH — Google Play talabi (2024-dan majburiy): o'chirish yo'li
  /// ilova ICHIDA bo'lishi shart. Ikki bosqichli tasdiq, chunki qaytarilmaydi.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final t = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.deleteAccountConfirm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.deleteAccountWarning),
            const SizedBox(height: AppSpace.lg),
            // Oddiy tugма o'rniga BOSIB USHLAB tasdiqlash — qaytarilmaydigan
            // amал tasodifan bosilmasin (izoh `HoldToConfirm`da).
            HoldToConfirm(
              label: t.deleteAccount,
              icon: Icons.delete_outline,
              onConfirmed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(usersRepositoryProvider).deleteAccount();
      if (context.mounted) showMessage(context, t.deleteAccountDone);
      await ref.read(authControllerProvider.notifier).logout();
    } catch (_) {
      if (context.mounted) showMessage(context, t.deleteAccountFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(meProvider);
    final langCode = ref.watch(langCodeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle), bottom: const JiyakLine()),
      body: me.when(
        loading: () => const ListSkeleton(),
        error: (error, _) =>
            ErrorView(error: error, onRetry: () => ref.invalidate(meProvider)),
        data: (data) {
          return YolRefresh(
            onRefresh: () => ref.refresh(meProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.lg,
                AppSpace.screen,
                AppSpace.lg,
              ),
              children: [
                // ── MENING NARSALARIM ──────────────────────────────────────────
                //
                // ROLGA BOG'LIQ, LEKIN HAMMASI EMAS.
                //
                // Egasi 2026-08-13 da aytdi: «rolni almashtirsam qolgan
                // narsalar ko'rinib turibdi — bu katta xato». O'shanda men
                // BUTUN blokni haydovchi rejimiga bog'lab yuborgan edim va
                /*
                 * «MENING NARSALARIM» BU YERDA EMAS — PROFILDA.
                 *
                 * 🔴 18.09.2026, egasi: «sozlamalardagi mening narsalarim
                 * profilga o'tsin, sozlamalarda turishi g'alati ekan».
                 * Mashinalarim, tarifim, daromadim, xotira kartam va
                 * do'stni chaqirish — bular sozlama EMAS. Sozlama —
                 * ilova QANDAY ishlashi; ular esa MEN KIMMAN degan
                 * savolning javobi. Kodi `my_stuff_section.dart` da.
                 */
                // ── SOZLAMALAR ─────────────────────────────────────────────────
                const SizedBox(height: AppSpace.xl),
                SectionLabel(t.settingsTitle),
                Card(
                  child: Column(
                    children: [
                      // Til va ko'rinish — IXCHAM qatorlar.
                      //
                      // 🔴 Nima buzilgan edi: ikkalasi ham to'liq kenglikdagi
                      // `SegmentedButton` bilan, yorliq OSTIDA turardi. Bu
                      // 2026-08-08 dagi matn sinishi muammosining yechimi edi
                      // (`ListTile.trailing` da "Til" -> "Ti/l"), lekin narxi
                      // baland bo'ldi: ikkita sozlama butun ekranning yarmini
                      // egallardi va "Sozlamalar" bo'limi cheksiz cho'zilardi
                      // (egasi qurilmada aytdi, 2026-08-13).
                      //
                      // Endi qator qisqa: chapda nomi, o'ngda TANLANGAN qiymat.
                      // Bosilganda tanlov varag'i ochiladi — u yerda joy yetarli,
                      // ya'ni matn sinishi ham qaytmaydi.
                      _ChoiceTile(
                        icon: Icons.language,
                        label: t.language,
                        value: switch (langCode) {
                          'ru' => 'Русский',
                          'en' => 'English',
                          'uz-Cyrl' => 'Ўзбекча',
                          _ => 'O\'zbekcha',
                        },
                        onTap: () => _pickOption<String>(
                          context: context,
                          title: t.language,
                          selected: langCode,
                          // Har til O'Z YOZUVIDA: kirillda o'qiydigan
                          // odam «Ўзбекча» ni ko'rib taniydi.
                          options: const [
                            ('uz', 'O\'zbekcha'),
                            ('uz-Cyrl', 'Ўзбекча'),
                            ('ru', 'Русский'),
                            ('en', 'English'),
                          ],
                          onSelected: (value) =>
                              ref.read(localeProvider.notifier).set(value),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ChoiceTile(
                        icon: Icons.brightness_6_outlined,
                        label: t.theme,
                        value: switch (ref.watch(themeModeProvider)) {
                          ThemeMode.light => t.themeLight,
                          ThemeMode.dark => t.themeDark,
                          ThemeMode.system => t.themeSystem,
                        },
                        onTap: () => _pickOption<ThemeMode>(
                          context: context,
                          title: t.theme,
                          selected: ref.read(themeModeProvider),
                          options: [
                            (ThemeMode.system, t.themeSystem),
                            (ThemeMode.light, t.themeLight),
                            (ThemeMode.dark, t.themeDark),
                          ],
                          onSelected: (value) =>
                              ref.read(themeModeProvider.notifier).set(value),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      // USLUB — Classic yoki Neon (egasi, 2026-08-20).
                      // Yorug'lik (yuqoridagi Mavzu) dan alohida o'lchov.
                      _ChoiceTile(
                        icon: Icons.auto_awesome_outlined,
                        label: t.themeStyle,
                        value: switch (ref.watch(themeStyleProvider)) {
                          ThemeStyle.classic => t.themeStyleClassic,
                          ThemeStyle.neon => t.themeStyleNeon,
                          ThemeStyle.amber => t.themeStyleAmber,
                        },
                        onTap: () => _pickOption<ThemeStyle>(
                          context: context,
                          title: t.themeStyle,
                          selected: ref.read(themeStyleProvider),
                          options: [
                            (ThemeStyle.classic, t.themeStyleClassic),
                            (ThemeStyle.neon, t.themeStyleNeon),
                            // TUNGI HAYDASH — ro'yxatning oxirida: u
                            // bezak emas, aniq bir vaziyat uchun.
                            (ThemeStyle.amber, t.themeStyleAmber),
                          ],
                          onSelected: (value) =>
                              ref.read(themeStyleProvider.notifier).set(value),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      // KATTA MATN — tizim sozlamasini topa olmaydigan odam
                      // ilovaning O'ZIDAN kattalashtira olsin (izohi
                      // `BigTextController` da). Aynan shu odamlar uchun
                      // ovozli qidiruv ham qilingan.
                      SwitchListTile(
                        secondary: const Icon(Icons.format_size),
                        title: Text(t.bigText),
                        subtitle: Text(t.bigTextHint),
                        value: ref.watch(bigTextProvider),
                        onChanged: (value) {
                          AppHaptics.select();
                          ref.read(bigTextProvider.notifier).set(value);
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      // OVOZ BILAN O'QISH — standart O'CHIQ.
                      //
                      // 🔴 Ovoz — bezovta qiluvchi narsa: so'ramasdan
                      // gapira boshlagan ilova darhol o'chiriladi va
                      // qaytib yoqilmaydi. Odam o'zi yoqsa esa aynan
                      // shuni kutadi. Kimga kerak: haydovchi to'rt soat
                      // ekranga qaramaydi, lekin eshita oladi.
                      SwitchListTile(
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: Text(t.readAloudTitle),
                        subtitle: Text(t.readAloudHint),
                        value: ref.watch(readAloudProvider),
                        onChanged: (value) {
                          AppHaptics.select();
                          ref.read(readAloudProvider.notifier).set(value);
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      // Parol — SMS'siz kirish yo'li. OTP kunlik 5 ta bilan cheklangan.
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: Text(t.setPassword),
                        subtitle: Text(t.passwordHint),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => PasswordSheet.show(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: Text(t.securityTitle),
                        subtitle: Text(
                          '${t.sessionsTitle} · ${t.blockedUsersTitle}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(Routes.security),
                      ),
                      const Divider(height: 1, indent: 56),
                      // XIZMAT HOLATI — «ilova buzuqmi yoki internetmi?»
                      // degan savolga javob (izohi ekranning o'zida).
                      ListTile(
                        leading: const Icon(Icons.monitor_heart_outlined),
                        title: Text(t.serviceStatusTitle),
                        subtitle: Text(t.statusLastSync),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(Routes.serviceStatus),
                      ),
                    ],
                  ),
                ),

                // ── HISOB ──────────────────────────────────────────────────────
                // Xavfli amallar ENG OXIRIDA va alohida kartada: tasodifan bosilmasin.
                // ⚠️ CHIQISH va HISOBNI O'CHIRISH ATAYIN AJRATILGAN.
                //
                // 🔴 Ilgari ikkalasi BITTA kartada, yonma-yon va bir xil
                // qizil rangda turardi — orasida faqat ingichka chiziq.
                // Biri kundalik va qaytariladi, ikkinchisi esa butunlay va
                // qaytarilmaydi; ularni bir xil ko'rsatish xato bosishga
                // taklif qilish bilan barobar (egasi qurilmada aytdi,
                // 2026-08-13).
                //
                // Endi: chiqish — ODDIY qator (qizil emas, chunki u xavfli
                // amal emas); o'chirish — alohida, pastda va qizil.
                const SizedBox(height: AppSpace.xl),
                SectionLabel(t.sectionAccount),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(t.logout),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
                // Xavfli amal: kartadan ham chiqarilgan — u "sozlamalar
                // ro'yxatining davomi" emas.
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => _confirmDeleteAccount(context, ref),
                    onLongPress: () =>
                        _openLegal(context, 'account-delete', langCode),
                    icon: Icon(
                      Icons.delete_forever_outlined,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      t.deleteAccount,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                Padding(
                  // Ostki yozuv tugmaga yaqin, futer havolalaridan esa UZOQ
                  // turishi kerak — aks holda uchtasi bitta uyum bo'lib
                  // ko'rinadi (o'z tuzatishimdan keyin ko'rildi).
                  padding: const EdgeInsets.only(
                    top: AppSpace.xs,
                    bottom: AppSpace.lg,
                  ),
                  child: Text(
                    t.deleteAccountWeb,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // ── FUTER ──────────────────────────────────────────────────────
                // Yordam va huquqiy hujjatlar ATAYIN qator emas, kichik havola:
                // ular kunda kerak bo'lmaydi, lekin doim topiladigan joyda tursin.
                // Ilgari ular "Mashinalarim"/"Xavfsizlik" bilan bir xil og'irlikdagi
                // qatorlar edi va ro'yxatni bekorga cho'zardi.
                _ProfileFooterLinks(
                  onSupport: () => _openSupport(context),
                  onPrivacy: () => _openLegal(context, 'privacy', langCode),
                  onTerms: () => _openLegal(context, 'terms', langCode),
                ),
                // Ilova versiyasi — eng pastda, kam urg'u bilan. Ilgari
                // hech qayerda ko'rsatilmasdi: odam (va egasi) qaysi versiyani
                // ishlatayotganini bilmasdi, murojaatda ham foydali.
                const SizedBox(height: AppSpace.md),
                Center(
                  child: Text(
                    'v${Env.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Profil oxiridagi kichik havolalar qatori: Yordam · Maxfiylik · Oferta.
///
/// Bosiladigan maydon ko'zga ko'ringan matndan KATTA (vertikal 10 px padding):
/// kichik yozuv bo'lsa ham barmoq bilan tegish qiyin bo'lmasligi kerak.
class _ProfileFooterLinks extends StatelessWidget {
  const _ProfileFooterLinks({
    required this.onSupport,
    required this.onPrivacy,
    required this.onTerms,
  });

  final VoidCallback onSupport;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.onSurfaceVariant,
    );

    /*
     * 🔴 QATOR EMAS, MATN (2026-09-03, zo'riqish ko'rigi).
     *
     * Uchta havola `Wrap` ichida `Row` bo'lib turardi va 320 px
     * ekranda ruscha matnda qator o'ngdan 5.2 px toshardi: `Wrap`
     * BUTUN `Row` ni ko'chiradi, ichidagi matnni emas. `Flexible`
     * toshishni to'xtatdi-yu, ajratgich nuqta yolg'iz qatorda
     * osilib qoldi.
     *
     * Endi bu oddiy matn xatboshisi: havolalar `TextSpan`, ajratgich
     * ularning orasida. Matn tabiiy ko'chadi, nuqta hech qachon
     * yolg'iz qolmaydi va toshish tushunchasi umuman yo'qoladi.
     */
    final dot = TextSpan(
      text: '  ·  ',
      style: style?.copyWith(decoration: TextDecoration.none),
    );
    TextSpan span(String label, VoidCallback onTap) => TextSpan(
      text: label,
      style: style,
      recognizer: TapGestureRecognizer()..onTap = onTap,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Text.rich(
        TextSpan(
          children: [
            span(t.support, onSupport),
            dot,
            span(t.privacyPolicy, onPrivacy),
            dot,
            span(t.termsOfUse, onTerms),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Profildagi tarif qatorining ostki yozuvi.
///
/// Obuna hali yuklanmagan yoki umuman yo'q bo'lsa — qator baribir ko'rinadi
/// (tarif tanlashga kirish yo'li), faqat izohsiz.
/// Sozlama qatori: chapda nomi, o'ngda TANLANGAN qiymat.
///
/// Tanlagichning o'zi bu yerda chizilmaydi — qator qisqa qolishi kerak.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Hozir tanlangan variant nomi — odam varaqni ochmasdan bilishi uchun.
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    /*
     * 🔴 `ListTile` DAN VOZ KECHILDI (2026-09-03, zo'riqish ko'rigi).
     *
     * `ListTile` avval `trailing` ga O'Z ENINI beradi va sarlavhaga
     * QOLGANINI qoldiradi. 320 px ekranda ruscha va katta matn
     * rejimida qiymat («Классический») butun joyni olib, «Стиль»
     * so'zi ekranda HAR HARFI ALOHIDA QATORDA chizilardi.
     * Chegarani kichraytirish yordam bermadi — muammo chegarada emas,
     * TARTIBDA: kim birinchi joy oladi.
     *
     * Endi taqsimot aniq: sarlavha 5 ulush, qiymat 4 ulush. Odam
     * qaysi sozlama ekanini SARLAVHADAN biladi, qiymat esa qisqarsa
     * ham zarar yo'q — bosilganda varaqda to'liq ko'rinadi.
     */
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.lg),
            Expanded(flex: 5, child: Text(label)),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              flex: 4,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// Variant tanlash varag'i.
///
/// Ro'yxat ko'rinishi ATAYIN: uch tilni yonma-yon tugmaga siqqanda matn
/// sinib ketardi, bu yerda esa har biri o'z qatorida to'liq yoziladi.
Future<void> _pickOption<T>({
  required BuildContext context,
  required String title,
  required T selected,
  required List<(T, String)> options,
  required void Function(T value) onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
    // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
    // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
    // qolib, bosib bo'lmaydigan bo'lardi.
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Text(
              title,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final (value, label) in options)
            ListTile(
              title: Text(label),
              trailing: value == selected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(sheetContext).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                onSelected(value);
                Navigator.of(sheetContext).pop();
              },
            ),
          const SizedBox(height: AppSpace.sm),
        ],
      ),
    ),
  );
}
