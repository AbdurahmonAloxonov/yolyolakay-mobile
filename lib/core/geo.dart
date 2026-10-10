import 'dart:math';

/// Ikki nuqta orasidagi masofa (km) — haversine.
///
/// Qidiruvda safarlarni jo'nash nuqtasiga YAQINLIGI bo'yicha saralash uchun:
/// backend natijalarni tartiblab bermaydi, radius ichida hammasi aralash keladi.
/// Web'da ham aynan shunday hisoblanadi.
double distanceKm({
  required double fromLat,
  required double fromLon,
  required double toLat,
  required double toLon,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(toLat - fromLat);
  final dLon = _toRadians(toLon - fromLon);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(fromLat)) *
          cos(_toRadians(toLat)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _toRadians(double degrees) => degrees * pi / 180;
