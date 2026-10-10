import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/money_input.dart';

/// Narx maydonи formatlashi (egasi, 2026-08-20: "50000" -> "50 000").
void main() {
  test('formatMoneyInput minglarni probel bilan ajratadi', () {
    expect(formatMoneyInput(50000), '50 000');
    expect(formatMoneyInput(1500000), '1 500 000');
    expect(formatMoneyInput(999), '999');
    expect(formatMoneyInput(0), '0');
  });

  test('parseMoney probel/harflarni tashlaydi', () {
    expect(parseMoney('50 000'), 50000.0);
    expect(parseMoney('1 500 000 so\'m'), 1500000.0);
    expect(parseMoney(''), isNull);
    expect(parseMoney('abc'), isNull);
  });
}
