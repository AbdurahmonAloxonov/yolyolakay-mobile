import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api/api_client.dart' show asMap;
import 'json.dart';

/// MANZILDAGI OB-HAVO — safar kunidagi eng yuqori harorat.
///
/// 🔴 NEGA KERAK: shaharlararo safarda odam nima kiyishini va yo'l qanday
/// bo'lishini bilishi kerak. Hozir buni boshqa ilovadan qaraydi.
///
/// 🔴 MANBA: Open-Meteo — KALIT talab qilmaydi va bizning backendimizga
/// bog'liq emas.
///
/// ⚠️ LITSENZIYA: Open-Meteo bepul tarifi NOTIJORAT foydalanish uchun.
/// YolYolakay tijorat mahsuloti, ya'ni relizdan oldin ularning tijorat
/// tarifiga o'tish yoki bu funksiyani olib tashlash kerak. Egasi
/// xabardor qilingan (2026-08-21).
///
/// ⚠️ Xato YUTILADI: ob-havo QO'SHIMCHA ma'lumot va uning yiqilishi
/// safar ekranini buzmasligi kerak.
class WeatherRepository {
  WeatherRepository()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.open-meteo.com',
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

  final Dio _dio;

  Future<DayWeather?> forDay({
    required double lat,
    required double lon,
    required DateTime day,
  }) async {
    final date =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    try {
      final res = await _dio.get<dynamic>(
        '/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'daily': 'temperature_2m_max,weather_code',
          'timezone': 'Asia/Tashkent',
          'start_date': date,
          'end_date': date,
        },
      );
      final daily = asMap(asMap(res.data)?['daily']);
      final temps = daily?['temperature_2m_max'];
      final codes = daily?['weather_code'];
      if (temps is! List || temps.isEmpty) return null;
      return DayWeather(
        maxTemp: asDouble(temps.first),
        code: codes is List && codes.isNotEmpty ? asInt(codes.first) : 0,
      );
    } catch (_) {
      return null;
    }
  }
}

class DayWeather {
  const DayWeather({required this.maxTemp, required this.code});

  final double maxTemp;

  /// WMO ob-havo kodi. To'liq jadval EMAS — faqat guruhlar: aniq kod
  /// ("o'rtacha kuchli yomg'ir") odamga qo'shimcha hech nima bermaydi.
  final int code;

  IconData get icon {
    if (code == 0) return Icons.wb_sunny_outlined;
    if (code <= 3) return Icons.wb_cloudy_outlined;
    if (code <= 49) return Icons.foggy;
    if (code <= 69) return Icons.water_drop_outlined;
    if (code <= 79) return Icons.ac_unit;
    if (code <= 89) return Icons.grain;
    return Icons.thunderstorm_outlined;
  }

  /// Harorat — butun songa yaxlitlangan: "+31.7°" soxta aniqlik beradi.
  String get tempLabel {
    final rounded = maxTemp.round();
    return '${rounded > 0 ? '+' : ''}$rounded°';
  }
}
