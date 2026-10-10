import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/haptics.dart';
import '../../core/local_flags.dart';
import '../../core/share_safely.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../shared/ui.dart';

/// «YETIB KELDIM» — safar tugagach yaqiniga xabar.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): safar oldidan
/// «Safarimni kuzat» xabari BOR edi (`ride_share.dart` dagi
/// `shareTripWatch`) — onasi yoki turmush o'rtog'i kim bilan va qayerga
/// ketayotganini biladi. Lekin ZANJIRNING OXIRI yo'q edi: yetib
/// kelganини hech kim aytmasdi va u odam kechgacha xavotirda qolardi.
/// Amalda bu qo'ng'iroq bilan hal qilinadi, ko'pincha esa umuman
/// unutiladi.
///
/// ═══ NEGA SMS EMAS (egasi aniq aytdi, 2026-08-25) ═══
///
/// SMS ishlatilmaydi. Push esa hozircha backenddan KELMAYDI (mijozda
/// butun zanjir tayyor, o'lchab tekshirilgan — xat
/// `BACKEND_XAT_BEKOR_VA_PUSH_2026-08-25.txt`).
///
/// Ya'ni bugun boshqa odamning telefoniga BIZ o'zimiz yeta olmaymiz.
/// Shuning uchun bu yerda YOLG'ON avtomatika yo'q: ilova xabarni
/// TAYYORLAB beradi va odam uni bir tegishда yuboradi (Telegram,
/// WhatsApp — o'zi tanlaydi). Push yoqilgach shu joyning o'zi avtomatik
/// yuborishga o'tadi, ekran o'zgarmaydi.
///
/// ⚠️ Karta FAQAT safar tugagach va FAQAT bir marta chiqadi: yuborilgani
/// belgilanadi (`core/local_flags.dart`), aks holda u har ochilganda
/// qayta so'rab, bezor qilardi.
class ArrivalNotice extends ConsumerStatefulWidget {
  const ArrivalNotice({super.key, required this.ride});

  final Ride ride;

  @override
  ConsumerState<ArrivalNotice> createState() => _ArrivalNoticeState();
}

class _ArrivalNoticeState extends ConsumerState<ArrivalNotice> {
  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    // Safar tugamagan bo'lsa «yetib keldim» degan gap yolg'on bo'lardi.
    if (ride.status != RideStatus.completed) return const SizedBox.shrink();

    final flags = ref.watch(localFlagsProvider);
    final key = LocalFlags.arrivalSent(ride.id);
    if (flags.has(key)) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: InfoBox(
        tone: InfoTone.positive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.arrivalTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(t.arrivalHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _send(t),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(t.arrivalSend),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                // «Kerak emas» — karta bezor qilmasin. Bosilsa ham
                // belgilanadi va boshqa chiqmaydi.
                TextButton(onPressed: () => _dismiss(), child: Text(t.close)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(AppStrings t) async {
    AppHaptics.select();
    final ride = widget.ride;
    final destination = ride.destinationAddress.trim();
    final text = destination.isEmpty
        ? t.arrivalMessage
        : t.arrivalMessageAt(destination);
    await shareSafely(context, ShareParams(text: text));
    await _dismiss();
  }

  Future<void> _dismiss() async {
    await ref
        .read(localFlagsProvider)
        .set(LocalFlags.arrivalSent(widget.ride.id));
    if (mounted) setState(() {});
  }
}
