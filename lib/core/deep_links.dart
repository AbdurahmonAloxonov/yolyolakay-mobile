import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/router.dart';

/// Ilovaga tashqaridan kelgan havolalar (deep link).
///
/// Hozircha bitta manzil bor — to'lovdan qaytish:
///   `uz.yolyolakay.mobile://payment/success` (yoki `.../fail`)
///
/// Sxema `applicationId` bilan bir xil (teskari-DNS), shuning uchun uni
/// boshqa ilova o'zlashtirib ololmaydi.
///
/// ✅ MyID callback'i OLIB TASHLANDI (2026-08-22): MyID butunlay
/// chiqarildi, backend `myid_code` ni endi talab qilmaydi.
class DeepLinks {
  DeepLinks(this._router, this._links, this._onPaymentReturn);

  final GoRouter _router;
  final AppLinks _links;

  /// To'lovdan qaytilganda obunani qayta o'qish. Provayderlarga bevosita
  /// bog'lanmaymiz — bu sinf test'da soxta bog'liqliklar bilan quriladi.
  final void Function() _onPaymentReturn;

  StreamSubscription<Uri>? _sub;

  /// Bir xil havolani ikki marta ishlamaslik uchun. `app_links` versiyalari
  /// birinchi havolani goh stream orqali, goh alohida beradi — dublikat bo'lsa
  /// foydalanuvchi ikki marta sakrab ketardi.
  Uri? _handled;

  void start() {
    _sub = _links.uriLinkStream.listen(
      _handle,
      // Deep link ishlamay qolsa ilovaning qolgan qismi baribir ishlashi kerak.
      onError: (_) {},
    );
    unawaited(
      _links
          .getInitialLink()
          .then((uri) {
            if (uri != null) _handle(uri);
          })
          .catchError((_) {}),
    );
  }

  void _handle(Uri uri) {
    if (uri == _handled) return;
    _handled = uri;

    // ULASHILGAN SAYT HAVOLASI (App Links) — `https://yolyolakay.co.uz/...`.
    //
    // 🔴 NEGA (2026-08-25): safarni matn bilan ham, «safar pasporti»
    // rasmi bilan ham ulashamiz va ikkalasida ham sayt havolasi turadi.
    // Uni bosgan do'st BRAUZERDA ochardi — ilovasi bo'lsa ham. Ya'ni
    // ulashish halqasi oxirgi bo'g'inda uzilardi.
    if (uri.scheme == 'https' && uri.host == 'yolyolakay.co.uz') {
      _handleWebLink(uri);
      return;
    }

    if (uri.scheme != 'uz.yolyolakay.mobile') return;

    if (uri.host == 'payment') {
      _handlePayment(uri);
      return;
    }

    // TEZ YO'LLAR — ikonkani bosib turganda chiqadigan menyu
    // (`res/xml/shortcuts.xml`).
    if (uri.host == 'open') {
      switch (uri.pathSegments.firstOrNull) {
        case 'search':
          _router.go(Routes.search);
        case 'create-ride':
          _router.go(Routes.createRide);
        case 'chats':
          _router.go(Routes.chats);
      }
      return;
    }
  }

  /// Sayt havolasi: `/{til}/trip/{id}` va `/{til}/search`.
  ///
  /// ⚠️ Safar ekrani `extra: Ride` kutadi, havolada esa faqat ID bor —
  /// safarni oldindan yuklab bo'lmaydi. Shuning uchun qidiruvga o'tamiz:
  /// bo'sh ekran ko'rsatgandan ko'ra odamni ishlaydigan joyga qo'ygan
  /// yaxshi. Safarni ID bo'yicha ochish `rideByIdProvider` bilan keyingi
  /// qadamda qo'shiladi.
  void _handleWebLink(Uri uri) {
    final segments = uri.pathSegments;
    // Birinchi bo'lak — til prefiksi (`uz`/`ru`/`en`), uni tashlaymiz.
    final rest = segments.length > 1 ? segments.sublist(1) : segments;
    if (rest.isEmpty) return;

    switch (rest.first) {
      case 'trip':
      case 'search':
        _router.go(Routes.search);
      case 'chats':
        _router.go(Routes.chats);
      case 'profile':
        _router.go(Routes.profile);
    }
  }

  /// `uz.yolyolakay.mobile://payment/success` yoki `.../fail`.
  ///
  /// Backend hali bu manzilni Click'ga bermaydi (so'ralgan), lekin qabul
  /// qiluvchi tomon TAYYOR tursin: qo'shilgan kuni oqim ilovani yangilamasdan
  /// ishlab ketadi.
  ///
  /// Natijaga ISHONMAYMIZ — Click qaytargan `success` faqat "brauzer shu
  /// yerga keldi" degani, pul o'tgani emas. Haqiqatni backend biladi,
  /// shuning uchun obunani qayta o'qiymiz va tarif ekraniga o'tamiz;
  /// haqiqiy paket o'sha yerda ko'rinadi.
  void _handlePayment(Uri uri) {
    _onPaymentReturn();
    _router.go(Routes.tariffs);
  }

  void dispose() => _sub?.cancel();
}

/// Test'da o'rniga soxta AppLinks qo'yish uchun alohida ajratilgan.
final appLinksProvider = Provider<AppLinks>((ref) => AppLinks());

/// `app.dart` da bir marta `watch` qilinadi — shu payt kuzatuv boshlanadi.
final deepLinksProvider = Provider<DeepLinks>((ref) {
  final links = DeepLinks(
    ref.watch(routerProvider),
    ref.watch(appLinksProvider),
    () {
      ref.invalidate(subscriptionProvider);
      ref.invalidate(meProvider);
    },
  );
  links.start();
  ref.onDispose(links.dispose);
  return links;
});
