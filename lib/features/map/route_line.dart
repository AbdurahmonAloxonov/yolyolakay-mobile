import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'road_route.dart';

/// Marshrut chizig'i — BARCHA xaritalar uchun YAGONA qoida.
///
/// 🔴 NEGA (28.09.2026, egasi: «xaritada to'g'ri chiziqlarmi, rasvo»).
/// Yo'l kelguncha yoki so'rov yiqilganda nuqtalar TO'G'RI CHIZIQ bilan
/// ulanardi — va u haqiqiy yo'l bilan AYNAN bir xil rang va qalinlikda
/// chizilardi. Odam tog' ustidan o'tgan chiziqni «marshrut» deb ko'rardi.
///
/// Endi ikki xil ko'rinish:
///   • HAQIQIY YO'L — yaxlit, to'liq rangda, oq hoshiyali (har xil plitka
///     ustida ham o'qiladi);
///   • TAXMINIY (to'g'ri) chiziq — UZUQ, ingichka va xira: «bu yo'nalish,
///     yo'l emas». Yo'l kelishi bilan o'rnini bo'shatadi.
List<Polyline> routePolylines({
  required List<LatLng> straight,
  required RoadRoute? route,
  required Color color,
  double width = 4,
}) {
  final real = route != null && route.isRealRoad && route.points.length > 1;
  if (real) {
    return [
      Polyline(
        points: route.points,
        strokeWidth: width,
        color: color,
        // Qalin oq hoshiya: rangli OSM fonida (sariq cho'l, yashil park,
        // pushti chegara) yo'l aynan shu hoshiya tufayli ajralib turadi
        // — egasi fonni o'zgartirmaslikni tanladi (28.09.2026).
        borderStrokeWidth: 2.5,
        borderColor: Colors.white.withValues(alpha: 0.95),
      ),
    ];
  }
  if (straight.length < 2) return const [];
  return [
    Polyline(
      points: straight,
      strokeWidth: (width * 0.6).clamp(2, 3).toDouble(),
      color: color.withValues(alpha: 0.55),
      pattern: StrokePattern.dashed(segments: const [10, 8]),
    ),
  ];
}
