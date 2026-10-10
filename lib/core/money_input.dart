import 'package:flutter/services.dart';

/// Narx kiritishda minglarni ajratadi: "50000" -> "50 000".
///
/// 🔴 Egasi (2026-08-20): narx yozganda formatlansin, o'qish oson bo'lsin.
/// O'zbekда minglar PROBEL bilan ajratiladi (50 000 so'm).
///
/// ⚠️ PARSE'да probel OLIB TASHLANISHI SHART: `double.tryParse("50 000")`
/// `null` qaytaradi. Shuning uchun matnni o'qiyotган joy `digitsOnly` dan
/// o'tkazishi kerak — pastдаги yordamchi shuni qiladi.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final formatted = group(digits);
    // Kursor doim oxirда: minglar ajratgichi o'rtaga probel qo'shgani uchun
    // kursorni aniq joyда saqlash murakkab va narx maydonида shart emas.
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String group(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

/// Formatlangan narx matnidan sonni oladi: "50 000" -> 50000.0.
/// Probel/harflar tashlanadi. Bo'sh yoki noto'g'ri -> null.
double? parseMoney(String text) {
  final digits = text.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return null;
  return double.tryParse(digits);
}

/// Sonni MAYDON UCHUN formatlaydi: 50000 -> "50 000".
/// Boshlang'ich qiymatni dasturiy o'rnatганда ishlatiladi (formatter faqat
/// QO'LDA yozishда ishlaydi, `controller.text = ...` da emas).
String formatMoneyInput(num value) =>
    ThousandsInputFormatter.group(value.round().toString());
