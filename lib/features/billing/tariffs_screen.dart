import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../data/models/billing.dart';
import '../../app/theme.dart';
import '../../core/analytics.dart';
import '../../l10n/strings.dart';
import '../shared/ui.dart';
import 'payment_watcher.dart';
import '../shared/state_views.dart';
import '../shared/sheet_drag_to_close.dart';
import '../../../app/dimens.dart';
import '../shared/yol_refresh.dart';
import '../shared/refreshable.dart';
import '../shared/skeleton.dart';
import '../shared/brand/brand_panels.dart';
import '../shared/brand/atlas.dart';
import '../shared/brand/ornament.dart';

/// Tariflar.
///
/// [paywall] — e'lon berish paketi tugaganda ochiladi: tepada sabab ko'rsatiladi
/// va sotib olingach oldingi ekranga QAYTADI (profilga emas), foydalanuvchi
/// uzilgan ishini davom ettirsin.
class TariffsScreen extends ConsumerWidget {
  const TariffsScreen({super.key, this.paywall = false});

  final bool paywall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final plans = ref.watch(billingPlansProvider);

    // Click'dan qaytgan odamga to'lov natijasini AYTADI (hech narsa
    // chizmaydi, izohi `PaymentResultWatcher` da). Shu ekranga o'ralgan,
    // chunki to'lov shu yerdan boshlanadi va diplink ham shu yerga
    // qaytaradi (`deep_links.dart`).
    return PaymentResultWatcher(
      child: Scaffold(
        appBar: AppBar(title: Text(t.tariffsTitle), bottom: const JiyakLine()),
        // 🔴 TORTISH YUKLANISH VA XATODA HAM (2026-09-04) — izohi
        // `refreshableState` da.
        body: plans.when(
          loading: () => refreshableState(
            onRefresh: () => ref.refresh(billingPlansProvider.future),
            child: const ListSkeleton(),
          ),
          error: (error, _) => refreshableState(
            onRefresh: () => ref.refresh(billingPlansProvider.future),
            child: ErrorView(
              error: error,
              onRetry: () => ref.refresh(billingPlansProvider.future),
            ),
          ),
          data: (all) {
            /*
           * 🔴 YO'LOVCHI TARIFLARI KO'RSATILMAYDI (2026-09-03).
           *
           * Backend `GET /billing/plans` ga to'rtta yangi tarif
           * qo'shdi — «Passenger Trial / Plus / Pro / Premium»,
           * 1 000–5 000 so'mdan. Ya'ni yo'lovchidan bron uchun pul
           * olish taklif qilingan.
           *
           * Bizning modelimizda yo'lovchi PUL TO'LAMAYDI: to'lov
           * haydovchi tomonda. Egasi: «oldingi tariflarimiz Plus,
           * Pro, Premium yaxshi edi — qo'shilganlarini olib tashla».
           *
           * ⚠️ Roli NOMA'LUM tarif ko'rsatiladi (izohi
           * `BillingPlan.isForPassenger` da): maydon yo'qolsa ekran
           * bo'sh qolmasin.
           */
            /*
           * SINOV TARIFI SOTUV SETKASIDAN CHIQARILADI (2026-09-04).
           *
           * 🔴 U SOTILMAYDI: backend uni ro'yxatdan o'tgan HAR BIR
           * haydovchiga avtomatik beradi, ya'ni `has_used_trial` birinchi
           * kundanoq `true` (jonli o'lchandi). Demak kartaning tugmasi
           * DOIM o'chiq turardi — ro'yxatning boshida bosib bo'lmaydigan
           * karta, boshqa hech nima.
           *
           * Joriy tarif nomi tepadagi to'q hujjatda allaqachon yozilgan
           * («Sizning tarifingiz: Free Trial»), ya'ni ma'lumot
           * yo'qolmaydi. Saytda ham AYNAN shunday (`page.tsx`:
           * `.filter((p) => p.type !== 'trial')`).
           */
            final items = all
                .where((p) => !p.isForPassenger && !p.isTrial)
                .toList(growable: false);
            if (items.isEmpty) {
              // qulaylik: chiqish yo'li SHART EMAS — ro'yxat serverdan
              // keladi va ekran TORTIB-YANGILANADI (`YolRefresh` pastda).
              // Ya'ni harakat allaqachon bor, u faqat tugma shaklida emas.
              return EmptyView(
                icon: Icons.workspace_premium_outlined,
                title: t.noPlans,
              );
            }
            return YolRefresh(
              onRefresh: () async {
                // 🔴 `invalidate` SINXRON: u faqat "eskirdi" deb belgilaydi
                // va DARHOL qaytadi — indikator o'sha zahoti yo'qolardi,
                // ma'lumot esa keyinroq kelardi. Odam uchun bu "tortdim,
                // hech nima bo'lmadi" degani (egasi 2026-08-21).
                // `refresh(...future)` esa haqiqiy yuklanishni KUTADI.
                await Future.wait([
                  ref.refresh(billingPlansProvider.future),
                  ref.refresh(subscriptionProvider.future),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.lg),
                children: [
                  if (paywall) ...[
                    _PaywallBanner(),
                    const SizedBox(height: AppSpace.lg),
                  ],
                  const _CurrentPlanCard(),
                  const SizedBox(height: AppSpace.md),
                  // ENG FOYDALI tarif — narx/safar bo'yicha HISOBLANADI,
                  // qo'lda tanlanmaydi. Tarif setkasi o'zgarsa nishon ham
                  // o'zi ko'chadi; qotirilgan "pro" yozib qo'yilsa, narxlar
                  // o'zgargach yolg'onga aylanardi.
                  for (final plan in items) ...[
                    _PlanCard(
                      plan: plan,
                      paywall: paywall,
                      best: plan.planKey == bestValueKey(items),
                      breakEven: plan.isUnlimited
                          ? unlimitedBreakEven(items, plan)
                          : null,
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    t.tariffsFooter,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Bitta safarning narxi — tarif narxini paketga bo'lib.
///
/// 🔴 NEGA KO'RSATAMIZ: "60 000 so'm/oy" qimmat eshitiladi, "1 safar ≈
/// 1 500 so'm" esa arzon — VA IKKALASI HAM AYNI HAQIQAT. Reklama shu
/// yerdan kuchayadi: o'ylab topilgan gap emas, oddiy bo'lish amali.
///
/// Cheksiz va bepul tariflarda `null`: u yerda bo'linadigan son yo'q.
double? perRidePrice(BillingPlan plan) {
  if (plan.price <= 0 || plan.isUnlimited || plan.ridesQuota <= 0) return null;
  return plan.price / plan.ridesQuota;
}

/// Cheksiz tarif nechta safardan keyin eng arzon tarifdan foydali bo'ladi.
///
/// 🔴 NEGA KERAK: cheksiz tarif kartada eng qimmat raqamni ko'rsatadi va
/// uning foydasi hech qayerda ko'rinmasdi — odam shunchaki "100 000"
/// ni ko'rib o'tib ketardi. Endi kartada aniq shart turadi:
/// "67 safardan boshlab Pro'dan arzon".
///
/// Bu bir vaqtning o'zida ham REKLAMA, ham OGOHLANTIRISH: kam yuradigan
/// odamga bu tarif kerak emasligini ham aytadi. Aynan shu narsa uni
/// ishonarli qiladi — maqtov emas, hisob.
///
/// `null` — solishtiradigan cheklangan tarif yo'q.
({int rides, String planName})? unlimitedBreakEven(
  List<BillingPlan> plans,
  BillingPlan unlimited,
) {
  if (!unlimited.isUnlimited || unlimited.price <= 0) return null;

  BillingPlan? cheapest;
  double best = double.infinity;
  for (final plan in plans) {
    final perRide = perRidePrice(plan);
    if (perRide == null || perRide <= 0) continue;
    if (perRide < best) {
      best = perRide;
      cheapest = plan;
    }
  }
  if (cheapest == null) return null;

  // Yuqoriga yaxlitlanadi: "66.7 safar" degan gap yo'q, 67-safardan
  // boshlab haqiqatan arzonroq bo'ladi.
  final rides = (unlimited.price / best).ceil();
  return (rides: rides, planName: cheapest.name);
}

/// Eng foydali tarif kaliti: bitta safar eng arzonga tushadigani.
///
/// Bepul/sinov tariflar hisobga OLINMAYDI (ular bilan solishtirish ma'nosiz).
///
/// 🔴 CHEKSIZ TARIF HAM HISOBGA OLINMAYDI (2026-08-16). Ilgari u "0 so'm
/// bir safarga" deb hisoblanardi va DOIM g'olib chiqardi. Bu esa yolg'on
/// bo'lardi: cheksiz tarif faqat KO'P yuradigan odam uchun foydali, oyiga
/// ikki marta yuradigan odamga u eng qimmat variant. Nishon hisoblab
/// chiqarilgan haqiqatni aytishi kerak, umumiy maqtovni emas.
String? bestValueKey(List<BillingPlan> plans) {
  BillingPlan? best;
  double bestPerRide = double.infinity;
  for (final plan in plans) {
    if (plan.isTrial) continue;
    final perRide = perRidePrice(plan);
    if (perRide == null) continue;
    if (perRide < bestPerRide) {
      bestPerRide = perRide;
      best = plan;
    }
  }
  return best?.planKey;
}

class _PaywallBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.paywallTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    t.paywallHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Joriy obuna — yo'q bo'lsa umuman ko'rsatilmaydi (bo'sh karta shovqin).
class _CurrentPlanCard extends ConsumerWidget {
  const _CurrentPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final subscriptionState = ref.watch(subscriptionProvider);

    // 🔴 UZILISH "tarifingiz yo'q" DEGANI EMAS. Obuna so'rovi yiqilsa
    // (502, tarmoq), ekran joriy tarifni ko'rsatmay hammasini sotuvga
    // qo'yardi va odam IKKINCHI marta to'lab yuborishi mumkin edi.
    // Backend endi obunasi yo'q odamga 200 + bo'sh tana qaytaradi
    // (xat 2026-08-14), ya'ni haqiqiy bo'shlik xatodan ajraladi.
    if (subscriptionState.hasError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Expanded(child: Text(t.planUnknown)),
              const SizedBox(width: AppSpace.sm),
              TextButton(
                onPressed: () => ref.invalidate(subscriptionProvider),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }

    final subscription = subscriptionState.valueOrNull;
    if (subscription == null) return const SizedBox.shrink();

    final plans = ref.watch(billingPlansProvider).valueOrNull ?? const [];
    final left = subscription.ridesLeftLabel(plans, t.unlimited);

    /*
     * OBUNA KARTASI — «a'zolik guvohnomasi».
     *
     * 🔴 Ilgari u OCH PUSHTI (`primaryContainer`) edi va shu ekranda
     * pushti «Tanlash» tugmasi bilan raqobatlashardi: ikkalasi ham
     * bir xil rangda, ya'ni ekranning eng muhim BOSILADIGAN joyi
     * bosilmaydigan ma'lumot kartasi bilan bir xil ko'rinardi
     * («bitta bo'lakda bitta pushti» qoidasi buzilgan edi).
     *
     * Endi u to'q va girih naqshli — safar pasporti bilan bir tilda,
     * pastida atlas jiyagi. Ya'ni bu endi «xabar» emas, HUJJAT.
     */
    final ground = heroSurface(theme);
    final ink = onHeroSurface(theme);
    return Card(
      color: ground,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: GirihPattern(
              cell: 64,
              color: ink.withValues(alpha: 0.09),
              cut: ground,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AtlasEdge(height: 4, scale: 0.55),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined, color: ink),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      t.currentPlan,
                      style: theme.textTheme.titleSmall?.copyWith(color: ink),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                // 🔴 Holat XOM `status` dan OLINMAYDI. Telefonda "Trial ride ·
                // Faol · Amal qiladi: 9 avgust" turardi, o'sha kuni esa 13 avgust
                // edi: backend muddati o'tgan obunaga ham `active` qaytaradi.
                // Hisoblangan holat ishlatiladi — `Subscription.isExpired` sanani
                // ham tekshiradi.
                // 🔴 Paket tugagach ham "Faol" deb turardi (qurilmada ko'rildi
                // 2026-08-13): tepada qizil "Safar paketi tugadi" bannneri,
                // ostida esa "Free trial · Faol" — bir-biriga zid ikki gap.
                // Kvota tugagani tarifning O'ZI tugagani emas, lekin odam uchun
                // muhimi shu, shuning uchun holat shunday aytiladi.
                Text(
                  '${_planLabel(subscription.planName)} · '
                  '${subscription.isExpired ? t.planStatus('expired') : (subscription.ridesLeft == 0 ? t.quotaFinished : t.planStatus(subscription.status))}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '${t.ridesLeft}: $left',
                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                ),
                if (subscription.endDate != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '${t.validUntil}: ${formatDate(subscription.endDate, t.lang)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: ink),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `free_trial` -> `Free trial` (backend obuna jadvalida lowercase saqlaydi).
  static String _planLabel(String planName) {
    if (planName.isEmpty) return '—';
    final words = planName.replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}

class _PlanCard extends ConsumerStatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.paywall,
    this.best = false,
    this.breakEven,
  });

  /// Narx/safar bo'yicha eng foydali tarif — ajratib ko'rsatiladi.
  final bool best;

  /// Cheksiz tarif uchun: nechta safardan keyin va qaysi tarifdan arzon.
  /// Butun RO'YXATga bog'liq, shuning uchun tashqaridan beriladi.
  final ({int rides, String planName})? breakEven;

  final BillingPlan plan;
  final bool paywall;

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  bool _busy = false;

  Future<void> _buy() async {
    final t = AppStrings.of(context);
    final promoCode = await _askPromoCode();
    if (!mounted) return;

    // To'lov oqimidagi uzilishni ko'rish uchun: nechtasi tarifni tanlaydi
    // va nechtasi to'lovni oxiriga yetkazadi.
    ref
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.planPurchaseStarted,
          payload: {'plan': widget.plan.planKey, 'price': widget.plan.price},
        );

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(billingRepositoryProvider)
          .pay(widget.plan.planKey, promoCode: promoCode);
      if (!mounted) return;

      // Obuna o'zgardi — joriy tarif kartasi va profil qayta o'qilsin.
      ref.invalidate(subscriptionProvider);
      ref.invalidate(meProvider);

      if (result.canOpen) {
        final uri = Uri.parse(result.url!);
        // Chiqishdan OLDIN belgilaymiz: Click bizni ilovaga qaytara olmaydi,
        // odam qo'lda qaytadi va o'shanda obuna qayta o'qilishi kerak
        // (`LifecycleRefresh`). Belgilamasak — pul o'tgan, ekranda eski
        // paket turadi va odam "to'lov o'tmadi" deb o'ylaydi.
        ref.read(awaitingExternalFlowProvider.notifier).state = true;
        // Qaytganda AYNAN shu to'lovni so'raymiz (14.09.2026) —
        // «obuna o'zgardimi?» degan taxmin o'rniga.
        ref.read(pendingPaymentProvider.notifier).state = result.transactionId;
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!mounted) return;
        if (!opened) {
          ref.read(awaitingExternalFlowProvider.notifier).state = false;
          showMessage(context, t.paymentOpenFailed);
          return;
        }
        showMessage(context, t.paymentRedirecting);
        return;
      }

      // Mock rejim yoki URL'siz javob — to'lov shu yerda tugadi.
      showMessage(context, result.isMock ? t.paymentMockDone : t.paymentDone);
      if (widget.paywall) Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, t.lang);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Promokod ixtiyoriy — bo'sh qoldirilsa so'rovga UMUMAN qo'shilmaydi.
  Future<String?> _askPromoCode() async {
    final t = AppStrings.of(context);
    final controller = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.promoCodeTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: t.promoCodeHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: Text(t.skip),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(t.continueButton),
          ),
        ],
      ),
    );
    controller.dispose();

    // Dialog yopilsa (null) — sotib olish bekor qilingan emas, promokodsiz davom.
    return (code == null || code.isEmpty) ? null : code;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final plan = widget.plan;
    final subscription = ref.watch(subscriptionProvider).valueOrNull;
    final isCurrent = subscription?.planKey == plan.planKey;

    // Trialni bir marta olgan foydalanuvchiga qayta taklif qilinmaydi —
    // backend baribir rad etadi, tugma esa "ishlamayapti" degan taassurot beradi.
    final trialUsed = plan.isTrial && (subscription?.hasUsedTrial ?? false);

    final quota = plan.isUnlimited ? t.unlimited : '${plan.ridesQuota}';

    /*
     * 🔴 KARTA QAYTA QURILDI (egasi, 2026-08-16: "kardni va ichidagilarini
     * o'zgartirish, UI qo'shish").
     *
     * Ilgari to'rtala karta ham bir xil oq to'rtburchak edi: nom, narx va
     * uchta bir xil "check" belgisi. Solishtirish uchun odam matnni O'QIB
     * chiqishi kerak edi, ko'z esa hech qayerga tushmasdi.
     *
     * Endi:
     *   1. Eng foydali tarif TO'Q fonda (wine-ash), oq matn va turkuaz
     *      aksent bilan. Chegara bilan EMAS: uslub qoidasi — karta
     *      chegarasiz, ajratish rang bilan (`design_system_test` qo'riqlaydi).
     *   2. "1 safar ≈ X so'm" chip ichida — kartaning eng katta va'dasi.
     *   3. Belgilar bir xil "check" emas, har biriga O'Z ikonkasi (mashina,
     *      quti, sozlash) — tariflar farqi bir qarashda ko'rinadi. Yo'q
     *      imkoniyat qulf ikonkasi bilan.
     *   4. Tugmada tarif NOMI ("Pro ni tanlash") — to'rtta bir xil
     *      "Tanlash" tugmasi qaysi kartaniki ekani chalkash edi.
     *
     * Raqamlar HISOBLANADI (narx/paket), o'ylab topilgan maqtov yo'q:
     * "eng mashhur", "1000 haydovchi tanladi", chegirma taymeri —
     * ataylab qo'shilmadi. Ular tez ishlaydi, lekin bir marta ushlansa
     * butun ilovaga bo'lgan ishonch ketadi.
     */
    final perRide = perRidePrice(plan);
    final highlight = widget.best && !isCurrent;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    /*
     * 🔴 AJRATISH USULI TEMAGA QARAB O'ZGARADI.
     *
     * Yorug' rejimda to'q (wine-ash) karta oq fonda darrov ko'zga tashlanadi.
     * Tungi rejimda esa AYNAN SHU usul teskari ishlaydi: to'q karta to'q
     * fonda yo'qoladi va "eng foydali" tarif hech nima bilan ajralmaydi
     * (rasmda ko'rildi). Shuning uchun qorong'ida karta aksincha —
     * YORUG'ROQ, turkuazga bo'yalgan sirt.
     *
     * Chegara qo'shilmaydi: uslub qoidasi — karta chegarasiz, ajratish rang
     * bilan (`design_system_test` buni qo'riqlaydi).
     */
    final highlightBg = isDark
        ? Color.alphaBlend(
            BrandColors.turquoise.withValues(alpha: 0.16),
            scheme.surface,
          )
        : BrandColors.wineAsh;

    // Faqat YORUG' rejimdagi to'q kartada matn oq bo'ladi; tungi rejimda
    // sirt yorug'roq bo'lsa ham matn odatdagidek qoladi.
    final onDarkFill = highlight && !isDark;
    final fg = onDarkFill ? Colors.white : scheme.onSurface;
    final muted = onDarkFill ? Colors.white70 : scheme.onSurfaceVariant;
    /*
     * 🔴 «KIRADI» BELGISI FERUZA, PUSHTI EMAS (2026-09-03 ko'rigi).
     *
     * Tarif kartasida pushti UCH joyda edi: xususiyat ikonkalari,
     * «Batafsil» havolasi va «Tanlash» tugmasi. Odam qaysi biri
     * bosiladigan asosiy amal ekanini rangdan aниqlay olmasdi.
     *
     * Ilovaning o'z qoidasi buni allaqachon aytadi:
     * FERUZA = «bor / yaxshi», PUSHTI = «muhim / asosiy amal».
     * Xususiyat — «bor» degani, ya'ni feruza. Endi kartada pushti
     * faqat tugmada qoladi.
     */
    /// «BOR» BELGISI — xususiyat ikonkalari va nishonlari.
    ///
    /// ⚠️ Temadan olinadi (`secondary`), qotirilgan feruza EMAS:
    /// neon uslubida u cyan, tungi haydashda esa issiq qumrang
    /// bo'lishi kerak — aks holda kartada begona rang paydo bo'ladi.
    final accent = scheme.secondary;

    /// IKKINCHI DARAJALI AMAL («Batafsil») — sokin, neytral.
    ///
    /// ⚠️ Na pushti, na feruza: pushti asosiy tugmaga tegishli,
    /// feruza esa «bor/yaxshi» degan MA'NOni tashiydi va uni
    /// havolaga qo'yish o'sha ma'noni buzadi.
    final linkTone = onDarkFill ? Colors.white : scheme.onSurfaceVariant;

    return Card(
      color: highlight ? highlightBg : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Kartani bosish = tafsilot (egasi, 2026-08-16). Tugma ALOHIDA
        // qoladi: bosish darhol sotib olishga olib bormasligi kerak.
        onTap: () => _PlanDetailsSheet.show(context, plan, perRide),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Nom + nishon =====
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    _PlanBadge(
                      text: t.activePlan,
                      tone: accent,
                      onDark: onDarkFill,
                    )
                  else if (highlight)
                    _PlanBadge(
                      text: t.planPopular,
                      tone: accent,
                      onDark: onDarkFill,
                    )
                  else if (plan.isUnlimited)
                    _PlanBadge(text: t.unlimited, tone: accent),
                ],
              ),
              const SizedBox(height: AppSpace.sm),

              // ===== Narx =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan.price == 0 ? t.free : formatPrice(plan.price),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: fg,
                    ),
                  ),
                  if (plan.price != 0) ...[
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        // 🔴 Backend valyutani "UZS" deb yuboradi va ekranda
                        // "5 000 UZS" chiqardi — ilovaning qolgan joyida esa
                        // narx "60 000 so'm" deb yoziladi (qurilmada ko'rildi
                        // 2026-08-13). Serverning "UZS" i tilga mos so'z bilan
                        // almashtiriladi.
                        '${_currencyLabel(plan.currency, t)} / ${t.perMonth}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // ===== Kartaning eng kuchli dalili =====
              if (perRide != null) ...[
                const SizedBox(height: AppSpace.sm),
                _ValueChip(
                  text: t.perRidePrice(formatPrice(perRide)),
                  tone: accent,
                  onDark: onDarkFill,
                ),
              ] else if (plan.isUnlimited && widget.breakEven != null) ...[
                const SizedBox(height: AppSpace.sm),
                _ValueChip(
                  text: t.unlimitedBreakEven(
                    '${widget.breakEven!.rides}',
                    widget.breakEven!.planName,
                  ),
                  tone: accent,
                  onDark: onDarkFill,
                ),
              ] else if (plan.price == 0) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  t.planFreeHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],

              const SizedBox(height: AppSpace.md),
              Divider(
                height: 1,
                color: onDarkFill ? Colors.white24 : scheme.outlineVariant,
              ),
              const SizedBox(height: AppSpace.md),

              // ===== Nima kiradi =====
              _Feature(
                icon: Icons.directions_car_filled_outlined,
                text: '$quota ${t.featureRides}',
                color: fg,
                accent: accent,
                mutedColor: muted,
              ),
              if (plan.parcelsQuota != 0)
                _Feature(
                  icon: Icons.inventory_2_outlined,
                  text:
                      '${plan.parcelsQuota < 0 ? t.unlimited : plan.parcelsQuota}'
                      ' ${t.featureParcels}',
                  color: fg,
                  accent: accent,
                  mutedColor: muted,
                ),
              // 🔴 Eng katta farq — PREMIUM FILTRLAR: backend ularni faqat Pro
              // va Premium'da o'tkazadi (xat 2026-08-13). Buni yozmasak, odam
              // qimmatroq tarifni nega olishini bilmaydi.
              //
              // Backendning o'z `features` ro'yxati ATAYIN chizilmaydi: u
              // shu faktlarni takrorlaydi, faqat inglizcha va qotirilgan
              // holda (qurilmada ko'rilgan, 2026-08-12).
              _Feature(
                icon: Icons.tune,
                text: t.featureFilters,
                color: fg,
                accent: accent,
                mutedColor: muted,
                enabled: planHasPremiumFilters(plan.planKey),
              ),

              // Kartani bosish mumkinligini AYTIB qo'yamiz: aks holda
              // tafsilot oynasini hech kim topmaydi.
              Row(
                children: [
                  Text(
                    t.planDetails,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: linkTone,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: linkTone),
                ],
              ),

              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: highlight
                      ? FilledButton.styleFrom(
                          backgroundColor: BrandColors.turquoise,
                          foregroundColor: BrandColors.wineAsh,
                        )
                      : null,
                  onPressed: (_busy || isCurrent || trialUsed) ? null : _buy,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isCurrent
                              ? t.activePlan
                              : trialUsed
                              ? t.trialUsed
                              // Bepul tarifda nom qo'shilmaydi: "Free Trial ni
                              // tanlash" g'aliz o'qiladi.
                              : plan.price == 0
                              ? t.choosePlan
                              : t.choosePlanNamed(plan.name),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartaning eng kuchli dalili — to'ldirilgan chip ichida.
///
/// Oddiy matn qatori ko'zga tashlanmasdi: bu raqam kartadagi eng muhim
/// gap, shuning uchun u fon bilan ajratiladi.
class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.text,
    required this.tone,
    required this.onDark,
  });

  final String text;
  final Color tone;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: onDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Tarif imkoniyati — O'Z ikonkasi bilan.
///
/// [enabled] `false` bo'lsa — bu tarifda YO'Q degani (qulf ikonkasi):
/// tariflarni solishtirish uchun "bor"ni ko'rsatishning o'zi yetmaydi.
///
class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.text,
    required this.color,
    required this.accent,
    required this.mutedColor,
    this.enabled = true,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color accent;
  final Color mutedColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = enabled ? accent : mutedColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(enabled ? icon : Icons.lock_outline, size: 18, color: tone),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: enabled ? color : mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.text,
    required this.tone,
    this.onDark = false,
  });

  final String text;
  final Color tone;

  /// To'q kartada fon quyuqroq — aks holda nishon yo'qoladi.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: onDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Backend valyutasini tilga mos so'zga aylantiradi.
