import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/active_role.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';
import '../shared/bottom_action_bar.dart';
import '../shared/brand/brand_panels.dart';
import '../shared/ui.dart';
import '../shared/yol_button.dart';

/// Yangi hisob uchun profil — `verify-otp` `is_new_user: true` qaytarganda.
///
/// Bu ekrandan orqaga yo'l yo'q (router boshqa hamma joyni to'sadi): ismsiz
/// foydalanuvchi qidiruvda "—" bo'lib ko'rinadi va haydovchi uni tanimaydi.
///
/// 🔑 IKKI QADAM (egasi, 22.09.2026: «role ni so'rashni otp dan keyin,
/// akkaunt ma'lumotlarini olishdan oldin — yo'lovchimi haydovchimi
/// so'ralsin»):
///
///   1) SEN KIMSAN — yo'lovchi yoki haydovchi;
///   2) ism, familiya, jins.
///
/// Tartib ATAYIN shunday: rol javobi qolgan hamma narsaga ma'no beradi
/// (ilova qaysi ekrandan ochilishi, keyin nima so'ralishi). Ilgari bu
/// savol UMUMAN berilmasdi — odam ro'yxatdan o'tib to'g'ridan-to'g'ri
/// yo'lovchi qidiruviga tushardi, haydovchi esa o'z yo'lini profil
/// ichidan qidirib topishi kerak edi.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String? _gender;
  bool _saving = false;

  /// 0 — rol tanlash, 1 — ism/jins.
  int _step = 0;

  /// Tanlangan rol. `null` — hali tanlanmagan (tugma o'chiq turadi).
  AppRole? _role;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _firstName.text.trim().isNotEmpty && _lastName.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final t = AppStrings.of(context);
    if (!_isValid) {
      showMessage(context, t.nameRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      // 🔴 2026-08-07, JONLI QURILMADA TOPILDI: bu yerda `createProfile()`
      // (`POST /users`) chaqirilardi va ro'yxatdan o'tish SHU YERDA to'xtardi.
      //
      // Sabab: `verify-otp` hisobni ALLAQACHON yaratadi — shuning uchun bu ekranga
      // kelgan odamda haqiqiy token bor (`sub` = user id). `POST /users` esa o'sha
      // hisobni QAYTA yaratmoqchi bo'ladi va gateway `409 Conflict` qaytaradi
      // (swagger: `/users` javoblari 201/400/409). Ekran xato ko'rsatib qotib qolardi,
      // ya'ni YANGI FOYDALANUVCHI ILOVAGA UMUMAN KIRA OLMASDI.
      //
      // To'g'ri chaqiruv — mavjud hisobni TO'LDIRISH: `PUT /users/profile`.
      // Web'da bu allaqachon shunday (`shared/api/users.ts` -> updateProfile).
      await ref
          .read(usersRepositoryProvider)
          .updateProfile(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            gender: _gender,
          );

      /*
       * TANLANGAN ROL QURILMADA SAQLANADI.
       *
       * ⚠️ SERVERGA YOZILMAYDI va yozib ham bo'lmaydi: gateway'da rolni
       * o'zgartiradigan endpoint YO'Q — haydovchilik faqat
       * `POST /users/upgrade` (hujjat + mashina) va moderatsiya orqali
       * beriladi. Shuning uchun bu tanlov ILOVANING qaysi ko'zi bilan
       * ochilishini belgilaydi, hisobning huquqini emas.
       *
       * 🔑 `activeRoleProvider` haydovchi bo'lmaganda `passenger` ga
       * qaytaradi (izohi `active_role.dart` da) — lekin QURILMADAGI
       * yozuv qoladi va tekshiruv tasdiqlangan kuni ilova o'zi
       * haydovchi rejimida ochiladi. Ya'ni odam tanlovini ikkinchi
       * marta qilmaydi.
       */
      final role = _role ?? AppRole.passenger;
      ref.read(activeRoleProvider.notifier).set(role);

      // Router `becomeDriver` ga o'tkazishdan OLDIN olinadi: bayroq
      // o'chishi bilan bu ekran yopiladi va `context` yaroqsiz bo'ladi.
      final router = ref.read(routerProvider);

      // Bayroqni o'chiramiz — router ilova ichiga o'tkazadi.
      ref.read(authControllerProvider.notifier).profileCompleted();

      /*
       * HAYDOVCHI TANLAGAN ODAM — TO'G'RI TEKSHIRUVGA.
       *
       * 🔴 VA'DA BERILMAYDI: u hozir haydovchi EMAS. Tekshiruv ekrani
       * nimalar kerakligini aytadi va yuborilgach moderatsiyani kutadi.
       * Shu sababli ekran `push` bilan USTIGA qo'yiladi — orqaga qaytsa
       * odam ilovadan yo'lovchi sifatida foydalanaveradi, hech qayerda
       * qamalib qolmaydi.
       */
      if (role == AppRole.driver) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => router.push(Routes.becomeDriver),
        );
      }
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final atRole = _step == 0;

    return Scaffold(
      appBar: AppBar(
        bottom: const JiyakLine(),
        title: Text(atRole ? t.chooseRoleTitle : t.completeProfileTitle),
        automaticallyImplyLeading: false,
        // Ikkinchi qadamdan rolga QAYTISH mumkin: odam noto'g'ri bosgan
        // bo'lishi mumkin va tanlovni faqat ilovadan chiqib o'zgartirish
        // boshi berk ko'cha bo'lardi.
        leading: atRole
            ? null
            : BackButton(onPressed: () => setState(() => _step = 0)),
      ),
      body: SafeArea(
        child: atRole ? _roleStep(t) : _infoStep(t),
      ),
      // 🔴 Tugma suriladigan qism ICHIDA TURMASIN (loyiha qoidasi,
      // `main_button_reachable_test.dart`): u ilgari ro'yxatning oxirida
      // edi va katta matnli telefonda oxirgi maydonga yopishib qolardi.
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // O'CHIQ TUGMANING SABABI YOZILADI — jim turgan o'chiq tugma
            // boshi berk ko'cha (loyiha qoidasi).
            if (atRole && _role == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text(
                  t.chooseRoleRequired,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            if (!atRole && !_isValid)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text(
                  t.nameRequired,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            YolButton(
              onPressed: atRole
                  ? (_role == null ? null : () => setState(() => _step = 1))
                  : (_saving || !_isValid ? null : _submit),
              busy: _saving,
              label: t.continueButton,
            ),
          ],
        ),
      ),
    );
  }

  /// 1-QADAM — «Siz kimsiz?».
  Widget _roleStep(AppStrings t) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xl),
      children: [
        _StepCounter(step: 1, total: 2),
        const SizedBox(height: AppSpace.md),
        Text(
          t.chooseRoleHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        _RoleCard(
          icon: Icons.person_outline,
          title: t.rolePassenger,
          subtitle: t.chooseRolePassengerHint,
          selected: _role == AppRole.passenger,
          onTap: () => setState(() => _role = AppRole.passenger),
        ),
        const SizedBox(height: AppSpace.md),
        _RoleCard(
          icon: Icons.directions_car_outlined,
          title: t.roleDriver,
          subtitle: t.chooseRoleDriverHint,
          selected: _role == AppRole.driver,
          onTap: () => setState(() => _role = AppRole.driver),
        ),
        // HAQIQAT DARHOL AYTILADI: haydovchilik tekshiruvdan o'tadi.
        // Buni keyinroq aytish «aldadi» degan taassurot beradi va
        // aynan shu nuqtada ishonch yo'qoladi.
        if (_role == AppRole.driver) ...[
          const SizedBox(height: AppSpace.md),
          InfoBox(
            tone: InfoTone.warning,
            child: Text(
              t.chooseRoleDriverNote,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }

  /// 2-QADAM — ism, familiya, jins.
  Widget _infoStep(AppStrings t) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xl),
      children: [
        _StepCounter(step: 2, total: 2),
        const SizedBox(height: AppSpace.md),
        Text(
          t.completeProfileHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        TextField(
          // Klaviaturada «Keyingi» — fokus keyingi maydonga o'zi o'tadi.
          // Busiz odam har maydondan keyin klaviaturani yopib, keyingisini
          // qo'li bilan izlardi (`textInputAction` butun ilovada UMUMAN
          // yo'q edi — 2026-08-25 auditi).
          controller: _firstName,
          textInputAction: TextInputAction.next,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: t.firstName),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _lastName,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: t.lastName),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.xl),
        Text(t.gender, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpace.sm),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'male', label: Text(t.male)),
            ButtonSegment(value: 'female', label: Text(t.female)),
          ],
          selected: _gender == null ? const {} : {_gender!},
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(
            () => _gender = selection.isEmpty ? null : selection.first,
          ),
        ),
      ],
    );
  }
}

/// «1/2» — qadam hisoblagichi.
///
/// Raqamlar ATAYIN matnsiz: uch tilda ham bir xil o'qiladi va
/// tarjimasiz turadi. Ma'nosi — oqim qancha davom etishi (odam
/// «yana qancha qoldi?» degan savol bilan qolmasin).
class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$step/$total',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: step / total,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rol kartasi — katta bosiladigan maydon.
///
/// ⚠️ Butun karta bosiladi, faqat radio nuqtasi emas: 44 px qoidasiga
/// ko'ra mayda nishonni nishonga olish telefonda og'riq beradi
/// (`tap_target_test`).
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Tanlanganini RANG bilan emas, BELGI bilan ham aytamiz:
              // rang ko'rmaydigan odam uchun chegara qalinligi yetmaydi.
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 22,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
