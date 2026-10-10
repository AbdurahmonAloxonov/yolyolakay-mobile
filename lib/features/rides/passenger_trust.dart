import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';

/// YO'LOVCHI HAQIDA HAYDOVCHIGA — «kimni olayapman».
///
/// 🔴 NEGA KERAK (raqobat tahlili, 2026-08-27): Yoldosh haydovchini HAM,
/// yo'lovchini HAM tasdiqlashini ochiq reklama qiladi. Bizda haydovchi
/// bron kartasida faqat ism, avatar va reyting ko'rardi — yangi
/// akkauntda esa reyting ham yo'q, ya'ni kartada odam haqida AYTADIGAN
/// hech narsa qolmasdi.
///
/// ✅ 2026-08-27 (kechqurun): backend `PassengerProfile` ga `kyc_status`
/// va `created_at` ni QO'SHDI — biz aynan shuni so'ragandik. Ya'ni odatda
/// ma'lumot BRONNING O'ZIDA keladi va qo'shimcha so'rov KETMAYDI.
///
/// ⚠️ `GET /users/{id}` zaxira sifatida QOLDIRILDI: offline keshdagi eski
/// javoblarda bu maydonlar yo'q va ular yangilanmaguncha nishon jimgina
/// yo'qolib turardi. Zaxira faqat maydonlar YETISHMAGANDA ishga tushadi.
///
/// ⚠️ TASDIQLANMAGANDA HECH NIMA CHIZILMAYDI. Qizil «tasdiqlanmagan»
/// yozuvi AYBLOV bo'lardi: bizda yo'lovchi uchun tekshiruv oqimi umuman
/// yo'q, ya'ni odam uni O'TA OLMAYDI ham. Yo'qlik dalil emas.
class PassengerTrust extends ConsumerWidget {
  const PassengerTrust({super.key, required this.userId, this.profile});

  final String userId;

  /// Bronga biriktirilgan profil — bo'lsa, so'rov umuman qilinmaydi.
  final DriverProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // Bronda kelgan ma'lumot YETARLI bo'lsa — tarmoqqa umuman chiqmaymiz.
    final embedded = profile;
    final hasEmbedded =
        embedded != null &&
        (embedded.kycStatus != null || embedded.createdAt != null);

    final bool approved;
    final DateTime? created;
    if (hasEmbedded) {
      approved = embedded.isKycApproved;
      created = embedded.createdAt;
    } else {
      final user = ref.watch(userByIdProvider(userId)).valueOrNull;
      if (user == null) return const SizedBox.shrink();
      approved = user.isKycApproved;
      created = user.createdAt;
    }

    final chips = <Widget>[
      if (approved)
        _Chip(
          icon: Icons.verified_user_outlined,
          label: t.passengerVerified,
          tone: theme.colorScheme.primary,
        ),
      if (created != null)
        _Chip(
          icon: Icons.schedule_outlined,
          label: t.memberSinceYear(created.year),
          tone: theme.colorScheme.outline,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      // `Wrap` SHART: tor ekranda (400 px) ikki chip bitta qatorga
      // sig'masligi mumkin va bu kartada toshish tarixi BOR.
      child: Wrap(
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        children: chips,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.tone});

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tone.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: AppSpace.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
