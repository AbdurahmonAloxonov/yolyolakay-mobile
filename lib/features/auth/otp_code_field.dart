import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/dimens.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../l10n/strings.dart';

/// SMS kodini kiritish — beshta katak va tasdiq uchun YASHIL yonish.
///
/// 🔴 NEGA SODDALASHTIRILDI (egasi, 2026-09-07: "otp animationni oddiy qilib
/// shunchaki yashil yonib tekshirishni tasdiqlaydigan qilaylik, hozirgi
/// animation qotib qotib ishlayapti").
///
/// Bundan oldin bu yerda `OtpRoadField` turardi: kataklar ostida punktir
/// yo'l, unda yuradigan mashina, tekshiruv paytida esa kataklarni "devor"
/// deb buzib o'tadigan katta mashina, uchib chiqadigan parchalar va egzoz
/// tutuni. U HAR KADRDA qayta chizilardi:
///   • `_WallDebrisPainter` — 5 katak × 11 parcha = 55 ta aylantirilgan
///     to'rtburchak, har kadrda `save/rotate/drawRect/restore`;
///   • olti dona `_Puff` bulut va `_BigCar` — har kadrda qayta quriladi;
///   • `AnimatedBuilder` butun daraxtni (jumladan `LayoutBuilder` va
///     `TextField` ni) 850 ms davomida har kadrda qayta qurardi.
/// Kuchsizroq telefonda bu kadr tushirardi — «qotib qotib» ko'rinishning
/// sababi shu. Ustiga ekran tasdiqlashdan OLDIN animatsiyaga 900 ms
/// ataylab kutardi, ya'ni kirish har safar bir soniyaga sekinlashardi.
///
/// ENDI: hech qanday har kadrli chizish yo'q. Kod TO'G'RI ekani ma'lum
/// bo'lgach kataklar YASHILGA o'tadi (bitta `AnimatedContainer`, 200 ms)
/// va ostida yashil tasdiq belgisi chiqadi. Xato bo'lsa qator qizarib bir
/// marta chayqaladi.
///
/// 🔑 NEGA YASHIL: `BrandColors.success` ilovada «tekshirildi va joyida»
/// degan yagona rang (ishonch narvoni, safar oldi ro'yxati). Brend feruzasi
/// «bor» degani — tasdiq uchun ishlatilmaydi.
///
/// ⚠️ YASHIL FAQAT BELGI VA CHEGARADA, YOZUVDA EMAS: #1FA971 oq zaminda
/// 3.05:1 beradi. Bu ikonka/chegara uchun yetarli (kerak 3:1), lekin mayda
/// YOZUV uchun yetmaydi (kerak 4.5:1). Shuning uchun «Tekshirilmoqda»
/// yozuvi va kataklardagi raqamlar oddiy matn rangida qoladi — 2026-09-04
/// dagi kontrast tuzatishini qaytarib buzmaslik uchun.
///
/// ⚠️ Xato FAQAT rang bilan bildirilmaydi: qizarish bilan birga chayqalish
/// va `heavy` tebranish ham beriladi, shunda rangni ajratmaydigan odam ham
/// sezadi. «Harakatni kamaytir» yoqilgan bo'lsa chayqalish o'chadi —
/// qizarish va tebranish qoladi.
///
/// TUZILISHI: ko'rinadigan kataklar CHIZILGAN, matn esa bitta yashirin
/// `TextField` da turadi. Beshta alohida maydon EMAS: ular fokusni
/// bir-biriga uzatib yuradi va o'chirish (backspace) har doim chalkashardi;
/// bitta maydon esa nusxa-joylashtirishni ham, klaviaturadagi "kodni
/// avtomatik to'ldirish" taklifini ham buzmasdan qabul qiladi.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 5,
    this.error = false,
    this.confirmed = false,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;

  /// Kod noto'g'ri — qator qizaradi va bir marta chayqaladi.
  final bool error;

  /// Kod TO'G'RI chiqdi — kataklar yashil yonadi va tasdiq belgisi chiqadi.
  ///
  /// 🔑 TEKSHIRUV PAYTIDA EMAS, JAVOBDAN KEYIN: yashil «tasdiqlandi»
  /// degani. So'rov ketayotganda yoqsak, kod noto'g'ri chiqqan holatda
  /// maydon avval yashil, keyin qizil bo'lardi — ya'ni bir lahza YOLG'ON
  /// gapirardi. Kutish paytining belgisi tugmadagi aylanma.
  final bool confirmed;

  final ValueChanged<String>? onChanged;

  /// Oxirgi raqam kiritilganda — tasdiqlashni o'zi boshlash uchun.
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  static const _cellHeight = 56.0;
  static const _gap = AppSpace.md;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    // Faol katakning chegarasi fokusga bog'liq — fokus o'zgarganda ham
    // qayta chizilishi kerak (ilgari faqat matn o'zgarganda chizilardi va
    // klaviatura yopilganda katak faol bo'lib qolaverardi).
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant OtpCodeField old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    // Xato YANGI kelganda bir marta chayqaymiz (har chizishda emas).
    if (widget.error && !old.error && AppMotion.on(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.removeListener(_onFocus);
    _shake.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  void _onText() {
    setState(() {});
    final text = widget.controller.text;
    widget.onChanged?.call(text);
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppStrings.of(context);
    final text = widget.controller.text;
    final filled = text.length.clamp(0, widget.length);
    // Tasdiq: javob kelди va kod to'g'ri.
    final confirming = widget.confirmed && !widget.error;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // Bir marta chapga-o'ngga tebranadi va joyiga qaytadi.
        final v = _shake.value;
        final dx = v == 0 ? 0.0 : 8 * (1 - v) * math.sin(v * 3 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      // 🔴 BOSILADIGAN MAYDONNING NOMI BO'LSIN (2026-09-04, o'lchandi).
      // Katakchalar ustidagi bu keng maydon butun kod maydonini fokuslash
      // uchun turadi, lekin ekran o'qigichga u shunchaki «bosiladi» bo'lib
      // eshitilardi — nima bosilayotgani nomsiz edi.
      child: Semantics(
        label: t.enterCodeField,
        child: GestureDetector(
          onTap: () => _focus.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _cellHeight,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < widget.length; i++) ...[
                          if (i > 0) const SizedBox(width: _gap),
                          Expanded(
                            child: _Cell(
                              char: i < text.length ? text[i] : '',
                              active: i == filled && _focus.hasFocus,
                              error: widget.error,
                              confirming: confirming,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Yashirin maydon — haqiqiy matn shu yerda turadi.
                    // `Opacity(0)` EMAS, `Offstage` ham EMAS: klaviatura
                    // ochilishi uchun maydon daraxtda va o'lchamli bo'lishi
                    // kerak, faqat KO'RINMASLIGI kerak.
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focus,
                          autofocus: true,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 1),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(widget.length),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== TASDIQ BELGISI =====
              // Kataklar yashil yonganda ostida yashil belgi va yozuv
              // chiqadi. Balandlik DOIM band — belgi paydo bo'lganda
              // ostidagi tugma sakramasin.
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                height: 20,
                child: AnimatedOpacity(
                  duration: AppMotion.on(context)
                      ? const Duration(milliseconds: 200)
                      : Duration.zero,
                  opacity: confirming ? 1 : 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: BrandColors.success,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(t.otpConfirmed, style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== Bitta katak =====
class _Cell extends StatelessWidget {
  const _Cell({
    required this.char,
    required this.active,
    required this.error,
    required this.confirming,
  });

  final String char;
  final bool active;
  final bool error;

  /// Kod tekshirilmoqda — katak yashil yonadi.
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = char.isNotEmpty;

    final border = error
        ? theme.colorScheme.error
        : confirming
        ? BrandColors.success
        : filled || active
        ? theme.colorScheme.primary
        // Ilovada ingichka chegara HAMMA joyda `outlineVariant`.
        : theme.colorScheme.outlineVariant;

    return AnimatedContainer(
      duration: AppMotion.on(context)
          ? const Duration(milliseconds: 200)
          : Duration.zero,
      decoration: BoxDecoration(
        // Yashil yonish: chegara + juda yengil zamin. Zamin to'q temada ham
        // ishlashi uchun shaffoflik bilan beriladi, qotirilgan rang bilan
        // emas.
        color: confirming
            ? BrandColors.success.withValues(alpha: 0.10)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: border,
          width: filled || active || confirming ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: filled
          ? Text(
              char,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
