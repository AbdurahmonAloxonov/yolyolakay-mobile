import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/cities.dart';
import 'package:yolyolakay/data/models/parcel.dart';
import 'package:yolyolakay/data/models/rating.dart';

void main() {
  /// 🔴 Bu testlar ILGARI teskarisini qo'riqlardi: "ixtiyoriy maydonlar
  /// yuborilmaydi". 2026-08-12 da qurilmada aniqlandiki backend
  /// `POST /parcels` da SAKKIZTA maydonni `required` qilgan va yubormaslik
  /// 400 beradi — ya'ni eski test buzuq xatti-harakatni qo'riqlab turgan.
  /// Endi teskarisi tekshiriladi: sakkiztasi ham HAR DOIM ketadi.
  group('CreateParcelRequest.toJson', () {
    test('backend talab qiladigan sakkiz maydon HAR DOIM yuboriladi', () {
      final json = const CreateParcelRequest(
        originLat: 41.311081,
        originLon: 69.240562,
        destinationLat: 39.6542,
        destinationLon: 66.9597,
        fromAddress: 'Toshkent',
        toAddress: 'Samarqand',
        price: 50000,
        receiverPhone: '+998901234567',
      ).toJson();

      for (final key in [
        'origin_lat',
        'origin_lon',
        'destination_lat',
        'destination_lon',
        'from_address',
        'to_address',
        'price',
        'receiver_phone',
      ]) {
        expect(json.containsKey(key), isTrue, reason: '$key yuborilmadi');
      }
      expect(json['origin_lat'], 41.311081);
      expect(json['from_address'], 'Toshkent');
      expect(json['price'], 50000);
      expect(json['receiver_phone'], '+998901234567');
    });

    /// Ixtiyoriy uchtasi (2026-08-12 da backend qo'shgan). Bo'sh bo'lsa
    /// YUBORILMAYDI: bo'sh satr "tavsif bor, lekin bo'sh" degan yolg'on
    /// holat yaratardi va haydovchi kartochkada bo'sh qator ko'rardi.
    test('size/description/deliver_by bo\'sh bo\'lsa yuborilmaydi', () {
      final json = const CreateParcelRequest(
        originLat: 41.0,
        originLon: 69.0,
        destinationLat: 39.0,
        destinationLon: 66.0,
        fromAddress: 'Toshkent',
        toAddress: 'Samarqand',
        price: 50000,
        receiverPhone: '+998901234567',
        description: '   ',
      ).toJson();

      expect(json.containsKey('size'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('deliver_by'), isFalse);
    });

    test('to\'ldirilganda uchalasi ham ketadi, deliver_by ISO8601 UTC', () {
      final json = CreateParcelRequest(
        originLat: 41.0,
        originLon: 69.0,
        destinationLat: 39.0,
        destinationLon: 66.0,
        fromAddress: 'Toshkent',
        toAddress: 'Samarqand',
        price: 50000,
        receiverPhone: '+998901234567',
        size: 'medium',
        description: '  hujjatlar  ',
        deliverBy: DateTime.utc(2026, 8, 20, 12),
      ).toJson();

      expect(json['size'], 'medium');
      // Chetlaridagi bo'shliqlar kesiladi.
      expect(json['description'], 'hujjatlar');
      expect(json['deliver_by'], '2026-08-20T12:00:00.000Z');
    });

    test('Parcel.fromJson yangi maydonlarni o\'qiydi', () {
      final p = Parcel.fromJson(const {
        'id': 'p-9',
        'origin_lat': 41.0,
        'origin_lon': 69.0,
        'destination_lat': 39.0,
        'destination_lon': 66.0,
        'size': 'large',
        'description': 'chamadon',
        'deliver_by': '2026-08-20T12:00:00Z',
      });
      expect(p.size, 'large');
      expect(p.description, 'chamadon');
      expect(p.deliverBy?.toUtc().day, 20);
    });
  });

  group('Parcel.fromJson', () {
    test('PascalCase va snake_case ikkalasini o\'qiydi', () {
      final a = Parcel.fromJson(const {
        'ID': 'p-1',
        'OriginLat': 41.3,
        'OriginLon': 69.2,
        'DestinationLat': 39.6,
        'DestinationLon': 66.9,
        'DriverID': 'd-1',
      });
      final b = Parcel.fromJson(const {
        'id': 'p-1',
        'origin_lat': 41.3,
        'origin_lon': 69.2,
        'destination_lat': 39.6,
        'destination_lon': 66.9,
        'driver_id': 'd-1',
      });

      expect(a.id, b.id);
      expect(a.originLat, b.originLat);
      expect(a.isTaken, isTrue);
      expect(b.isTaken, isTrue);
    });

    test('haydovchisiz posilka bo\'sh deb hisoblanadi', () {
      final parcel = Parcel.fromJson(const {'id': 'p-2', 'driver_id': ''});
      expect(parcel.isTaken, isFalse);
    });
  });

  group('SubmitFeedbackRequest.toJson', () {
    test('reviewer_id YUBORILMAYDI (backend tokendan oladi)', () {
      final json = const SubmitFeedbackRequest(
        rideId: 'r-1',
        revieweeId: 'u-2',
        score: 5,
      ).toJson();

      expect(json.keys, containsAll(['ride_id', 'reviewee_id', 'score']));
      expect(json.containsKey('reviewer_id'), isFalse);
      expect(json.containsKey('comment'), isFalse);
    });

    test('izoh berilsa qo\'shiladi', () {
      final json = const SubmitFeedbackRequest(
        rideId: 'r-1',
        revieweeId: 'u-2',
        score: 4,
        comment: 'Rahmat',
      ).toJson();
      expect(json['comment'], 'Rahmat');
    });
  });

  group('nearestPlace', () {
    // Posilka javobida manzil MATNI yo'q — nom koordinatadan topiladi.
    test('koordinatadan shahar nomini topadi', () {
      expect(nearestPlace(41.311081, 69.240562)?.name, 'Toshkent');
      expect(nearestPlace(39.6542, 66.9597)?.name, 'Samarqand');
    });

    test('juda uzoq nuqta uchun null (noto\'g\'ri nom ko\'rsatilmasin)', () {
      // Moskva — O'zbekistondan tashqarida.
      expect(nearestPlace(55.7558, 37.6173), isNull);
    });
  });
}
