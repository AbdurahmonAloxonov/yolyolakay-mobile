/// JSON parse yordamchilari.
///
/// Gateway javoblari bir xil emas: bir joyda `snake_case`, boshqasida
/// `PascalCase`; sonlar goh `int`, goh `double`, goh `String` bo'lib keladi.
/// Shuning uchun model konstruktorlari to'g'ridan-to'g'ri cast qilmaydi.
library;

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  return str.isEmpty ? null : str;
}

String asString(dynamic value, [String fallback = '']) =>
    asStringOrNull(value) ?? fallback;

/// 🔴 Go'ning "nol vaqti" (`0001-01-01T00:00:00Z`) — SANA EMAS, "qiymat yo'q".
///
/// Backend uni jonli yuboradi: WS `new_message` kadrida `created_at` aynan
/// shunday keladi (o'lchandi 2026-08-20), `departure_time` da ham uchradi.
/// `DateTime.tryParse` buni bemalol o'qiydi va natijada:
///   • yangi kelgan xabar yozishmaning eng TEPASIGA sakraydi (1-yil eng eski);
///   • ustida "01.01.0001" degan sana ajratgichi paydo bo'ladi.
///
/// `null` qaytarsak, mavjud mantiq buni allaqachon to'g'ri ishlaydi: vaqtsiz
/// xabar QO'SHNISINING vaqtini oladi, ya'ni o'z joyida — oxirida qoladi.
/// Chegara 2000-yil: undan oldingi sana bu ilovada haqiqiy bo'la olmaydi.
DateTime? asDate(dynamic value) {
  final raw = asStringOrNull(value);
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || parsed.year < 2000) return null;
  return parsed.toLocal();
}

/// Berilgan kalitlardan birinchi topilganini qaytaradi.
///
/// Bron obyekti gateway'dan `PascalCase` keladi (Swagger'dagi `camelCase`
/// yolg'on chiqdi, 2026-07-18 jonli tekshiruv) — lekin kelajakda to'g'rilanishi
/// mumkin, shuning uchun ikkala yozuvni ham qabul qilamiz.
dynamic pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}
