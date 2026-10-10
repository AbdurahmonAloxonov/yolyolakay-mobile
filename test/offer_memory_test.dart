import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/data/offer_memory.dart';

/// SAVDOLASHISH — haydovchi narxni qaytarganda yo'lovchi buni bilishi kerak.
///
/// 🔴 Jonli o'lchov (2026-08-13): backend bronning `offered_price` maydonini
/// ALMASHTIRADI, lekin kim oxirgi taklif qilganini bildiradigan maydon yo'q.
/// Ya'ni yo'lovchi ekranida narx jimgina o'zgaradi. Shu sabab o'z taklifimizni
/// qurilmada eslab qolamiz va taqqoslaymiz.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfferMemory memory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    memory = OfferMemory(await SharedPreferences.getInstance());
  });

  test('o\'z taklifim eslab qolinadi', () async {
    await memory.remember('b-1', 45000);
    expect(memory.mine('b-1'), 45000);
  });

  test('narx O\'ZGARMAGAN bo\'lsa — haydovchi tegmagan', () async {
    await memory.remember('b-1', 45000);
    expect(memory.driverChanged('b-1', 45000), isFalse);
  });

  test('narx boshqa bo\'lsa — HAYDOVCHI qaytargan', () async {
    await memory.remember('b-1', 45000);
    expect(memory.driverChanged('b-1', 55000), isTrue);
  });

  test('o\'z taklifim yozilmagan bo\'lsa — BILIB BO\'LMAYDI', () {
    // Bron saytdan yoki boshqa telefondan qilingan bo'lishi mumkin —
    // o'shanda "haydovchi o'zgartirdi" deb aytish yolg'on bo'lardi.
    expect(memory.driverChanged('b-yangi', 55000), isNull);
  });

  test('narx umuman kelmasa — BILIB BO\'LMAYDI', () async {
    await memory.remember('b-1', 45000);
    expect(memory.driverChanged('b-1', null), isNull);
  });
}
