import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';

/// TO'LOV NATIJASINI AYTADI — taxmin qilmaydi.
///
/// 🔴 NEGA YOZILDI (14.09.2026). Ilgari oqim shunday edi: odam Click'ga
/// chiqib ketadi, qaytadi, biz obunani qayta o'qiymiz va... jim
/// turamiz. To'lov o'tgan bo'lsa yangi paket ko'rinardi (yaxshi), lekin
/// karta rad etilgan bo'lsa odam HECH QANDAY xabar olmasdi: ekranda
/// eski paket, sababi noma'lum. «Pulim ketdimi?» degan savolga
/// ilovada javob yo'q edi.
///
/// Backend 14.09 da `transaction_id` va `GET /billing/transactions/{id}`
/// berdi. Endi qaytishda AYNAN o'sha to'lov so'raladi va uchta javobdan
/// biri aytiladi: o'tdi / o'tmadi / hali ma'lum emas.
///
/// 🔑 «HALI MA'LUM EMAS» ni «O'TDI» deb yozmaymiz. Bank javobi
/// kechikishi mumkin va o'sha holatda tabrik aytish — yolg'on.
///
/// Hech narsa chizmaydi: `child` ni shundoq o'tkazadi.
class PaymentResultWatcher extends ConsumerStatefulWidget {
  const PaymentResultWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PaymentResultWatcher> createState() =>
      _PaymentResultWatcherState();
}

class _PaymentResultWatcherState extends ConsumerState<PaymentResultWatcher> {
  /// 2 soniyada bir, ~40 soniya. Click odatda bir necha soniyada javob
  /// beradi; undan uzoq kutish odamni ekranga mixlab qo'yadi.
  static const _period = Duration(seconds: 2);
  static const _tries = 20;

  Timer? _timer;
  int _count = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Kuzatuvni boshlaydi. Qayta chaqirilsa eskisi bekor qilinadi —
  /// ikki taymer bir vaqtda ishlab, ikki marta xabar bermasin.
  void _start(String id) {
    _timer?.cancel();
    _count = 0;
    showMessage(context, AppStrings.of(context).paymentChecking);
    _timer = Timer.periodic(_period, (_) => unawaited(_poll(id)));
    unawaited(_poll(id));
  }

  Future<void> _poll(String id) async {
    _count++;
    final status = await ref
        .read(billingRepositoryProvider)
        .transactionStatus(id);
    if (!mounted) return;
    final t = AppStrings.of(context);

    // Javob kelmadi (noma'lum id'da backend 500 beradi) — jim davom
    // etamiz, chunki obuna baribir qayta o'qiladi va haqiqiy paket
    // ekranda ko'rinadi.
    if (status != null && status.isFinal) {
      _finish();
      ref.invalidate(subscriptionProvider);
      ref.invalidate(meProvider);
      showMessage(context, status.isPaid ? t.paymentDone : t.paymentFailed);
      return;
    }

    if (_count >= _tries) {
      _finish();
      // Javob umuman kelmagan bo'lsa (`status == null`) ortiqcha gap
      // aytmaymiz — obuna yangilanishi o'zi yetarli signal.
      if (status != null) showMessage(context, t.paymentPending);
    }
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    ref.read(pendingPaymentProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    /*
     * Ikkita signal, bitta natija:
     *   • `pendingPayment` — to'lov boshlandi va id bor;
     *   • `awaitingExternalFlow` false ga tushishi — odam ilovaga
     *     QAYTDI (`LifecycleRefresh` shuni tushiradi).
     *
     * Kuzatuvni qaytishda boshlaymiz: brauzerda turgan odamga so'rov
     * yuborishning ma'nosi yo'q.
     */
    ref.listen<bool>(awaitingExternalFlowProvider, (before, after) {
      if (before == true && after == false) {
        final id = ref.read(pendingPaymentProvider);
        if (id != null && id.isNotEmpty) _start(id);
      }
    });

    return widget.child;
  }
}
