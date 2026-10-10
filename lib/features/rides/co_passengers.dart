import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../shared/ui.dart';

/// HAMROHLAR — safar sahifasida BOSHQA tasdiqlangan yo'lovchilar.
///
/// 🔴 NEGA (raqobat/ayollar, 2026-08-27..09-08): «kim bilan ketaman»
/// eng ko'p so'ralgan narsa edi — ayniqsa ayol yo'lovchi salonda kimlar
/// borligini bilishni istaydi.
///
/// 🔴 MANBA ALMASHTIRILDI (14.09.2026, jonli o'lchov). Ilgari ro'yxat
/// `GET /rides/{id}/passengers` dan olinardi. O'sha endpoint RBAC
/// ostida: mehmonga 401, begonaga 403 va — eng muhimi — bron qilib
/// hali TASDIQLANMAGAN (pending) odamga ham 403. Ya'ni ro'yxat aynan
/// QAROR QILAYOTGAN odamga ko'rinmasdi: safarni ko'rib turgan
/// yo'lovchi salonda kim borligini bilmasdan bron qilishi kerak edi.
/// Xato ekranda ko'rinmasdi (403 → bo'sh ro'yxat → bo'lim chizilmaydi),
/// shuning uchun buni sezish ham qiyin edi.
///
/// Javob esa allaqachon qo'limizda: `GET /rides/{id}` javobining
/// O'ZIDA `passengers[]` bor va u HAMMAGA ochiq. Endi ro'yxat SHU
/// yerdan keladi — qo'shimcha so'rov ham yo'q.
///
/// 🔒 TELEFON KO'RSATILMAYDI. Ochiq safar javobida u begonaga
/// umuman kelmaydi, kelgan holatda ham ko'rsatmaymiz —
/// yo'lovchi-yo'lovchiga telefon ochish maxfiylikka tegadi (egasi
/// qarori 12.09.2026): faqat ism, reyting va jins. Haydovchi
/// bronlarni telefoni bilan o'z ekranida ko'radi.
///
/// ⚠️ FAQAT o'zidan boshqa yo'lovchi bo'lsa chiziladi.
class CoPassengers extends StatelessWidget {
  const CoPassengers({super.key, required this.passengers, this.selfUserId});

  /// Safar javobidagi `passengers[]` — `Ride.passengers`.
  final List<DriverProfile> passengers;

  /// Joriy foydalanuvchi — o'zini ro'yxatdan chiqarish uchun.
  final String? selfUserId;

  @override
  Widget build(BuildContext context) {
    final list = passengers;
    // Bo'sh — hech nima (bu ikkinchi darajali ma'lumot, ekranni
    // to'ldirib turmaydi).
    if (list.isEmpty) return const SizedBox.shrink();

    // O'zini chiqaramiz — «hamrohlar» faqat BOSHQALAR.
    final others = <DriverProfile>[
      for (final p in list)
        if (selfUserId == null || (p.id ?? '') != selfUserId) p,
    ];
    if (others.isEmpty) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(t.coPassengers),
        const SizedBox(height: AppSpace.xs),
        for (final p in others) _CoPassengerTile(profile: p),
      ],
    );
  }
}

class _CoPassengerTile extends StatelessWidget {
  const _CoPassengerTile({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final name = (profile.name ?? '').trim();
    final genderLabel = switch ((profile.gender ?? '').trim().toLowerCase()) {
      'male' => t.male,
      'female' => t.female,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          PersonAvatar(
            url: profile.avatar,
            radius: 18,
            gender: profile.gender,
            seed: profile.id ?? name,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? t.passengers : name,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (genderLabel != null)
                  Text(
                    genderLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          if (profile.rating != null && profile.rating! > 0) ...[
            Icon(Icons.star_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpace.xs),
            Text(
              profile.rating!.toStringAsFixed(1),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
