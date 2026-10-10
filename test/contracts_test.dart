import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/format.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/ride.dart';

/// Backend kontraktining nozik joylari — bular jonli xatolardan o'rganilgan,
/// shuning uchun test bilan mahkamlanadi.
void main() {
  group('departure_time', () {
    test('RFC3339 ofset bilan yoziladi (UTC deb o\'qilib qolmasin)', () {
      final local = DateTime(2026, 7, 30, 9, 0);
      final encoded = toRfc3339(local);

      // Ofset MAJBURIY: toIso8601String() uni yozmaydi va safar siljib ketardi.
      expect(encoded, matches(r'^2026-07-30T09:00:00[+-]\d{2}:\d{2}$'));
      expect(encoded.contains('.'), isFalse, reason: 'millisekund kerak emas');
    });

    test('PublishRideRequest.toJson ofsetli vaqtni yuboradi', () {
      final json = PublishRideRequest(
        departureTime: DateTime(2026, 7, 30, 9, 0),
        originAddress: 'Toshkent',
        originLat: 41.2995,
        originLon: 69.2401,
        destinationAddress: 'Samarqand',
        destinationLat: 39.6542,
        destinationLon: 66.9597,
        pricePerSeat: 150000,
        totalSeats: 3,
        vehicleId: 'car-1',
      ).toJson();

      expect(json['departure_time'], matches(r'[+-]\d{2}:\d{2}$'));
      // Ixtiyoriy maydonlar berilmasa YUBORILMAYDI (backend null'ni yoqtirmaydi).
      expect(json.containsKey('gender_restriction'), isFalse);
      expect(json.containsKey('stops'), isFalse);
      // «Farqi yo'q» — maydon umuman yuborilmaydi, aks holda kartada
      // bo'sh musiqa belgisi chiqardi.
      expect(json.containsKey('music_taste'), isFalse);
    });

    /// 🔴 27.08.2026 dan 09.09.2026 gacha `music_taste` HECH QACHON
    /// yuborilmagan: kartadagi belgilar chizilgan edi-yu, ularni yoqadigan
    /// joy yo'q edi. Test aynan shu bo'g'inni qo'riqlaydi — tanlov yana
    /// jimgina yo'qolib qolmasin.
    test('musiqa tanlansa `music_taste` YUBORILADI', () {
      final json = PublishRideRequest(
        departureTime: DateTime(2026, 7, 30, 9, 0),
        originAddress: 'Toshkent',
        originLat: 41.2995,
        originLon: 69.2401,
        destinationAddress: 'Samarqand',
        destinationLat: 39.6542,
        destinationLon: 66.9597,
        pricePerSeat: 150000,
        totalSeats: 3,
        vehicleId: 'car-1',
        musicTaste: 'quiet',
      ).toJson();

      expect(json['music_taste'], 'quiet');
    });
  });

  group('Booking.fromJson', () {
    test('gateway PascalCase javobini o\'qiydi', () {
      final booking = Booking.fromJson(const {
        'ID': 'b-1',
        'RideID': 'r-1',
        'PassengerID': 'p-1',
        'SeatsBooked': 2,
        'OfferedPrice': null,
        'Status': 'confirmed',
      });

      expect(booking.id, 'b-1');
      expect(booking.rideId, 'r-1');
      expect(booking.seatsBooked, 2);
      expect(booking.offeredPrice, isNull, reason: 'null jonlida kuzatilgan');
      expect(booking.isConfirmed, isTrue);
    });

    test('snake_case variantini ham o\'qiydi', () {
      final booking = Booking.fromJson(const {
        'id': 'b-2',
        'ride_id': 'r-2',
        'passenger_id': 'p-2',
        'seats_booked': 1,
        'status': 'pending_negotiation',
      });

      expect(booking.id, 'b-2');
      expect(booking.seatsBooked, 1);
      expect(booking.isPending, isTrue);
    });
  });

  group('BookRideRequest', () {
    test('maydon nomi `seats` (seats_booked EMAS)', () {
      final json = const BookRideRequest(seats: 2).toJson();
      expect(json['seats'], 2);
      expect(json.containsKey('seats_booked'), isFalse);
    });
  });

  group('Ride.fromJson', () {
    test('yassi koordinatalar va belgilarni o\'qiydi', () {
      final ride = Ride.fromJson(const {
        'id': 'r-1',
        'origin_address': 'Toshkent',
        'origin_lat': 41.2995,
        'origin_lon': 69.2401,
        'destination_address': 'Buxoro',
        'destination_lat': 39.7747,
        'destination_lon': 64.4286,
        'departure_time': '2026-07-30T09:00:00+05:00',
        'total_seats': 4,
        'available_seats': 2,
        'price_per_seat': 200000,
        'status': 'active',
        'no_smoking': true,
        'driving_speed': 'calm',
      });

      expect(ride.availableSeats, 2);
      expect(ride.noSmoking, isTrue);
      expect(ride.drivingSpeed, DrivingSpeed.calm);
      expect(ride.isActive, isTrue);
      expect(ride.departureTime, isNotNull);
    });

    test('noma\'lum driving_speed null bo\'ladi (crash emas)', () {
      final ride = Ride.fromJson(const {
        'id': 'r-2',
        'status': 'active',
        'driving_speed': 'teleport',
      });
      expect(ride.drivingSpeed, isNull);
    });
  });

  group('RideVehicle', () {
    // Backend bir xil mashinani IKKI XIL ataydi — ikkalasini ham o'qiymiz,
    // aks holda yo'lovchi mashina raqamini ko'rmay qoladi.
    test('domain.Vehicle shakli (license_plate, color, year)', () {
      final car = RideVehicle.tryParse(const {
        'brand': 'Chevrolet',
        'model': 'Cobalt',
        'license_plate': '01 A 123 BC',
        'color': 'oq',
        'year': 2021,
      });

      expect(car?.title, 'Chevrolet Cobalt');
      expect(car?.plate, '01 A 123 BC');
      expect(car?.color, 'oq');
      expect(car?.year, 2021);
    });

    test('domain.Car shakli (gov_number)', () {
      final car = RideVehicle.tryParse(const {
        'brand': 'Malibu',
        'gov_number': '10 B 777 CA',
      });

      expect(car?.plate, '10 B 777 CA');
      expect(car?.title, 'Malibu');
    });

    test('{car: {...}} o\'ramidan chiqaradi', () {
      final car = RideVehicle.tryParse(const {
        'car': {'brand': 'Nexia', 'gov_number': '01 A 001 AA'},
      });
      expect(car?.title, 'Nexia');
    });

    test('bo\'sh yoki yaroqsiz — null (qator umuman chizilmaydi)', () {
      expect(RideVehicle.tryParse(null), isNull);
      expect(RideVehicle.tryParse('nexia'), isNull);
      expect(RideVehicle.tryParse(const {'color': 'oq'}), isNull);
      // Xato yil ko'rsatilmaydi.
      expect(
        RideVehicle.tryParse(const {'brand': 'Damas', 'year': 12})?.year,
        isNull,
      );
    });

    test('safar javobidan o\'qiladi va birlashtirishda saqlanadi', () {
      final withCar = Ride.fromJson(const {
        'id': 'r-1',
        'status': 'active',
        'car': {'brand': 'Lacetti', 'license_plate': '01 A 555 BB'},
      });
      final withoutCar = Ride.fromJson(const {'id': 'r-1', 'status': 'active'});

      expect(withCar.car?.plate, '01 A 555 BB');
      // Yangi javobda mashina kelmasa eskisi saqlanadi.
      expect(withoutCar.mergedWith(withCar).car?.plate, '01 A 555 BB');
    });
  });

  group('Ride.mergedWith', () {
    /// Qidiruvdan kelgan to'liq safar: haydovchi bor.
    final fromSearch = Ride.fromJson(const {
      'id': 'r-1',
      'origin_address': 'Toshkent',
      'origin_lat': 41.2995,
      'origin_lon': 69.2401,
      'destination_address': 'Buxoro',
      'destination_lat': 39.7747,
      'destination_lon': 64.4286,
      'departure_time': '2026-07-30T09:00:00+05:00',
      'total_seats': 4,
      'available_seats': 2,
      'price_per_seat': 200000,
      'status': 'active',
      'no_smoking': true,
      'driver': {'id': 'd-1', 'name': 'Aziz', 'rating': 4.8},
    });

    test('driver kelmasa eskisi saqlanadi (ism "Haydovchi" ga aylanmaydi)', () {
      // Jonlida `GET /rides/{id}` shunday javob berdi: driver yo'q.
      final fresh = Ride.fromJson(const {
        'id': 'r-1',
        'origin_address': 'Toshkent',
        'origin_lat': 41.2995,
        'origin_lon': 69.2401,
        'destination_address': 'Buxoro',
        'destination_lat': 39.7747,
        'destination_lon': 64.4286,
        'total_seats': 4,
        'available_seats': 1,
        'price_per_seat': 200000,
        'status': 'in_progress',
      });

      final merged = fresh.mergedWith(fromSearch);

      // Haydovchi eskisidan — usiz baholash tugmasi umuman chiqmasdi.
      expect(merged.driver?.id, 'd-1');
      expect(merged.driver?.name, 'Aziz');
      // Yangilashning maqsadi — holat va o'rindiq YANGISIDAN.
      expect(merged.status, RideStatus.inProgress);
      expect(merged.availableSeats, 1);
      // Kelmagan vaqt eskisidan tiklanadi.
      expect(merged.departureTime, isNotNull);
    });

    test('driver qisman kelsa maydonlar to\'ldiriladi', () {
      final fresh = Ride.fromJson(const {
        'id': 'r-1',
        'status': 'active',
        'driver': {'id': 'd-1'},
      });

      final merged = fresh.mergedWith(fromSearch);

      expect(merged.driver?.id, 'd-1');
      expect(merged.driver?.name, 'Aziz');
      expect(merged.driver?.rating, 4.8);
    });

    test('belgilar va jins sharti ATAYIN eskisidan olinmaydi', () {
      final fresh = Ride.fromJson(const {
        'id': 'r-1',
        'status': 'active',
        'available_seats': 2,
      });

      final merged = fresh.mergedWith(fromSearch);

      // Haydovchi shartni olib tashlagan bo'lishi mumkin — eskisini
      // ko'rsatib qo'yish yo'qolgan belgidan battar.
      expect(merged.noSmoking, isFalse);
      expect(merged.genderRestriction, isNull);
    });

    test('eski safar bo\'lmasa yangisi o\'zgarishsiz qaytadi', () {
      expect(fromSearch.mergedWith(null), same(fromSearch));
    });
  });
}
