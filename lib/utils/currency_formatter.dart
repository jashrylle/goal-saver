import 'package:intl/intl.dart';

/// Currency formatter with support for multiple currencies.
/// Handles localization-ready currency formatting.
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
  };

  static String _currentCurrency = 'PHP';

  static void setCurrency(String currencyCode) {
    if (_currencies.containsKey(currencyCode)) {
      _currentCurrency = currencyCode;
    }
  }

  static void registerCurrency(CurrencyConfig config) {
    _currencies[config.code] = config;
  }

  static String getCurrentCurrency() => _currentCurrency;

  static CurrencyConfig? getCurrencyConfig([String? currencyCode]) {
    return _currencies[currencyCode ?? _currentCurrency];
  }

  static String format(double amount, {String? currencyCode}) {
    final config = _currencies[currencyCode ?? _currentCurrency];
    if (config == null) return amount.toStringAsFixed(2);

    try {
      final formatter = NumberFormat.currency(
        locale: config.locale,
        symbol: config.symbol,
        decimalDigits: config.decimalPlaces,
      );
      return formatter.format(amount);
    } catch (_) {
      return '${config.symbol}${amount.toStringAsFixed(config.decimalPlaces)}';
    }
  }

  static String formatCompact(double amount, {String? currencyCode}) {
    final config = _currencies[currencyCode ?? _currentCurrency];
    if (config == null) return amount.toStringAsFixed(2);

    if (amount >= 1000000) {
      return '${config.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${config.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${config.symbol}${amount.toStringAsFixed(config.decimalPlaces)}';
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
