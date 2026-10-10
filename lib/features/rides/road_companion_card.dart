import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/road_facts.dart';
import '../../l10n/strings.dart';
import '../../l10n/cyrillic.dart';

/// YO'L HAMROHI KARTASI — «hozir qayerdan o'tyapmiz».
///
/// 🔴 NEGA (egasi, 2026-08-27): Toshkent–Samarqand to'rt soat, Buxoroga
/// oltidan oshadi. Odam zerikadi — va aynan o'sha paytda internet ham
/// YO'Q, chunki shaharlararo yo'lda antena chiqmaydi. Shuning uchun bu
/// karta tarmoqqa BIRORTA so'rov qilmaydi: joylar ham, matnlar ham
/// qurilmada (`core/road_facts.dart`).
///
/// ⚠️ FAQAT YO'LOVCHIGA chiziladi. Haydovchi to'rt soat telefonga
/// qaramaydi va qaramasligi kerak — unga faqat OVOZ (sozlamadan
/// yoqiladigan `readAloudProvider`).
///
/// ⚠️ Joy topilmasa yoki u haqida gapimiz bo'lmasa — HECH NIMA
/// chizilmaydi. «Ma'lumot yo'q» degan bo'sh karta zerikishni yechmaydi,
/// aksincha ilovani bo'sh ko'rsatadi.
class RoadCompanionCard extends ConsumerStatefulWidget {
  const RoadCompanionCard({super.key, required this.lat, required this.lon});

  /// Hozirgi joylashuv — chaqiruvchidan (qurilma GPS'i yoki haydovchi
  /// oxirgi `ping` i).
  final double? lat;
  final double? lon;

  @override
  ConsumerState<RoadCompanionCard> createState() => _RoadCompanionCardState();
}

class _RoadCompanionCardState extends ConsumerState<RoadCompanionCard> {
  FlutterTts? _tts;
  bool _speaking = false;

  /// Oxirgi o'qilgan joy — bir gapni ikki marta o'qimaslik uchun.
  String? _spokenFor;

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  Future<void> _speak(String text, Lang lang) async {
    final tts = _tts ??= FlutterTts();
    // Til kodi topilmasa qurilma o'z tilida o'qiydi — bu jim qolishdan
    // yaxshiroq.
    await tts.setLanguage(switch (lang) {
      Lang.ru => 'ru-RU',
      Lang.en => 'en-US',
      // O'zbekcha ovoz ko'p qurilmada YO'Q; bunda tizim o'zi eng yaqinini
      // tanlaydi va matn baribir tushunarli o'qiladi.
      Lang.uz => 'uz-UZ',
      Lang.uzCyrl => toCyrillic('uz-UZ'),
    });
    await tts.setSpeechRate(0.45);
    if (!mounted) return;
    setState(() => _speaking = true);
    await tts.speak(text);
    if (!mounted) return;
    setState(() => _speaking = false);
  }

  Future<void> _stop() async {
    await _tts?.stop();
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.lat;
    final lon = widget.lon;
    if (lat == null || lon == null) return const SizedBox.shrink();

    final place = nearestKnownPlace(lat, lon);
    if (place == null) return const SizedBox.shrink();
    final fact = factFor(place);
    if (fact == null) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final readAloud = ref.watch(readAloudProvider);
    final text = fact.forLang(t.lang);

    // Ovoz YOQILGAN bo'lsa yangi joyga yetganda BIR MARTA o'qiladi.
    if (readAloud && _spokenFor != place.name) {
      _spokenFor = place.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak('${place.name}. $text', t.lang);
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    t.roadWhereTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                // Tugma FAQAT sozlamada yoqilganda — aks holda odam
                // so'ramagan imkoniyat tugmasi bo'lib turadi.
                if (readAloud)
                  IconButton(
                    onPressed: _speaking
                        ? _stop
                        : () => _speak('${place.name}. $text', t.lang),
                    icon: Icon(
                      _speaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      size: 20,
                    ),
                    tooltip: _speaking ? t.roadStopReading : t.roadReadAloud,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(place.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpace.xs),
            Text(text, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
