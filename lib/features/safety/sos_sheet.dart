import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/geo_message.dart';
import '../../l10n/strings.dart';
import '../map/point_preview_map.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';
import '../../core/haptics.dart';
import '../../core/share_safely.dart';

/// Favqulodda yordam (SOS) — BITTA amal: `tel:102`.
///
/// 🔴 2026-08-16 da SODDALASHTIRILDI (egasi: "SOS'da 102 qolsin, boshqa
/// narsa qolmasin"). Ilgari bu yerda "ishonchli shaxsga joylashuv SMS"
/// oqimi ham bor edi: raqam kiritish, saqlash, GPS kutish. Favqulodda
/// holatda odam forma to'ldirmaydi — har qo'shimcha qadam qo'ng'iroqni
/// KECHIKTIRADI, ya'ni SOSning o'zini zaiflashtiradi.
///
/// NEGA BACKEND YO'Q: favqulodda holatda serverga bog'liq bo'lish xavfli.
/// Qo'ng'iroq tarmoq yiqilsa ham (hatto internetsiz ham) ishlaydi.
///
/// Tasdiq oynasi ATAYIN qoldirilgan: SOS tugmasi ekranda turadi va tasodifiy
/// bosilsa to'g'ridan-to'g'ri militsiyaga qo'ng'iroq ketib qolardi.
///
/// ═══ «MEN QAYERDAMAN» — 16.09.2026 ═══
///
/// 🔴 NEGA QO'SHILDI: 102 ga qo'ng'iroq qilganda BIRINCHI so'raladigan
/// savol — «qayerdasiz?». Shaharlararo yo'lda odam bunga javob bera
/// olmaydi: atrofda belgi yo'q, u shunchaki «Toshkent–Samarqand yo'lida,
/// bir joyda». Bu varaqda esa koordinata UMUMAN yo'q edi (birorta ham
/// `lat` satri).
///
/// ⚠️ EGASINING QARORI BUZILMADI (2026-08-16: «SOS'da 102 qolsin»).
/// Qo'ng'iroq tugmasi TEPADA, birinchi va o'zgarmagan — u GPSni
/// KUTMAYDI. Joy PASTDA, mustaqil ravishda, fon'da aniqlanadi: kelsa
/// ko'rinadi, kelmasa varaq o'sha-o'sha ishlayveradi. Ya'ni bu
/// qo'ng'iroqni bir qadam ham kechiktirmaydi, aksincha unga JAVOB
/// beradi.
class SosSheet extends ConsumerStatefulWidget {
  const SosSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
    // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
    // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
    // qolib, bosib bo'lmaydigan bo'lardi.
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => const SosSheet(),
  );

  @override
  ConsumerState<SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends ConsumerState<SosSheet> {
  /// Joriy joy — fon'da aniqlanadi, qo'ng'iroqni kutib turmaydi.
  Position? _me;

  /// Joy NOMI — teskari geokoderdan. Koordinata dispecherga hech nima
  /// aytmaydi, «Toshkent–Samarqand yo'li, Jizzax yaqini» esa aytadi.
  String? _label;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() => _me = position);

      // Nom IKKINCHI qadam: u tarmoqqa chiqadi va bo'lmasligi mumkin.
      // Koordinata esa allaqachon ekranda — tarmoqsiz ham foydali.
      final name = await ref
          .read(geocoderProvider)
          .reverse(position.latitude, position.longitude);
      if (mounted) setState(() => _label = name);
    } catch (_) {
      // Joy aniqlanmadi — varaq o'z ishini qilaveradi (102 tugmasi
      // undan mustaqil). Xato ko'rsatib favqulodda varaqni
      // shovqinga to'ldirmaymiz.
    }
  }

  Future<void> _call102(BuildContext context) async {
    final t = AppStrings.of(context);
    AppHaptics.heavy(); // xavfli/shoshilinch amal — sezilarli tebranish
    final opened = await launchUrl(Uri.parse('tel:102'));
    if (!opened && context.mounted) showMessage(context, t.linkOpenFailed);
  }

  /// Joyni ULASHISH — SMS, Telegram, qayerga bo'lsa ham.
  ///
  /// 🔑 Chatdagi bilan AYNAN bir format (`geo:`): yaqin kishiga
  /// yuborilsa va u YolYolakay'da ochsa — xarita bo'lib ko'rinadi
  /// (izohi `core/geo_message.dart` da).
  Future<void> _share() async {
    final me = _me;
    if (me == null) return;
    final text = GeoMessage(
      lat: me.latitude,
      lon: me.longitude,
      label: _label,
    ).encode();
    await shareSafely(context, ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final me = _me;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.emergency_outlined, color: theme.colorScheme.error),
              const SizedBox(width: AppSpace.sm),
              // 🔴 `Expanded` (2026-08-30 auditi): sarlavha tor ekranda
              // 110 pikselgacha toshib ketardi. Bu FAVQULODDA varaq —
              // undagi matn kesilishi mumkin emas.
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(t.sosTitle, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => _call102(context),
            icon: const Icon(Icons.phone),
            label: Text(t.sosCall102),
          ),

          // ─── MEN QAYERDAMAN (qo'ng'iroqdan KEYIN, uni kutmasdan) ───
          const SizedBox(height: AppSpace.xl),
          Text(t.sosWhereAmI, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpace.sm),
          if (me == null)
            // Aniqlanayotgani AYTILADI: bo'sh joy «buzilgan» ko'rinardi.
            Row(
              children: [
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    t.sosLocating,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            PointPreviewMap(point: LatLng(me.latitude, me.longitude)),
            const SizedBox(height: AppSpace.sm),
            // Koordinata O'QIB BERISH uchun ham yoziladi: telefonda
            // dispecherga aynan shu raqamlarni aytish mumkin.
            SelectableText(
              _label == null
                  ? '${me.latitude.toStringAsFixed(5)}, ${me.longitude.toStringAsFixed(5)}'
                  : '$_label\n${me.latitude.toStringAsFixed(5)}, ${me.longitude.toStringAsFixed(5)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpace.md),
            OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.ios_share, size: 18),
              label: Text(t.sosShareLocation),
            ),
          ],
        ],
      ),
    );
  }
}
