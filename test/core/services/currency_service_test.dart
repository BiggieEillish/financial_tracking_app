import 'package:flutter_test/flutter_test.dart';
import 'package:financial_planner_ui_demo/core/services/currency_service.dart';

void main() {
  late CurrencyService currencyService;

  setUp(() {
    currencyService = CurrencyService();
  });

  group('CurrencyService - convert', () {
    test('should return same amount when converting same currency', () {
      final amount = 100.0;
      final result = currencyService.convert(amount, 'MYR', 'MYR');
      expect(result, equals(amount));
    });

    test('should convert 1 USD to 4.47 MYR', () {
      final result = currencyService.convert(1.0, 'USD', 'MYR');
      expect(result, equals(4.47));
    });

    test('should convert 1 MYR to approximately 0.224 USD', () {
      final result = currencyService.convert(1.0, 'MYR', 'USD');
      // 1 MYR = 1 / 4.47 USD ≈ 0.22371...
      expect(result, closeTo(1.0 / 4.47, 0.0001));
    });

    test('should convert 100 USD to 447 MYR', () {
      final result = currencyService.convert(100.0, 'USD', 'MYR');
      expect(result, equals(447.0));
    });

    test('should convert USD to EUR via MYR base', () {
      // 1 USD = 4.47 MYR
      // 1 EUR = 4.85 MYR
      // 1 USD = 4.47 / 4.85 EUR ≈ 0.9216...
      final result = currencyService.convert(1.0, 'USD', 'EUR');
      expect(result, closeTo(4.47 / 4.85, 0.0001));
    });

    test('should convert EUR to GBP via MYR base', () {
      // 1 EUR = 4.85 MYR
      // 1 GBP = 5.65 MYR
      // 1 EUR = 4.85 / 5.65 GBP ≈ 0.8584...
      final result = currencyService.convert(1.0, 'EUR', 'GBP');
      expect(result, closeTo(4.85 / 5.65, 0.0001));
    });

    test('should convert 1000 JPY to 30 MYR', () {
      // 1 JPY = 0.030 MYR
      // 1000 JPY = 30 MYR
      final result = currencyService.convert(1000.0, 'JPY', 'MYR');
      expect(result, equals(30.0));
    });

    test('should convert CAD to AUD via MYR base', () {
      // 1 CAD = 3.30 MYR
      // 1 AUD = 2.90 MYR
      // 1 CAD = 3.30 / 2.90 AUD ≈ 1.1379...
      final result = currencyService.convert(1.0, 'CAD', 'AUD');
      expect(result, closeTo(3.30 / 2.90, 0.0001));
    });

    test('should handle decimal amounts correctly', () {
      final result = currencyService.convert(45.67, 'USD', 'MYR');
      expect(result, closeTo(45.67 * 4.47, 0.01));
    });

    test('should throw ArgumentError for unsupported from currency', () {
      expect(
        () => currencyService.convert(100.0, 'XXX', 'MYR'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for unsupported to currency', () {
      expect(
        () => currencyService.convert(100.0, 'MYR', 'XXX'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('CurrencyService - getRate', () {
    test('should return 1.0 for same currency', () {
      final rate = currencyService.getRate('MYR', 'MYR');
      expect(rate, equals(1.0));
    });

    test('should return correct rate for USD to MYR', () {
      final rate = currencyService.getRate('USD', 'MYR');
      expect(rate, equals(4.47));
    });

    test('should return correct rate for MYR to USD', () {
      final rate = currencyService.getRate('MYR', 'USD');
      expect(rate, closeTo(1.0 / 4.47, 0.0001));
    });

    test('should return correct rate for EUR to GBP', () {
      // 1 EUR = 4.85 MYR, 1 GBP = 5.65 MYR
      // rate = 4.85 / 5.65
      final rate = currencyService.getRate('EUR', 'GBP');
      expect(rate, closeTo(4.85 / 5.65, 0.0001));
    });

    test('should throw ArgumentError with correct message for unsupported from currency', () {
      expect(
        () => currencyService.getRate('XXX', 'MYR'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unsupported currency: XXX'),
          ),
        ),
      );
    });

    test('should throw ArgumentError with correct message for unsupported to currency', () {
      expect(
        () => currencyService.getRate('MYR', 'YYY'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unsupported currency: YYY'),
          ),
        ),
      );
    });
  });

  group('CurrencyService - getSymbol', () {
    test('should return RM for MYR', () {
      final symbol = currencyService.getSymbol('MYR');
      expect(symbol, equals('RM'));
    });

    test('should return \$ for USD', () {
      final symbol = currencyService.getSymbol('USD');
      expect(symbol, equals('\$'));
    });

    test('should return € for EUR', () {
      final symbol = currencyService.getSymbol('EUR');
      expect(symbol, equals('\u20AC'));
    });

    test('should return £ for GBP', () {
      final symbol = currencyService.getSymbol('GBP');
      expect(symbol, equals('\u00A3'));
    });

    test('should return ¥ for JPY', () {
      final symbol = currencyService.getSymbol('JPY');
      expect(symbol, equals('\u00A5'));
    });

    test('should return C\$ for CAD', () {
      final symbol = currencyService.getSymbol('CAD');
      expect(symbol, equals('C\$'));
    });

    test('should return A\$ for AUD', () {
      final symbol = currencyService.getSymbol('AUD');
      expect(symbol, equals('A\$'));
    });

    test('should return CHF for CHF', () {
      final symbol = currencyService.getSymbol('CHF');
      expect(symbol, equals('CHF'));
    });

    test('should return ¥ for CNY', () {
      final symbol = currencyService.getSymbol('CNY');
      expect(symbol, equals('\u00A5'));
    });

    test('should return ₹ for INR', () {
      final symbol = currencyService.getSymbol('INR');
      expect(symbol, equals('\u20B9'));
    });

    test('should return MX\$ for MXN', () {
      final symbol = currencyService.getSymbol('MXN');
      expect(symbol, equals('MX\$'));
    });

    test('should return currency code for unknown currency', () {
      final symbol = currencyService.getSymbol('UNKNOWN');
      expect(symbol, equals('UNKNOWN'));
    });

    test('should return currency code for empty string', () {
      final symbol = currencyService.getSymbol('');
      expect(symbol, equals(''));
    });
  });

  group('CurrencyService - formatAmount', () {
    test('should format MYR amount correctly', () {
      final formatted = currencyService.formatAmount(100.0, 'MYR');
      expect(formatted, equals('RM 100.00'));
    });

    test('should format USD amount correctly', () {
      final formatted = currencyService.formatAmount(45.67, 'USD');
      expect(formatted, equals('\$ 45.67'));
    });

    test('should format EUR amount correctly', () {
      final formatted = currencyService.formatAmount(123.45, 'EUR');
      expect(formatted, equals('\u20AC 123.45'));
    });

    test('should format GBP amount correctly', () {
      final formatted = currencyService.formatAmount(78.90, 'GBP');
      expect(formatted, equals('\u00A3 78.90'));
    });

    test('should format amount with 2 decimal places', () {
      final formatted = currencyService.formatAmount(100.1, 'MYR');
      expect(formatted, equals('RM 100.10'));
    });

    test('should round amount to 2 decimal places', () {
      final formatted = currencyService.formatAmount(100.126, 'MYR');
      expect(formatted, equals('RM 100.13'));
    });

    test('should format zero amount correctly', () {
      final formatted = currencyService.formatAmount(0.0, 'MYR');
      expect(formatted, equals('RM 0.00'));
    });

    test('should format negative amount correctly', () {
      final formatted = currencyService.formatAmount(-50.25, 'USD');
      expect(formatted, equals('\$ -50.25'));
    });

    test('should format large amount correctly', () {
      final formatted = currencyService.formatAmount(999999.99, 'MYR');
      expect(formatted, equals('RM 999999.99'));
    });

    test('should use currency code for unknown currency symbol', () {
      final formatted = currencyService.formatAmount(100.0, 'UNKNOWN');
      expect(formatted, equals('UNKNOWN 100.00'));
    });
  });

  group('CurrencyService - singleton pattern', () {
    test('should return same instance', () {
      final instance1 = CurrencyService();
      final instance2 = CurrencyService();
      expect(identical(instance1, instance2), isTrue);
    });
  });
}
