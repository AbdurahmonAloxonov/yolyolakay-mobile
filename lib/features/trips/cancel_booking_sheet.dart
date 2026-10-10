import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/haptics.dart';
import '../../data/models/booking.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';

/// BRONNI BEKOR QILISH — yo'lovchi tomonidan, HAQIQATAN.
///
/// 🔴 TARIXI (bu yerdagi tanlovlarni tushunish uchun muhim): 2026-08-25 da
/// gateway'da yo'lovchi uchun bekor qilish ruchkasi UMUMAN yo'q edi — faqat
/// `.../bookings/{id}/reject` (HAYDOVCHI rad etadi) va `rides/{id}/cancel`
/// (haydovchi safarni bekor qiladi). Shuning uchun biz ATAYIN "so'rov"
/// yasagandik: haydovchiga tuzilgan chat xabari ketardi, bron esa mahalliy
/// bayroq bilan «bekor qilish so'raldi» deb belgilanardi. Yolg'on tugma
/// qo'ymaslik uchun shunday qilingandi.
///
/// ✅ 2026-08-27: backend `POST /rides/{id}/bookings/{booking_id}/cancel`
/// ni ochdi (jonli sxema bilan sverka qilindi, `reason` ixtiyoriy). Endi
/// bekor qilish HAQIQIY: o'rindiq darhol bo'shaydi va haydovchining
/// tasdig'i kutilmaydi. Mahalliy «so'raldi» bayrog'i ham keraksiz bo'ldi.
///
/// ⚠️ NEGA BU OFFLINE NAVBATGA (`core/outbox.dart`) QO'YILMADI — chat va
/// bahodan farqli o'laroq bu QAYTARIB BO'LMAYDIGAN amal. Navbatga qo'ysak,
/// odam «bekor qilindi» degan yozuvni ko'rib ketardi, so'rov esa soatlar
/// keyin — masalan haydovchi allaqachon jo'nab ketganda — ketardi. Aloqa
/// yo'q bo'lsa halol xato ko'rsatgan afzal.
Future<bool> showCancelBookingSheet(
  BuildContext context, {
  required Booking booking,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CancelBookingSheet(booking: booking),
  );
  return result ?? false;
}

class _CancelBookingSheet extends ConsumerStatefulWidget {
  const _CancelBookingSheet({required this.booking});

  final Booking booking;

  @override
  ConsumerState<_CancelBookingSheet> createState() =>
      _CancelBookingSheetState();
}

class _CancelBookingSheetState extends ConsumerState<_CancelBookingSheet> {
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final t = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    try {
      await ref
          .read(ridesRepositoryProvider)
          .cancelBooking(
            widget.booking.rideId,
            widget.booking.id,
            reason: _reason.text.trim(),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHaptics.notice();
      showApiError(context, e, t.lang);
      return;
    }

    if (!mounted) return;
    AppHaptics.success();
    navigator.pop(true);
    messenger.showSnackBar(SnackBar(content: Text(t.cancelBookingDone)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpace.lg,
        right: AppSpace.lg,
        top: AppSpace.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cancelBookingTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.sm),

          // 🔴 OQIBATI OLDIN aytiladi: nechta o'rindiq bo'shashi va buni
          // qaytarib bo'lmasligi. Ilgari bu quti «bu faqat so'rov» deb
          // ogohlantirardi — endi teskarisi rost.
          InfoBox(
            tone: InfoTone.warning,
            child: Text(
              t.cancelBookingExplain(widget.booking.seatsBooked),
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpace.md),

          TextField(
            controller: _reason,
            maxLines: 2,
            enabled: !_busy,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: t.cancelBookingReason,
              hintText: t.cancelBookingReasonHint,
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _cancel,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.event_busy_outlined, size: 18),
              label: Text(t.cancelBookingConfirm),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: Text(t.cancelBookingKeep),
            ),
          ),
        ],
      ),
    );
  }
}
