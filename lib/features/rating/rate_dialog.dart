import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/rating.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';
import '../../core/motion.dart';
import '../shared/brand/suzani_icons.dart';
import '../../core/api/api_exception.dart';
import '../../core/haptics.dart';
import '../../core/outbox.dart';
import '../../app/theme.dart';

/// Baho qo'yish oynasi — haydovchi va yo'lovchi uchun bir xil.
///
/// `true` qaytsa baho yuborildi (chaqiruvchi tugmani yashiradi).
Future<bool> showRateDialog(
  BuildContext context, {
  required String rideId,
  required String revieweeId,
  required String revieweeName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _RateDialog(
      rideId: rideId,
      revieweeId: revieweeId,
      revieweeName: revieweeName,
    ),
  );
  return result == true;
}

class _RateDialog extends ConsumerStatefulWidget {
  const _RateDialog({
    required this.rideId,
    required this.revieweeId,
    required this.revieweeName,
  });

  final String rideId;
  final String revieweeId;
  final String revieweeName;

  @override
  ConsumerState<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends ConsumerState<_RateDialog> {
  final _comment = TextEditingController();

  /// Standart 5 — odatiy holat ijobiy, foydalanuvchi faqat pastroq baho
  /// qo'ymoqchi bo'lsa teginadi.
  int _score = 5;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppStrings.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(ratingRepositoryProvider)
          .submit(
            SubmitFeedbackRequest(
              rideId: widget.rideId,
              revieweeId: widget.revieweeId,
              score: _score,
              comment: _comment.text.trim().isEmpty
                  ? null
                  : _comment.text.trim(),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showMessage(context, t.ratingThanks);
    } on ApiException catch (error) {
      if (!mounted) return;

      /*
       * 🔴 ALOQA YO'Q — BAHO NAVBATGA TUSHADI (2026-08-25).
       *
       * Ilgari bu yerda oddiy xato ko'rsatilardi va odam ikkinchi marta
       * qaytib kelmasdi: baho bir marta beriladigan ish, "keyin beraman"
       * amalda "hech qachon" degani. Safar esa aynan yo'lda tugaydi —
       * ya'ni aloqa eng zaif paytда so'raladi.
       *
       * FAQAT ulanish xatosida navbatga qo'yamiz. Server javob bergan
       * bo'lsa (400/403) — bu qayta urinishdan tuzalmaydi va navbatда
       * abadiy aylanardi, shuning uchun ochiq xato ko'rsatiladi.
       */
      if (error.kind == ApiErrorKind.network) {
        unawaited(
          ref
              .read(outboxProvider)
              .add(
                kind: OutboxKind.rating,
                payload: {
                  'ride_id': widget.rideId,
                  'reviewee_id': widget.revieweeId,
                  'score': _score,
                  'comment': _comment.text.trim().isEmpty
                      ? null
                      : _comment.text.trim(),
                },
              ),
        );
        Navigator.of(context).pop(true);
        showMessage(context, t.ratingQueued);
        return;
      }

      setState(() => _busy = false);
      showApiError(context, error, t.lang);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showApiError(context, error, t.lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(t.rateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.revieweeName, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpace.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: _busy
                      ? null
                      : () {
                          AppHaptics.select();
                          setState(() => _score = star);
                        },
                  tooltip: '$star',
                  icon: AnimatedScale(
                    // Tanlangan eng baland yulduz "sakraydi" (elasticOut),
                    // reduce-motion'да tinch turadi.
                    scale: (AppMotion.on(context) && star == _score)
                        ? 1.28
                        : 1.0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.elasticOut,
                    // Suzani yulduzi — sakkiz nurli an'anaviy naqsh.
                    // Baholash — odam ilovada eng ko'p "his qiladigan"
                    // lahza; besh burchakli stok yulduz uni har qanday
                    // boshqa ilovadagidek qilib qo'yardi.
                    child: SuzaniIconWidget(
                      SuzaniIcon.star,
                      filled: star <= _score,
                      size: 32,
                      color: BrandColors.star,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Center(
            child: Text(
              t.scoreLabel(_score),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _comment,
            enabled: !_busy,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: t.commentOptional,
              hintText: t.commentHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.sendRating),
        ),
      ],
    );
  }
}