///
/// Server "UZS" yuboradi va ekranda "5 000 UZS" chiqardi — ilovaning qolgan
/// joyida esa narx "60 000 so'm" deb yoziladi (qurilmada ko'rildi
/// 2026-08-13). Boshqa valyuta kelsa kodi o'zi ko'rsatiladi.
String _currencyLabel(String? raw, AppStrings t) {
  final code = (raw ?? '').trim().toUpperCase();
  if (code.isEmpty || code == 'UZS' || code == 'SUM') return t.sum;
  return code;
}

/// Tarif tafsiloti — kartani bosganda pastdan ochiladi.
///
/// 🔴 NEGA KERAK (egasi, 2026-08-16: "tariflarni bosganda info ko'rsatsin,
/// batafsil nimalar borligi aytilsin"): kartada joy chegaralangan va u
/// faqat RAQAMLARNI ko'rsatadi — 40 safar, 5 posilka, filtrlar. Lekin
/// odamda paydo bo'ladigan savollar boshqa:
///   • "40 safar" nima degani — balans qachon kamayadi?
///   • "Filtrlar" — aynan qaysilari?
///   • Oy oxirida pul o'zidan yechiladimi?
/// Bu savollarga javob bermasak, odam sotib olishdan qo'rqadi. Karta
/// SOTADI, bu oyna esa ISHONTIRADI.
///
/// Hamma gap HISOBLANGAN yoki kodda mavjud faktdan olinadi: filtrlar
/// ro'yxati `create_ride_screen` da qulflanadigan aynan o'sha to'rttasi,
/// paket izohi esa backend qoidasi.
class _PlanDetailsSheet extends StatelessWidget {
  const _PlanDetailsSheet({required this.plan, required this.perRide});

