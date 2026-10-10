import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/voice_route.dart';
import '../../l10n/strings.dart';
import '../shared/voice_listen_button.dart';

/// OVOZ BILAN YO'NALISH AYTISH — "Toshkentdan Samarqandga".
///
/// 🔴 NEGA KERAK: shahar nomini yozish keksa foydalanuvchi uchun to'siq —
/// klaviatura tili, lotin/kirill, apostrof (`Farg'ona`). Aytish esa tabiiy.
///
/// 🔴 SAYTDAGI XATO SHU YERDA TAKRORLANMAYDI (egasi, 2026-08-24): u yerda
/// tugma faqat JO'NASH joyini to'ldirardi, aytilgan gapning yarmi tashlab
/// ketilardi. Bu yerda bitta gapdan ikkala joy ajratiladi
/// (`core/voice_route.dart`) — tahlil qoidasi ikkala mijozda bir xil.
///
/// ⚠️ Nutqni tanishning O'ZI `VoiceListenButton` da (2026-08-25 da
/// ajratildi): e'lon berish ham xuddi shu mexanizmga muhtoj bo'ldi va uni
/// ko'chirish ikkita manba yaratardi.
class VoiceRouteButton extends StatelessWidget {
  const VoiceRouteButton({super.key, required this.onRoute, this.onRawText});

  /// Yo'nalish tanilganda. `from` yoki `to` alohida `null` bo'lishi mumkin.
  final void Function(VoiceRoute route) onRoute;

  /// Bitta ham joy tanilmaganda — xom matn. Berilmasa, hech nima qilinmaydi.
  ///
  /// Chaqiruvchi buni ro'yxat filtriga qo'yishi mumkin: odam nimadir aytdi,
  /// ilova esa jim qolmasin.
  final void Function(String text)? onRawText;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return VoiceListenButton(
      hint: t.voiceRouteHint,
      onResult: (text) {
        final route = parseVoiceRoute(text);
        if (route == null || route.isEmpty) {
          onRawText?.call(text);
          return;
        }
        AppHaptics.success();
        onRoute(route);
      },
    );
  }
}
