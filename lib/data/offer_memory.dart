import 'package:shared_preferences/shared_preferences.dart';

/// Yo'lovchining O'ZI taklif qilgan narxi — qurilmada eslab qolinadi.
///
/// NEGA KERAK (2026-08-13 jonli o'lchov): haydovchi narxni qaytarganda
/// backend bronning `offered_price` maydonini ALMASHTIRADI, lekin kim
/// oxirgi taklif qilganini bildiradigan maydon yo'q (`last_offer_by`
/// javobda ham, swaggerda ham yo'q). Ya'ni yo'lovchi ekranida narx jimgina
/// o'zgaradi va u buni "men shunday yozganmidim?" deb o'ylaydi.
///
/// Shu sabab o'z taklifimizni yozib qo'yamiz: keyin taqqoslash orqali
/// "haydovchi boshqa narx taklif qildi" deb aniq aytish mumkin.
///
/// Backend `last_offer_by` (yoki taklif tarixi) bersa, bu xotira keraksiz
/// bo'ladi — xatda so'ralgan.
class OfferMemory {
  const OfferMemory(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String bookingId) => 'my_offer_$bookingId';

  Future<void> remember(String bookingId, double price) =>
      _prefs.setDouble(_key(bookingId), price);

  /// Shu bron uchun O'ZIM taklif qilgan narx (bo'lmasa `null`).
  double? mine(String bookingId) => _prefs.getDouble(_key(bookingId));

  /// Haydovchi boshqa narx taklif qildimi?
  ///
  /// `null` — bilib bo'lmaydi (o'z taklifimiz yozilmagan: bron boshqa
  /// qurilmadan yoki saytdan qilingan).
  bool? driverChanged(String bookingId, double? current) {
    final mine = this.mine(bookingId);
    if (mine == null || current == null) return null;
    return (current - mine).abs() > 0.5;
  }
}
