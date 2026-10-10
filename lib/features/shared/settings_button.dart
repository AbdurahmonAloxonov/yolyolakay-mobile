import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../l10n/strings.dart';

/// ⚙️ Sozlamalar tugmasi — har bir asosiy tabning yuqori qatorida.
///
/// 🔴 NEGA (2026-09-05, egasi aytdi): sozlamalar 02.09 da profildan
/// ajratilgandan keyin ularga YAGONA yo'l profil tabi bo'lib qoldi.
/// Ya'ni "Safarlarim" da turgan odam tilni yoki temani o'zgartirish
/// uchun avval profilga o'tishi, keyin ⚙️ ni topishi kerak edi —
/// ikki bosish, va ikkinchisi ko'rinmas.
///
/// Bu AYNAN o'sha xato bo'lib chiqdi: qo'ng'iroqcha ham bir paytlar
/// faqat qidiruvda edi va shu sababdan umumiy vidjetga ajratilgan edi
/// (izohi `NotificationBell` da). Endi ikkalasi yonma-yon yuradi.
///
/// 🔑 `push` — `go` EMAS. `go` butun stekni almashtiradi va sozlamadan
/// chiqqan odam qaysi tabdan kirgan bo'lsa ham qidiruvga tushib
/// qolardi. `push` bilan "orqaga" AYNAN BIR QADAM qaytaradi: qaysi
/// tabdan kirilgan bo'lsa, o'shanga. Sozlamalar shell'dan TASHQARIDAGI
/// yo'l bo'lgani uchun (izohi `router.dart` da) u ildiz navigatoriga
/// qo'yiladi va pastki tab qatori bilan poyga qilmaydi.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.of(context).settingsTitle,
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push(Routes.settings),
    );
  }
}
