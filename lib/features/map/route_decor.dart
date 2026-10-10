import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/dimens.dart';

/// Marshrut UCHLARINING belgisi — nuqta va ustida shahar nomi.
///
/// 🔴 NEGA (28.09.2026, egasi: «xarita eng dabdala ko'rinishda»). OSM
/// fonidagi yozuvlar uch tilda (Шымкент, Тоҷикистон, Samarqand Viloyati)
/// va mayda; bizning yo'lning boshi va oxiri esa faqat rangli doira edi —
/// qaysi shahar ekanini fon yozuvidan qidirish kerak edi. Endi uchlar
/// O'ZBEKCHA nom bilan belgilanadi.
///
/// ⚠️ EGASINING SHARTI: fon o'zgarmaydi va «bezak ortiqcha bo'lib
/// ketmasin». Shuning uchun faqat IKKI UCH nomlanadi (oraliq bekatlar
/// oddiy nuqta qoladi) va boshqa hech narsa qo'shilmaydi.
///
/// Belgi nuqtaning AYNAN markazida: vidjet balandligi yorliq bilan
/// simmetrik (pastda bo'sh joy), shuning uchun `Marker` ning standart
/// markazlash qoidasi doirani nuqtaga qo'yadi.
Marker routeEndMarker({
  required LatLng point,
  required String? name,
  required Color color,
  bool compact = false,
}) {
  final dot = compact ? 14.0 : 18.0;
  final pill = compact ? 20.0 : 26.0;
  const gap = 4.0;
  final label = shortPlaceName(name);
  final height = label == null ? dot + 8 : 2 * (pill + gap) + dot;
  return Marker(
    point: point,
    width: label == null ? dot + 8 : 180,
    height: height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (label != null) ...[
          _NamePill(text: label, compact: compact, height: pill),
          const SizedBox(height: gap),
        ],
        _EndDot(size: dot, color: color),
        if (label != null) SizedBox(height: pill + gap),
      ],
    ),
  );
}

/// Manzil matnidan QISQA nom: «Samarqand, Samarqand viloyati» → «Samarqand».
/// Bo'sh bo'lsa `null` — yorliq umuman chizilmaydi.
String? shortPlaceName(String? address) {
  final first = (address ?? '').split(',').first.trim();
  return first.isEmpty ? null : first;
}

class _EndDot extends StatelessWidget {
  const _EndDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _NamePill extends StatelessWidget {
  const _NamePill({
    required this.text,
    required this.compact,
    required this.height,
  });

  final String text;
  final bool compact;

  /// QAT'IY balandlik: belgi o'lchami shundan hisoblanadi va matn
  /// balandligi shriftga qarab o'zgarsa, belgi toshib ketardi (sinov
  /// tutdi: 2 px).
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      constraints: const BoxConstraints(maxWidth: 176),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      decoration: BoxDecoration(
        // Yorug' ham, tungi ham fonda bir xil: to'q yorliq har qanday
        // plitka ustida o'qiladi.
        color: const Color(0xEB2A2226),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      // `widthFactor: 1` — yorliq matn kengligida qoladi (`alignment`
      // Container'ni butun kenglikka yoyib yuborardi — rasmda ko'rildi).
      child: Align(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // Xarita ichidagi yorliq shrift kattaligidan MUSTAQIL: belgining
          // o'lchami qat'iy, kattalashgan matn undan toshib chiqardi.
          textScaler: TextScaler.noScaling,
          style:
              (compact
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelLarge)
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
