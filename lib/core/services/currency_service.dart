import '../../shared/constants/app_constants.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // Exchange rates: how many MYR = 1 unit of foreign currency
  static const Map<String, double> _exchangeRates = {
    'MYR': 1.0,
    'USD': 4.47,
    'EUR': 4.85,
    'GBP': 5.65,
    'JPY': 0.030,
    'CAD': 3.30,
    'AUD': 2.90,
    'CHF': 5.05,
    'CNY': 0.62,
    'INR': 0.053,
    'MXN': 0.26,
  };

  /// Converts [amount] from [fromCurrency] to [toCurrency].
  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    final rate = getRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  /// Returns the conversion rate from [fromCurrency] to [toCurrency].
  ///
  /// For example, `getRate('USD', 'MYR')` returns 4.47, meaning
  /// 1 USD = 4.47 MYR.
  double getRate(String fromCurrency, String toCurrency) {
    final fromRate = _exchangeRates[fromCurrency];
    final toRate = _exchangeRates[toCurrency];

    if (fromRate == null || toRate == null) {
      throw ArgumentError(
        'Unsupported currency: ${fromRate == null ? fromCurrency : toCurrency}',
      );
    }

    // Convert via MYR as the base currency:
    // fromCurrency -> MYR -> toCurrency
    // 1 unit of fromCurrency = fromRate MYR
    // 1 MYR = 1/toRate units of toCurrency
    return fromRate / toRate;
  }

  /// Returns the symbol for the given [currencyCode],
  /// e.g. 'MYR' -> 'RM', 'USD' -> '\$'.
  String getSymbol(String currencyCode) {
    return AppConstants.currencySymbols[currencyCode] ?? currencyCode;
  }

  /// Formats [amount] with the appropriate currency symbol,
  /// e.g. "RM 45.00" or "\$10.06".
  String formatAmount(double amount, String currency) {
    final symbol = getSymbol(currency);
    return '$symbol ${amount.toStringAsFixed(2)}';
  }
}