  final BillingPlan plan;
  final double? perRide;

  static Future<void> show(
    BuildContext context,
    BillingPlan plan,
    double? perRide,
  ) => showModalBottomSheet<void>(
    context: context,
    // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
    // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
    // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
    // qolib, bosib bo'lmaydigan bo'lardi.
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PlanDetailsSheet(plan: plan, perRide: perRide),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final premium = planHasPremiumFilters(plan.planKey);

    // Premium filtrlar — `create_ride_screen._premiumLocked` AYNAN shu
    // to'rttasini qulflaydi. Ro'yxat shu bilan bir joyda turishi kerak:
    // biri o'zgarib, ikkinchisi qolsa oyna yolg'on gapiradi.
    final premiumFilters = [
      (Icons.ac_unit, t.hasAc),
      (Icons.smoke_free, t.noSmoking),
      (Icons.airline_seat_recline_normal, t.maxTwoBack),
      (Icons.speed, t.drivingStyle),
    ];
    // Hamma tarifda ochiq bo'lganlari.
    final freeFilters = [
      (Icons.luggage, t.hasLuggage),
      (Icons.pets, t.noPets),
      (Icons.local_shipping_outlined, t.parcelFilter),
    ];

    return SafeArea(
      // Mazmun surilganda varaqni pastga surib yopish tiklanadi
      // (izohi `SheetDragToClose` da).
      child: SheetDragToClose(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            0,
            AppSpace.lg,
            AppSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    plan.price == 0
                        ? t.free
                        : '${formatPrice(plan.price)} ${_currencyLabel(plan.currency, t)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              if (perRide != null) ...[
                const SizedBox(height: AppSpace.sm),
                _ValueChip(
                  text: t.perRidePrice(formatPrice(perRide!)),
                  tone: scheme.primary,
                  onDark: false,
                ),
              ],

              const SizedBox(height: AppSpace.xl),
              SectionLabel(t.planWhatYouGet),
              InfoBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.isUnlimited
                          ? t.planRidesUnlimited
                          : t.planRidesExplain('${plan.ridesQuota}'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (plan.parcelsQuota != 0) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        t.planParcelsExplain(
                          plan.parcelsQuota < 0
                              ? t.unlimited
                              : '${plan.parcelsQuota}',
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpace.lg),
              SectionLabel(t.planFiltersTitle),
              Text(
                t.planFiltersWhy,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // Shu tarifda ochiladiganlari — qulf yoki belgi bilan.
              Text(
                premium ? t.planFiltersOpenHere : t.planFiltersNeedUpgrade,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: premium ? scheme.primary : scheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              for (final (icon, label) in premiumFilters)
                _DetailFilterRow(icon: icon, label: label, enabled: premium),

              const SizedBox(height: AppSpace.md),
              Text(
                t.planFiltersAlways,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              for (final (icon, label) in freeFilters)
                _DetailFilterRow(icon: icon, label: label, enabled: true),

              const SizedBox(height: AppSpace.lg),
              InfoBox(
                tone: InfoTone.neutral,
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 18,
                      color: scheme.outline,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        t.planPeriodNote,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tafsilot oynasidagi bitta filtr qatori.
class _DetailFilterRow extends StatelessWidget {
  const _DetailFilterRow({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = enabled ? scheme.onSurface : scheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Icon(
            enabled ? icon : Icons.lock_outline,
            size: 18,
            color: enabled ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
