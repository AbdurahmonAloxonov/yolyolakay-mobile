import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/voice_ride.dart';

/// OVOZLI E'LON — bitta gapdan butun forma (`core/voice_ride.dart`).
///
/// Qulflanadigan qoida: FAQAT tanilgani to'ldiriladi. Taxmin qilinmaydi —
/// yolg'on to'ldirilgan forma e'lon berilgach jonli xatoga aylanadi.
void main() {
  // Barqaror "bugun" — test sana o'tishi bilan yiqilmasin.
  final now = DateTime(2026, 8, 25, 10, 0);

  test('to\'liq gap — hammasi tanilsin', () {
    final ride = parseVoiceRide(
      'Toshkentdan Samarqandga ertaga sakkizda uch joy sakson ming',
      now: now,
    );

    expect(ride, isNotNull);
    expect(ride!.from?.name, 'Toshkent');
    expect(ride.to?.name, 'Samarqand');
    expect(ride.date, DateTime(2026, 8, 26));
    expect(ride.hour, 8);
    expect(ride.seats, 3);
    expect(ride.price, 80000);
  });

  test('o\'zbek KIRILLIDA ham', () {
    final ride = parseVoiceRide(
      'Тошкентдан Самарқандга эртага 3 joy 80 ming',
      now: now,
    );
    expect(ride?.from?.name, 'Toshkent');
    expect(ride?.to?.name, 'Samarqand');
    expect(ride?.seats, 3);
    expect(ride?.price, 80000);
  });

  test('raqam bilan aytilgan vaqt: «8:30»', () {
    final ride = parseVoiceRide('Toshkentdan Buxoroga bugun 8:30', now: now);
    expect(ride?.hour, 8);
    expect(ride?.minute, 30);
    expect(ride?.date, DateTime(2026, 8, 25));
  });

  test('«soat 14» ko\'rinishi', () {
    final ride = parseVoiceRide('Andijondan Toshkentga soat 14', now: now);
    expect(ride?.hour, 14);
  });

  test('narx so\'m bilan: «75000 so\'m»', () {
    final ride = parseVoiceRide('Toshkent Samarqand 75000 so\'m', now: now);
    expect(ride?.price, 75000);
  });

  test('qo\'shma son: «sakson besh ming»', () {
    final ride = parseVoiceRide('Toshkent Samarqand sakson besh ming', now: now);
    expect(ride?.price, 85000);
  });

  test('ruscha gap', () {
    final ride = parseVoiceRide(
      'из Ташкента в Самарканд завтра 3 места 80 тысяч',
      now: now,
    );
    expect(ride?.from?.name, 'Toshkent');
    expect(ride?.to?.name, 'Samarqand');
    expect(ride?.date, DateTime(2026, 8, 26));
    expect(ride?.seats, 3);
    expect(ride?.price, 80000);
  });

  /// 🔴 ENG MUHIM QOIDA: eshitilmagan narsa TO'LDIRILMAYDI.
  test('faqat yo\'nalish aytilsa — qolgani BO\'SH', () {
    final ride = parseVoiceRide('Toshkentdan Samarqandga', now: now);
    expect(ride?.from?.name, 'Toshkent');
    expect(ride?.date, isNull);
    expect(ride?.hour, isNull);
    expect(ride?.seats, isNull);
    expect(ride?.price, isNull);
  });

  test('hech nima tanilmasa — null', () {
    expect(parseVoiceRide('salom qalaysiz', now: now), isNull);
    expect(parseVoiceRide('   ', now: now), isNull);
  });

  /// Mashinaga sig'maydigan son o'rindiq deb olinmasin.
  test('«o\'n ming so\'m joy» — 10 ta o\'rindiq DEB o\'qilmaydi', () {
    final ride = parseVoiceRide(
      'Toshkent Samarqand o\'n ming so\'m joy',
      now: now,
    );
    expect(ride?.seats, isNull);
  });
}
