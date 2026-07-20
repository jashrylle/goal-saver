import 'package:intl/intl.dart';
import '../services/exchange_rate_service.dart';

/// Currency formatter with support for multiple currencies and live exchange rates.
///
/// All goal amounts are stored in a canonical base currency (e.g. PHP).
/// Exchange rates are applied **only at display time**, never mutating stored data.
class CurrencyFormatter {
  static final Map<String, CurrencyConfig> _currencies = {
    'PHP': const CurrencyConfig(
      symbol: '\u20B1',
      code: 'PHP',
      locale: 'en_PH',
      decimalPlaces: 2,
    ),
    'USD': const CurrencyConfig(
      symbol: r'$',
      code: 'USD',
      locale: 'en_US',
      decimalPlaces: 2,
    ),
    'EUR': const CurrencyConfig(
      symbol: '\u20AC',
      code: 'EUR',
      locale: 'en_IE',
      decimalPlaces: 2,
    ),
    'GBP': const CurrencyConfig(
      symbol: '\u00A3',
      code: 'GBP',
      locale: 'en_GB',
      decimalPlaces: 2,
    ),
    'JPY': const CurrencyConfig(
      symbol: '\u00A5',
      code: 'JPY',
      locale: 'ja_JP',
      decimalPlaces: 0,
    ),
    'AUD': const CurrencyConfig(
      symbol: r'A$',
      code: 'AUD',
      locale: 'en_AU',
      decimalPlaces: 2,
    ),
    'CAD': const CurrencyConfig(
      symbol: r'CA$',
      code: 'CAD',
      locale: 'en_CA',
      decimalPlaces: 2,
    ),
    'SGD': const CurrencyConfig(
      symbol: r'S$',
      code: 'SGD',
      locale: 'en_SG',
      decimalPlaces: 2,
    ),
  };

  static String _currentCurrency = 'PHP';
  static String _baseCurrency = 'PHP';

  static void setCurrency(String currencyCode) {
    if (_currencies.containsKey(currencyCode)) {
      _currentCurrency = currencyCode;
    }
  }

  static void registerCurrency(CurrencyConfig config) {
    _currencies[config.code] = config;
  }

  static String getCurrentCurrency() => _currentCurrency;

  static String getBaseCurrency() => _baseCurrency;

  static void setBaseCurrency(String code) {
    _baseCurrency = code;
  }

  static CurrencyConfig? getCurrencyConfig([String? currencyCode]) {
    return _currencies[currencyCode ?? _currentCurrency];
  }

  /// Convert [amountInBaseCurrency] from base currency to the current display
  /// currency using the [ExchangeRateService]. Pure conversion — never mutates data.
  static double convert(double amountInBaseCurrency, {String? toCurrency}) {
    final target = toCurrency ?? _currentCurrency;
    if (target == _baseCurrency) return amountInBaseCurrency;
    return ExchangeRateService().convert(amountInBaseCurrency, target);
  }

  /// Format [amountInBaseCurrency] in the current display currency.
  ///
  /// Automatically converts using live exchange rates when the display currency
  /// differs from the base currency. All call sites (goal_card.dart,
  /// balance_overview.dart, etc.) go through this method, so conversion is
  /// transparent with zero call-site changes.
  static String format(double amountInBaseCurrency, {String? currencyCode}) {
    final targetCode = currencyCode ?? _currentCurrency;
    // Convert to display currency
    final convertedAmount = convert(amountInBaseCurrency, toCurrency: targetCode);

    final config = _currencies[targetCode];
    if (config == null) return convertedAmount.toStringAsFixed(2);

    try {
      final formatter = NumberFormat.currency(
        locale: config.locale,
        symbol: config.symbol,
        decimalDigits: config.decimalPlaces,
      );
      return formatter.format(convertedAmount);
    } catch (_) {
      return '${config.symbol}${convertedAmount.toStringAsFixed(config.decimalPlaces)}';
    }
  }

  static String formatCompact(double amountInBaseCurrency, {String? currencyCode}) {
    final targetCode = currencyCode ?? _currentCurrency;
    final convertedAmount = convert(amountInBaseCurrency, toCurrency: targetCode);
    final config = _currencies[targetCode];
    if (config == null) return convertedAmount.toStringAsFixed(2);

    if (convertedAmount >= 1000000) {
      return '${config.symbol}${(convertedAmount / 1000000).toStringAsFixed(1)}M';
    } else if (convertedAmount >= 1000) {
      return '${config.symbol}${(convertedAmount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${config.symbol}${convertedAmount.toStringAsFixed(config.decimalPlaces)}';
    }
  }

  static double parse(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[\u20B1\$\u20AC\u00A3\u00A5\s]'), '')
        .replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }

  static List<String> getAvailableCurrencies() => _currencies.keys.toList();

  static String getSymbol(String currencyCode) {
    return _currencies[currencyCode]?.symbol ?? currencyCode;
  }

  /// Get a human-readable rate label, e.g. "1 PHP ≈ 0.017 USD".
  static String rateLabel(String targetCurrency) {
    return ExchangeRateService().rateLabel(targetCurrency);
  }

  /// Whether exchange rates have been loaded.
  static bool get hasRates => ExchangeRateService().latestRates != null;

  /// Last updated label from the exchange rate service.
  static String get lastUpdatedLabel => ExchangeRateService().lastUpdatedLabel;
}

/// Configuration for a currency.
class CurrencyConfig {
  final String symbol;
  final String code;
  final String locale;
  final int decimalPlaces;

  const CurrencyConfig({
    required this.symbol,
    required this.code,
    required this.locale,
    required this.decimalPlaces,
  });
}

/// Extension on double for easy currency formatting.
extension CurrencyExtension on double {
  String toMoney([String? currencyCode]) =>
      CurrencyFormatter.format(this, currencyCode: currencyCode);

  String toCompactMoney([String? currencyCode]) =>
      CurrencyFormatter.formatCompact(this, currencyCode: currencyCode);

  String get money => CurrencyFormatter.format(this);
}

/// Extension on int for easy currency formatting.
extension IntCurrencyExtension on int {
  String toMoney([String? currencyCode]) =>
      CurrencyFormatter.format(toDouble(), currencyCode: currencyCode);

  String get money => CurrencyFormatter.format(toDouble());
}
