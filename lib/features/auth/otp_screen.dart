import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';
import 'otp_code_field.dart';
import '../../core/haptics.dart';
import '../shared/brand/brand_panels.dart';
import '../support/support_entry.dart';

/// Tasdiqlash kodi.
///
/// Muvaffaqiyatdan keyin bu yerda navigatsiya QILINMAYDI — auth holati
/// o'zgaradi va router o'zi ichkariga o'tkazadi (yagona manba).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.newDevice = false,
  });

  final String phoneNumber;

  /// Parol to'g'ri edi, lekin qurilma notanish — kodni backend O'ZI yuborgan.
  /// Bunda ekran ochilganda QAYTA `send-otp` qilinmaydi (ikkinchi SMS bo'lardi).
  final bool newDevice;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  bool _verifying = false;

  /// Kod noto'g'ri kiritildi — `OtpCodeField` qatorni qizartirib bir marta
  /// chayqaydi. Xabar (snackbar) bilan birga ishlaydi: xabar o'qilmasa ham
  /// xato AYNAN kod maydonida ko'rinadi.
  bool _codeError = false;

  /// Kod TO'G'RI chiqdi — maydon yashil yonadi. Sessiya yoqilishidan
  /// oldingi qisqa lahzada ko'rsatiladi (izohi `_verify` da).
  bool _confirmed = false;

  /// Shu ekranda kamida bitta xato bo'ldimi (kod noto'g'ri, qayta
  /// yuborib bo'lmadi, tarmoq uzildi...). Xabar 4 soniyada so'nadi,
  /// yordam havolasi esa shundan keyin ham KO'RINADIGAN bo'lib qoladi —
  /// aynan shu nuqtada odam ilovani tashlab ketardi.
  bool _hadError = false;

  /// `send-otp` daqiqasiga 3 marta — foydalanuvchini limitga urdirmaymiz.
  static const _resendCooldown = 60;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    final t = AppStrings.of(context);
    // Maydon oxirgi raqamda O'ZI chaqiradi — takror chaqiruv ikkinchi
    // `verify-otp` so'rovini yubormasin.
    if (_verifying) return;
    if (_controller.text.length != 5) {
      showMessage(context, t.invalidOtp);
      return;
    }

    setState(() {
      _verifying = true;
      _codeError = false;
    });
    AppHaptics.success(); // kod to'liq — tekshiruv boshlandi

    try {
      final isNewUser = await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(
            widget.phoneNumber,
            _controller.text,
            // 🔴 TASDIQ KO'RINSIN (egasi, 2026-09-07: "shunchaki yashil
            // yonib tekshirishni tasdiqlaydigan qilaylik").
            //
            // Bu kod TO'G'RI ekani ma'lum bo'lgan, lekin sessiya hali
            // yoqilmagan lahza — kataklarni yashil yoqamiz va rang
            // o'tishiga vaqt beramiz. Sessiya yoqilishi bilan router
            // ekranni almashtiradi.
            //
            // ⚠️ ILGARI BU 900 ms EDI va so'rovdan OLDIN turardi — eski
            // mashinali animatsiyaning to'liq uzunligi. Ya'ni har kirish
            // bir soniyaga sekinlashardi, ustiga kod NOTO'G'RI bo'lganda
            // ham «g'alaba» ko'rinardi.
            onVerified: () async {
              if (!mounted) return;
              setState(() => _confirmed = true);
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
          );
      // Yangi hisob: router `needsProfile` bo'yicha O'ZI profil to'ldirish
      // ekraniga olib boradi (`CompleteProfileScreen`) — bu yerda faqat
      // nima uchun boshqa ekran ochilganini aytamiz.
      if (isNewUser && mounted) showMessage(context, t.welcomeFillProfile);
    } catch (error) {
      if (!mounted) return;
      // Kod tozalanadi: noto'g'ri raqamlarni birma-bir o'chirish odamni
      // ortiqcha ovora qiladi va yo'l imorasi ham boshidan boshlanadi.
      _controller.clear();
      // Xato faqat rang bilan bildirilmasin: tebranish + chayqalish.
      AppHaptics.heavy();
      setState(() {
        _codeError = true;
        _confirmed = false;
        _hadError = true;
      });
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendOtp(widget.phoneNumber);
      _startCountdown();
    } catch (error) {
      if (!mounted) return;
      setState(() => _hadError = true);
      showApiError(context, error, ref.read(langProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final canResend = _secondsLeft <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(t.otpTitle), bottom: const JiyakLine()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.xl),
              Text(
                '${t.otpSentTo}: ${widget.phoneNumber}',
                style: theme.textTheme.bodyLarge,
              ),
              if (widget.newDevice) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  t.newDeviceHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.xxl),
              Text(
                t.otpLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              // Kataklar + tasdiq uchun yashil yonish — izohi
              // `otp_code_field.dart` da.
              OtpCodeField(
                controller: _controller,
                length: 5,
                error: _codeError,
                // Kod to'g'ri chiqqanda kataklar yashil yonadi.
                confirmed: _confirmed,
                onChanged: (_) {
                  // Yozishni boshlagan zahoti xato belgisi so'nadi — aks holda
                  // chayqalish har raqamda qayta ishga tushardi.
                  if (_codeError) setState(() => _codeError = false);
                },
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: _verifying || _controller.text.length != 5
                    ? null
                    : _verify,
                child: _verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(t.verify),
              ),
              const SizedBox(height: AppSpace.md),
              TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  canResend ? t.resendCode : '${t.resendIn} ${_secondsLeft}s',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.changeNumber),
              ),
              /*
               * YORDAM — AYNAN SHU EKRANDA (egasi, 22.09.2026).
               *
               * Kod kelmasa yoki qayta-qayta noto'g'ri chiqsa oqim SHU
               * YERDA to'xtaydi: ichkariga ham o'tolmaydi, orqaga qaytish
               * ham yordam bermaydi. Ilgari bu nuqtadan bizga yozishning
               * YO'LI YO'Q edi — «Yordam» ilova ichida, profil ostida
               * turardi.
               *
               * Xatodan keyin havola ko'rinadigan tugmaga aylanadi
               * (`highlight`), chunki sokin kulrang yozuv xato bilan
               * yuzma-yuz qolgan odamning ko'ziga tushmaydi.
               */
              SupportLink(highlight: _codeError || _hadError),
            ],
          ),
        ),
      ),
    );
  }
}
