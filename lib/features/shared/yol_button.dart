import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/haptics.dart';
import '../../core/motion.dart';
import 'brand/loom_loader.dart';

/// ASOSIY TUGMA — ilovaning eng ko'p bosiladigan yuzasi.
///
/// 🔴 NEGA YOZILDI (egasi, 18.09.2026: «tugmalarga creativelik
/// qo'sholasanmi»). Tanqid o'rinli edi va sababi aniq: ilovaning
/// dizayn tili boy — peshtoq, girih, xonatlas ipi, suzani muhri,
/// dastgoh yuklagichi — lekin TUGMA shularning hech qaysisini
/// bilmasdi. U oddiy Material to'rtburchagi edi, ya'ni **eng ko'p
/// tegiladigan element eng brendsiz element** edi.
///
/// ─────────────────────────────────────────────────────────────────
/// QOIDALAR — nima QILINMADI va NEGA
/// ─────────────────────────────────────────────────────────────────
///
/// ⚠️ NAQSH TUGMA ICHIGA SOLINMADI. Naqsh nizomi quyuqlikni 0.08 bilan
/// cheklaydi, tugma yozuvi esa to'rtala temada 5.5–8.2 : 1 kontrast
/// bilan O'LCHANGAN (`accessibility_test`). Zaminga to'qima qo'shish
/// o'sha o'lchovni buzadi — chiroy uchun o'qilishni qurbon qilmaymiz.
///
/// ⚠️ XONATLAS IPI QO'SHILMADI. U ilovaning YAGONA tikuv chizig'i va
/// faqat sarlavha panellari ostida turadi. 10.09.2026 da u aynan shu
/// sababdan amal panelidan OLIB TASHLANGAN: bir ekranda ikki marta
/// chiqib, ekranni tasma-tasma qilardi.
///
/// ⚠️ SHAKL O'ZGARTIRILMADI. Peshtoq — SHAKL, bezak emas, va u
/// medalyon/surat uchun. Keng tugmani uchli qilish uni tugmaga
/// o'xshamaydigan qilib qo'yardi.
///
/// ─────────────────────────────────────────────────────────────────
/// QO'SHILGANI — HARAKAT, BEZAK EMAS
/// ─────────────────────────────────────────────────────────────────
///
/// 1. **YO'L IZI** — bosilganda tugma bo'ylab chapdan o'ngga yengil
///    yorug'lik o'tadi. Bu ilovaning o'z motivi: yo'l chizig'i
///    (`JourneyLine`, xaritadagi marshrut, neon yo'l izi). Bosish
///    tugagach iz ham tugaydi — ekranda hech nima QOLMAYDI.
/// 2. **IKONKA OLDINGA SILJIYDI** — 2 px. Yo'nalish hissi: tugma
///    «ketamiz» degan ma'noni beradi.
/// 3. **YUKLANISH — DASTGOH**, aylanma spinner emas. Ilovada
///    yuklanish allaqachon `LoomLoader` bilan ko'rsatiladi; tugmada
///    esa har safar begona `CircularProgressIndicator` aylanardi.
///
/// 🔑 YOZUV YO'QOLMAYDI: yuklanishda ham matn joyida qoladi va tugma
/// ENI o'zgarmaydi. Ilgari matn spinnerga almashardi — tugma sakrab
/// kichrayardi va odam nimani bosganini unutardi.
///
/// 🔑 `AppMotion.on` HURMAT QILINADI: tizimda «harakatni kamaytir»
/// yoqilgan bo'lsa iz ham, siljish ham chizilmaydi — tugma oddiy
/// ishlaydi.
///
/// ⚠️ RANG VA O'LCHAM TEMADAN OLINADI (`filledButtonTheme`): bu yerda
/// hech qanday rang qotirilmaydi. Shu sabab o'chiq holat, neon
/// yolqini va amber temasi avvalgidek ishlaydi.
class YolButton extends StatefulWidget {
  const YolButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.busy = false,
    this.haptic = true,
  });

  /// `null` — tugma o'chiq. ⚠️ Loyiha qoidasi: o'chiq tugmaning SABABI
  /// yonida yozilishi shart (buni chaqiruvchi ekran qiladi).
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  /// So'rov ketyapti: dastgoh aylanadi, tugma bosilmaydi, matn QOLADI.
  final bool busy;
  final bool haptic;

  @override
  State<YolButton> createState() => _YolButtonState();
}

