import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../data/models/user.dart';
import '../../l10n/strings.dart';

/// PROFIL TO'LIQLIGI — nima yetishmayotgani va NEGA muhimligi.
///
/// 🔴 NEGA (2026-08-25 auditi): ilovada hech qanday ko'rsatkich yo'q edi.
/// Rasmsiz va familiyasiz profil bron olishi qiyin — haydovchi
/// «bu kim?» deb rad etadi. Lekin odam buni BILMAYDI: ilova unga hech
/// nima demaydi, u esa «nega meni qabul qilishmayapti?» deb o'ylaydi.
///
/// ⚠️ FOIZ O'ZI MAQSAD EMAS. Ro'yxatda faqat HAQIQATAN ta'sir qiladigan
/// narsalar bor va har biri yonida SABABI yozilgan. «Profilingizni
/// 100% qiling» degan bo'sh o'yin emas — «surat qo'ysangiz bron
/// qabul qilinishi osonlashadi» degan aniq gap.
///
/// To'liq bo'lsa karta UMUMAN chizilmaydi: bajarilgan ishni har kuni
/// ko'rsatib turish — shovqin.
class ProfileCompleteness extends StatelessWidget {
  const ProfileCompleteness({
    super.key,
    required this.user,
    required this.hasCar,
    required this.onAvatar,
    required this.onName,
    required this.onCar,
  });

  final User user;

  /// Haydovchi uchun mashina ham hisobga olinadi.
  final bool hasCar;

  final VoidCallback onAvatar;
  final VoidCallback onName;
  final VoidCallback onCar;

  bool get _isDriver => (user.role ?? '').toLowerCase() == 'driver';

  /// Yetishmayotganlar — tartib MUHIMLIK bo'yicha.
  List<_Gap> _gaps(AppStrings t) => [
    if ((user.avatarUrl ?? '').isEmpty)
      _Gap(
        icon: Icons.photo_camera_outlined,
        label: t.completenessAvatar,
        why: t.completenessAvatarWhy,
        onTap: onAvatar,
      ),
    if ((user.lastName ?? '').trim().isEmpty)
      _Gap(
        icon: Icons.badge_outlined,
        label: t.completenessName,
        why: t.completenessNameWhy,
        onTap: onName,
      ),
    if (_isDriver && !hasCar)
      _Gap(
        icon: Icons.directions_car_outlined,
        label: t.completenessCar,
        why: t.completenessCarWhy,
        onTap: onCar,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final gaps = _gaps(t);

    // Bajarilgan ishni har kuni ko'rsatib turish — shovqin.
    if (gaps.isEmpty) return const SizedBox.shrink();

    // Jami band soni: yo'lovchida 2, haydovchida 3.
    final total = _isDriver ? 3 : 2;
    final done = total - gaps.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.completenessTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  '$done/$total',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.badge),
              child: LinearProgressIndicator(value: done / total, minHeight: 6),
            ),
            const SizedBox(height: AppSpace.md),
            for (final gap in gaps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(gap.icon, color: theme.colorScheme.primary),
                title: Text(gap.label),
                // SABAB — bandning o'zidan muhimroq. Usiz bu shunchaki
                // «to'ldiring» degan buyruq bo'lardi.
                subtitle: Text(gap.why),
                trailing: const Icon(Icons.chevron_right),
                onTap: gap.onTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _Gap {
  const _Gap({
    required this.icon,
    required this.label,
    required this.why,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String why;
  final VoidCallback onTap;
}
