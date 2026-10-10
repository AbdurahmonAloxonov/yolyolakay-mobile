import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/active_role.dart';
import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../data/models/user.dart';
import '../../l10n/strings.dart';
import '../shared/ui.dart';
import 'invite_card.dart';

/// «MENING NARSALARIM» — PROFILDA, sozlamalarda EMAS.
///
/// 🔴 NEGA KO'CHIRILDI (egasi, 18.09.2026): «sozlamalardagi mening
/// narsalarim profilga o'tsin, sozlamalarda turishi g'alati ekan».
/// Va bu haq edi: mashinalarim, tarifim, daromadim — bular sozlama
/// EMAS. Sozlama — ilova QANDAY ishlashi (til, tema, matn o'lchami);
/// bular esa MEN KIMMAN degan savolning javobi, ya'ni profil.
///
/// Odam «mashinam qani?» deb o'ylaganda ⚙️ tugmasini bosmaydi — u
/// o'z profiliga qaraydi. Ilgari esa yo'l aynan ⚙️ orqali edi va bu
/// 2026-09-05 dagi qulaylik tahlilidagi ildiz sababning o'zi:
/// «qayta bezashda narsa ko'chdi, YO'L eski joyda qoldi».
///
/// 🔑 XOTIRA KARTASI va DO'STNI CHAQIRISH ham shu yerga keldi: ular
/// ham sozlama emas, odamning O'Z narsasi. Sozlamalarda faqat ilova
/// xulqi va hisob xavfsizligi qoldi.
///
/// ⚠️ TARIFLAR HAMMAGA ko'rinadi (haydovchi bo'lmaganga ham): paketni
/// haydovchi bo'lishdan OLDIN ko'rish mumkin va saytda ham shunday.
/// Mashinalar va daromad esa faqat HAYDOVCHI REJIMIDA — shart
/// profildagi bilan AYNAN bir xil (rol tanlovi + odam haqiqatan
/// haydovchimi), aks holda yo'lovchida haydovchi qatorlari ochilib
/// ketardi (2026-08-13 da aynan shu xato bo'lgan).
class MyStuffSection extends ConsumerWidget {
  const MyStuffSection({super.key, required this.cars});

  /// Foydalanuvchining mashinalari — qatordagi izoh uchun («3 ta mashina»).
  final List<Car> cars;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final user = ref.watch(meProvider).valueOrNull?.user;
    final driverMode =
        (user?.isDriver ?? false) && ref.watch(isDriverModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(t.sectionMyStuff),
        const SizedBox(height: AppSpace.sm),
        Card(
          child: Column(
            children: [
              if (driverMode) ...[
                ListTile(
                  leading: const Icon(Icons.directions_car_outlined),
                  title: Text(t.myCars),
                  subtitle: Text(
                    cars.isEmpty
                        ? t.noCars
                        : '${cars.length} ${t.carsCountSuffix}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.cars),
                ),
                const Divider(height: 1, indent: 56),
              ],
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(t.tariffsTitle),
                subtitle: const SubscriptionSummary(),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.tariffs),
              ),
              if (driverMode) ...[
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(t.earningsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.earnings),
                ),
              ],
              const Divider(height: 1, indent: 56),
              // Yo'l xotiram — ulashiladigan brend kartasi (suzani muhri).
              ListTile(
                leading: const Icon(Icons.ios_share_outlined),
                title: Text(t.memoryCardTitle),
                subtitle: Text(t.memoryTagline),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.memoryCard),
              ),
              const Divider(height: 1, indent: 56),
              // DO'STNI CHAQIRISH — bazada odam kamligi bugungi eng katta
              // muammo, o'sishning eng arzon kanali esa foydalanuvchining
              // o'zi (izohi `InviteCard` da).
              ListTile(
                leading: const Icon(Icons.group_add_outlined),
                title: Text(t.inviteTitle),
                subtitle: Text(t.inviteSubline),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showInviteCard(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarif qatoridagi izoh: holat va qolgan safar soni.
///
/// ⚠️ Xom `status` EMAS: backend muddati o'tgan obunaga ham `active`
/// qaytaradi (telefonda ko'rilgan, 2026-08-13). `isExpired` sanani ham
/// tekshiradi.
class SubscriptionSummary extends ConsumerWidget {
  const SubscriptionSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final subscription = ref.watch(subscriptionProvider).valueOrNull;
    if (subscription == null) return Text(t.noPlanYet);

    // Cheksizlik TARIF kvotasidan aniqlanadi, `rides_left: -1` dan EMAS
    // (billing.dart izohi). Rejalar hali yuklanmagan bo'lsa — raqam ko'rinadi.
    final plans = ref.watch(billingPlansProvider).valueOrNull ?? const [];
    final left = subscription.ridesLeftLabel(plans, t.unlimited);
    final status = subscription.isExpired ? 'expired' : subscription.status;
    return Text('${t.planStatus(status)} · ${t.ridesLeft}: $left');
  }
}