class _YolButtonState extends State<YolButton>
    with SingleTickerProviderStateMixin {
  /* 🔴 `late final` EMAS — bu xato loyihada BIR MARTA bo'lgan
     (`route_map_sheet._trailController`, 30.08.2026) va bu yerda
     sinov uni QAYTA tutdi.
     Dangasa `late final` hech qachon o'qilmasa (tizimda «harakatni
     kamaytir» yoqiq — iz umuman chizilmaydi), `dispose` dagi
     `_trace.dispose()` uni AYNAN O'SHANDA birinchi marta YARATADI.
     Yaratish `createTicker` ni chaqiradi, u esa allaqachon
     o'chirilgan elementda `TickerMode` ni qidiradi:
        «Looking up a deactivated widget's ancestor is unsafe».
     Dangasalikning o'zi TO'G'RI qaror (tikkersiz tugma batareya
     yemaydi) — faqat `dispose` endi YARATMAYDI. */
  AnimationController? _traceController;

  AnimationController get _trace => _traceController ??= AnimationController(
    vsync: this,
    duration: AppMotion.enter,
  );

  bool _down = false;

  @override
  void dispose() {
    _traceController?.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.busy;

  void _press(bool down) {
    if (!_enabled) return;
    setState(() => _down = down);
    if (down && AppMotion.on(context)) _trace.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = AppMotion.on(context);
    final onAccent = theme.colorScheme.onPrimary;

    final Widget leading = widget.busy
        // Dastgoh — tugma yozuvi rangida, ya'ni har temada to'g'ri.
        ? LoomLoader(size: 18, color: onAccent)
        : (widget.icon == null
              ? const SizedBox.shrink()
              : AnimatedSlide(
                  // Oldinga 2 px — yo'nalish hissi (o'ngga, «ketamiz»).
                  offset: _down && motion ? const Offset(0.12, 0) : Offset.zero,
                  duration: AppMotion.quick,
                  child: Icon(widget.icon, size: 20),
                ));

    final button = FilledButton(
      onPressed: _enabled
          ? () {
              if (widget.haptic) AppHaptics.select();
              widget.onPressed!.call();
            }
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.busy || widget.icon != null) ...[
            leading,
            const SizedBox(width: AppSpace.sm),
          ],
          // ⚠️ `Flexible` — uzun matn (ruscha, 1.3 shkala) tugmadan
          // toshib ketmasin: loyihada bu xato bir necha marta bo'lgan.
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    /* ⚠️ `Semantics` O'ROVCHISI YO'Q: `FilledButton` o'z yorlig'ini
       allaqachon e'lon qiladi va ikkinchi o'rovchi ekran o'qigichga
       yorliqni IKKI MARTA o'qitardi.

       🔴 `excludeFromSemantics: true` SHART (21.09.2026, sinov tutdi).
       Men «`GestureDetector` faqat `onTapDown`/`onTapUp` ni tinglaydi,
       demak semantika qo'shmaydi» deb o'ylagandim — NOTO'G'RI: bu
       ikkalasi ham `tap` amali bo'lgan semantika tugunini yasaydi.
       Natijada tugma ustida YORLIQSIZ bosiladigan tugun paydo bo'lib,
       ekran o'qigich uni «tugma» deb e'lon qilardi-yu, NIMA ekanini
       ayta olmasdi (`contrast_audit_test` buni qidiruv va posilka
       ekranlarida tutdi). Bu o'rovchi faqat BOSISH TUYG'USI uchun —
       amalni ostidagi `FilledButton` bajaradi. */
    return GestureDetector(
      excludeFromSemantics: true,
      onTapDown: (_) => _press(true),
      onTapUp: (_) => _press(false),
      onTapCancel: () => _press(false),
      child: AnimatedScale(
        scale: _down && motion ? 0.98 : 1,
        duration: AppMotion.quick,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.control),
          /* 🔴 `StackFit.passthrough` SHART: usiz `Stack` bolaga
             BO'SH constraint beradi va tugma BUTUN ENGDA emas,
             matn eniga qarab kichkina bo'lib qolardi. Loyihada
             asosiy tugma butun engda bo'lishi QOIDA
             (`asosiy-tugma-qoidasi`), ya'ni bu jimgina buziladigan
             joy edi. */
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              button,
              // YO'L IZI — bosilganda bir marta o'tadi va yo'qoladi.
              if (motion)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _trace,
                      builder: (context, _) => CustomPaint(
                        painter: _TracePainter(
                          progress: _trace.value,
                          color: onAccent,
                        ),
                      ),
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

/// Tugma bo'ylab o'tadigan yengil yorug'lik — «yo'l izi».
///
/// 🔑 Chiziq EMAS, YUMSHOQ DOG': qattiq chiziq tugmani ikkiga bo'lib
/// ko'rsatardi. Gradient chetlari shaffof, ya'ni u faqat «nimadir
/// o'tdi» degan taassurot qoldiradi.
class _TracePainter extends CustomPainter {
  const _TracePainter({required this.progress, required this.color});

  /// 0 → chapda (ko'rinmaydi), 1 → o'ngdan chiqib ketdi.
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    // Dog'ning eni tugmaning uchdan biri — kattasi «yaltiroq» bo'lib
    // ketadi, kichigi esa ko'rinmaydi.
    final bandWidth = size.width / 3;
    final x = -bandWidth + (size.width + bandWidth * 2) * progress;
    final rect = Rect.fromLTWH(x, 0, bandWidth, size.height);
    // Boshida va oxirida so'niq: iz «paydo bo'lib, o'chadi».
    final fade = (progress < 0.2)
        ? progress / 0.2
        : (progress > 0.8 ? (1 - progress) / 0.2 : 1.0);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.18 * fade),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_TracePainter old) => old.progress != progress;
}
