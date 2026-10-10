import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/push_actions.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/ride.dart';

/// PUSH'DAGI TUGMALAR — noto'g'ri odamni qabul qilib qo'ymaydimi?
///
/// 🔴 NEGA O'LCHANADI: tugma bosilganda qaysi bronni tasdiqlashni push
/// AYTMAYDI (`ride_id`/`booking_id` yo'q — 16.09.2026 da o'lchangan),
/// ya'ni bronni ilova O'ZI topadi. Bu yerdagi xato — «bir bosishda
/// noto'g'ri yo'lovchi qabul qilindi» degani: uni haydovchi ham,
/// yo'lovchi ham keyin, safar kunida biladi.
///
/// Shuning uchun ASOSIY qoida sinovda qotiriladi: kutayotgan bron
/// BITTA bo'lsagina amal bajariladi.
void main() {
  Booking booking(String id, String status) => Booking(
    id: id,
    rideId: 'r',
    passengerId: 'p',
    seatsBooked: 1,
    status: status,
  );

  Ride ride(
    String id, {
    required List<Booking> bookings,
    String status = RideStatus.active,
  }) => Ride(
    id: id,
    originAddress: 'Toshkent',
    originLat: 41.3,
    originLon: 69.2,
    destinationAddress: 'Samarqand',
    destinationLat: 39.6,
    destinationLon: 66.9,
    departureTime: DateTime(2026, 9, 20, 8),
    pricePerSeat: 100000,
    totalSeats: 4,
    availableSeats: 3,
    status: status,
    bookings: bookings,
  );

  group('Qaysi bron', () {
    test('BITTA kutayotgan bron — amal bajariladi', () {
      final rides = [
        ride('r1', bookings: [booking('b1', BookingStatus.pending)]),
      ];
      expect(resolveSinglePending(rides), const BookingRef('r1', 'b1'));
    });

    test('IKKITA kutayotgan bron — HECH NIMA qilinmaydi', () {
      final rides = [
        ride(
          'r1',
          bookings: [
            booking('b1', BookingStatus.pending),
            booking('b2', BookingStatus.pending),
          ],
        ),
      ];
      expect(
        resolveSinglePending(rides),
        isNull,
        reason: 'taxmin qilib noto\'g\'ri yo\'lovchini qabul qilish mumkin emas',
      );
      expect(pendingBookings(rides), hasLength(2));
    });

    test('ikki xil SAFARDAGI ikkita bron ham — hisoblanadi', () {
      final rides = [
        ride('r1', bookings: [booking('b1', BookingStatus.pending)]),
        ride('r2', bookings: [booking('b2', BookingStatus.pending)]),
      ];
      expect(resolveSinglePending(rides), isNull);
    });

    test('savdolashuv (pending_negotiation) ham JAVOB KUTADI', () {
      final rides = [
        ride(
          'r1',
          bookings: [booking('b1', BookingStatus.pendingNegotiation)],
        ),
      ];
      expect(resolveSinglePending(rides), const BookingRef('r1', 'b1'));
    });

    test('hal bo\'lgan bronlar hisobga OLINMAYDI', () {
      final rides = [
        ride(
          'r1',
          bookings: [
            booking('b1', BookingStatus.confirmed),
            booking('b2', BookingStatus.rejected),
            booking('b3', BookingStatus.cancelled),
            booking('b4', BookingStatus.noShow),
            booking('b5', BookingStatus.pending),
          ],
        ),
      ];
      expect(resolveSinglePending(rides), const BookingRef('r1', 'b5'));
    });

    test('BEKOR QILINGAN safardagi bron qaror kutmaydi', () {
      // Ilgari shu yerda xato bo'lishi mumkin edi: safar bekor qilinsa
      // bronlar `pending` bo'lib QOLADI va tugma o'lik safarni
      // tasdiqlab yuborardi.
      final rides = [
        ride(
          'r1',
          status: RideStatus.cancelled,
          bookings: [booking('b1', BookingStatus.pending)],
        ),
        ride('r2', bookings: [booking('b2', BookingStatus.pending)]),
      ];
      expect(resolveSinglePending(rides), const BookingRef('r2', 'b2'));
    });

    test('hech nima kutmayotgan bo\'lsa — bo\'sh', () {
      expect(resolveSinglePending([]), isNull);
      expect(pendingBookings([]), isEmpty);
    });
  });

  group('Qaysi push', () {
    test('yangi bron — tugmalar CHIZILADI', () {
      for (final type in [
        'booking_created',
        'BookingCreated',
        'BOOKING_CREATED',
        'new_booking',
      ]) {
        expect(
          isNewBookingPush({'type': type}),
          isTrue,
          reason: 'backend turni uch xil yozgan — uchalasi ham tanilsin',
        );
      }
    });

    test('bron haqidagi XABARGA tugma kerak emas', () {
      // Bular so'rov emas, xabar: tugma ma'nosiz va chalg'ituvchi.
      for (final type in [
        'booking_cancelled',
        'booking_rejected',
        'booking_confirmed',
        'new_message',
        'ride_cancelled',
        'subscription_activated',
      ]) {
        expect(isNewBookingPush({'type': type}), isFalse, reason: type);
      }
    });

    test('turi yo\'q push — tugmasiz', () {
      expect(isNewBookingPush({}), isFalse);
      expect(isNewBookingPush({'title': 'Yangi bron'}), isFalse);
    });
  });

  group('Bosilgan tugma', () {
    test('tugma bosilgani oddiy bosishdan FARQ qiladi', () {
      expect(isBookingAction({pushActionKey: bookingAcceptAction}), isTrue);
      expect(isBookingAction({pushActionKey: bookingRejectAction}), isTrue);
      expect(isBookingAction({'type': 'booking_created'}), isFalse);
      expect(isBookingAction({pushActionKey: 'boshqa'}), isFalse);
    });

    test('kalit backend maydonlari bilan to\'qnashmaydi', () {
      // Pastki chiziq — bizning ichki belgimiz.
      expect(pushActionKey.startsWith('_'), isTrue);
    });
  });

  group('Tugma yozuvlari', () {
    test('to\'rt tilda ham bo\'sh emas', () {
      for (final code in ['uz', 'uz-Cyrl', 'ru', 'en', null]) {
        final l = bookingActionLabels(code);
        expect(l.accept.trim(), isNotEmpty, reason: '$code');
        expect(l.reject.trim(), isNotEmpty, reason: '$code');
      }
    });

    test('noma\'lum til — o\'zbekcha (ilovaning standart tili)', () {
      expect(bookingActionLabels('de').accept, bookingActionLabels('uz').accept);
      expect(bookingActionLabels(null).accept, 'Qabul qilaman');
    });

    test('kirill yozuvi lotinchadan FARQ qiladi', () {
      // 08.09.2026 saboqi: `uz-Cyrl` alohida yozuv, uni unutish oson.
      expect(
        bookingActionLabels('uz-Cyrl').accept,
        isNot(bookingActionLabels('uz').accept),
      );
    });

    test('tugma yozuvi QISQA — Androidda kesiladi', () {
      for (final code in ['uz', 'uz-Cyrl', 'ru', 'en']) {
        final l = bookingActionLabels(code);
        expect(l.accept.length, lessThanOrEqualTo(16), reason: code);
        expect(l.reject.length, lessThanOrEqualTo(16), reason: code);
      }
    });
  });

  test('til kaliti `LocaleController` dagi bilan bir xil', () {
    // 🔑 Ikki joyda yozilgan va bog'lab bo'lmaydi (fon isolate'i
    // providerlarni ko'rmaydi) — shuning uchun sinov qo'riqlaydi.
    expect(localePrefsKey, 'locale');
  });
}
