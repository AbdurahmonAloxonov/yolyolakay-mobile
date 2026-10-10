import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../l10n/strings.dart';
import '../../l10n/cyrillic.dart';

/// SANA LENTASI — natijalar tepasidagi kunlar qatori, har kunning tagida
/// SHU YO'NALISHDA topilgan safarlar soni.
///
/// 🔴 NEGA KERAK (2026-08-24 auditi): sana o'zgartirish uchun odam orqaga
/// qaytib, formani ochib, kalendarni chaqirib, kun tanlab, qayta qidirishi
/// kerak edi — besh harakat. Va eng yomoni: u tanlagunicha o'sha kunda
/// safar bor-yo'qligini BILMASDI, ya'ni ko'pincha bo'sh ekranga tushardi.
///
/// Endi son OLDINDAN ko'rinadi: «ertaga 12, payshanba 3, juma yo'q».
/// Odam bo'sh kunga umuman bosmaydi.
///
/// ⚠️ Son TO'QIB CHIQARILMAYDI — u bitta sanasiz qidiruvdan sanaladi
/// (`ridesPerDayProvider`). Ma'lumot kelmaguncha lenta CHIZILMAYDI: nol
/// ko'rsatib "bu kunda safar yo'q" deb aldash — eng yomon variant.
class DateStrip extends ConsumerWidget {
  const DateStrip({super.key, required this.onPick});

  /// Kun bosilganda — qidiruvni shu sanada qayta yugurtiradi.
  final void Function(DateTime day) onPick;

  /// Lentada nechta kun ko'rsatiladi (bugundan boshlab).
  ///
  /// 14 — ikki hafta: safar odatda shu oraliqda rejalashtiriladi va
  /// undan uzog'ida e'lon deyarli bo'lmaydi.
  static const _days = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(ridesPerDayProvider).valueOrNull;
    // Yuklanmaguncha yo'q — sakrab turadigan skelet ro'yxatni pastga
    // suradi va odam bosayotgan kartochkasini yo'qotadi.
    if (counts == null || counts.isEmpty) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final params = ref.watch(searchControllerProvider.notifier).lastParams;
    final chosen = params?.date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      // 🔴 Balandlik uch qatorga MO'LJALLANGAN edi va 62 px da toshib
      // ketardi (sinovda topildi) — tizim shrifti kattalashtirilgan
      // telefonda esa battar. Endi kartochka IKKI qatorli ("Se 12" va
      // son), balandlik esa shrift kattaligiga qarab o'sadi.
      height:
          40 + 26 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        itemCount: _days,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final day = today.add(Duration(days: index));
          return _DayChip(
            day: day,
            count: counts[day] ?? 0,
            selected:
                chosen != null &&
                chosen.year == day.year &&
                chosen.month == day.month &&
                chosen.day == day.day,
            label: _weekday(day, t.lang),
            onTap: () {
              AppHaptics.select();
              onPick(day);
            },
          );
        },
      ),
    );
  }

  /// Hafta kuni — qisqa shaklda. `intl` ning `DateFormat.E` ATAYIN
  /// ishlatilmadi: o'zbekcha lokal unda to'liq emas va ba'zi qurilmada
  /// inglizcha "Mon" chiqadi.
  static String _weekday(DateTime day, Lang lang) {
    const uz = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final i = day.weekday - 1;
    return switch (lang) {
      Lang.uz => uz[i],
      Lang.uzCyrl => toCyrillic(uz[i]),
      Lang.ru => ru[i],
      Lang.en => en[i],
    };
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.count,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final DateTime day;
  final int count;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final empty = count == 0;

    // Bo'sh kun BOSILMAYDI. Ilgari (chiplarda) bosish mumkin edi va odam
    // bo'sh ekranga tushardi — son ko'rsatib turib, keyin baribir bo'sh
    // natija berish ishonchni yo'qotadi.
    final color = selected
        ? scheme.primary
        : empty
        ? scheme.surfaceContainerHighest
        : scheme.secondaryContainer;
    final onColor = selected
        ? scheme.onPrimary
        : empty
        ? scheme.outline
        : scheme.onSecondaryContainer;

    return Semantics(
      button: !empty,
      selected: selected,
      // Ekran o'quvchisi uchun: "12-avgust, 3 safar". Raqamlar alohida
      // o'qilsa ("Se", "12", "3") ma'nosi yo'qoladi.
      label: '${formatDate(day, AppStrings.of(context).lang)}, $count',
      excludeSemantics: true,
      child: Opacity(
        opacity: empty ? 0.55 : 1,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            onTap: empty ? null : onTap,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: Container(
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hafta kuni va sana BITTA qatorda: uchta alohida qator
                  // kartochkani balandlashtirardi va lenta ro'yxatdan
                  // ko'p joy yeb qo'yardi. `FittedBox` — inglizchada
                  // "Wed 12" uzunroq, u siqilib sig'sin.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$label ${day.day}',
                      maxLines: 1,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    // Bo'sh kunda "0" emas, chiziqcha: nol raqami
                    // "hisoblanmadi" degan taassurot beradi.
                    empty ? '—' : '$count',
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
