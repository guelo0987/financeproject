import 'package:flutter_test/flutter_test.dart';
import 'package:financeproject/core/utils/formatters.dart';

void main() {
  group('money formatting', () {
    test('formats DOP with comma grouping', () {
      expect(formatMoney(1234567, currency: 'DOP'), 'RD\$1,234,567');
    });

    test('parses comma grouped money input', () {
      expect(parseMoneyInput('1,234'), 1234);
      expect(parseMoneyInput('RD\$1,234.50'), 1234.5);
    });

    test('parses decimal comma input', () {
      expect(parseMoneyInput('1234,50'), 1234.5);
    });
  });
}
