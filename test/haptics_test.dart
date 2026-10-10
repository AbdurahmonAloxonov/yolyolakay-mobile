import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/haptics.dart';

/// HAPTIK NAQSHLAR.
///
/// 🔴 NEGA TEST: naqshning butun ma'nosi KETMA-KETLIKDA. Agar kutish
/// (`await`) tushib qolsa, uchala zarba bir vaqtda ketadi va tizim
/// ularni BITTA tebranish deb qo'shib yuboradi — ya'ni "tasdiq" va
/// "bekor" yana bir xil his qilinadi va butun ish behuda ketadi.
/// Bu xatoni ekranda ko'rib bo'lmaydi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add('${call.arguments}');
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('tasdiq — UCH zarba, KO\'TARILUVCHI', () async {
    await AppHaptics.confirmed();

    expect(calls, hasLength(3));
    expect(calls[0], contains('selectionClick'));
    expect(calls[1], contains('lightImpact'));
    expect(calls[2], contains('mediumImpact'));
  });

  test('bekor — IKKI zarba, TUSHUVCHI', () async {
    await AppHaptics.cancelled();

    expect(calls, hasLength(2));
    expect(calls[0], contains('mediumImpact'));
    expect(calls[1], contains('selectionClick'));
  });

  /// Ikki naqsh bir-biridan FARQ QILISHI — butun g'oyaning o'zi.
  test('tasdiq va bekor bir xil emas', () async {
    await AppHaptics.confirmed();
    final confirmed = List<String>.from(calls);

    calls.clear();
    await AppHaptics.cancelled();

    expect(confirmed, isNot(equals(calls)));
  });

  test('bitta zarbali amallar o\'zgarmagan', () async {
    AppHaptics.success();
    AppHaptics.notice();
    AppHaptics.heavy();
    AppHaptics.select();

    expect(calls, hasLength(4));
  });
}
