import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Service for fetching and caching live currency exchange rates.
///
/// Uses the Frankfurter API (free, no key required).
/// Rates are cached in secure storage with a timestamp;
/// stale caches (>1 hour old) are refreshed on next access.
/// Never blocks the UI — falls back to cached rates on failure.
class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  static const String _baseUrl = 'https://api.frankfurter.app';
  static const Duration _cacheTtl = Duration(hours: 1);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, double>? _cachedRates;
  DateTime? _lastFetchTime;
  String _baseCurrency = 'PHP';

  /// Latest fetched rates (base → target).
  Map<String, double>? get latestRates => _cachedRates;

  /// When rates were last successfully fetched.
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Human-readable "last updated" string.
  String get lastUpdatedLabel {
    if (_lastFetchTime == null) return 'No rates fetched yet';
    final diff = DateTime.now().difference(_lastFetchTime!);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hr ago';
    return 'Updated ${diff.inDays} days ago';
  }

  /// Whether cached rates are still fresh.
  bool get _isCacheFresh =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheTtl;

  /// Fetch latest rates relative to [baseCurrency].
  ///
  /// Returns cached rates if fresh, otherwise attempts a network fetch.
  /// On network failure, returns last cached rates (never throws).
  Future<Map<String, double>?> fetchRates({String? baseCurrency}) async {
    final base = baseCurrency ?? _baseCurrency;
    _baseCurrency = base;

    // Return fresh cache immediately
    if (_isCacheFresh && _cachedRates != null) {
      return _cachedRates;
    }

    // Try loading from persistent cache first
    if (_cachedRates == null) {
      await _loadCachedRates();
      if (_isCacheFresh && _cachedRates != null) {
        return _cachedRates;
      }
    }

    // Fetch fresh rates from API
    try {
      final uri = Uri.parse('$_baseUrl/latest?from=$base');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final converted = <String, double>{};
        // Include the base currency itself (1:1)
        converted[base] = 1.0;
        rates.forEach((key, value) {
          converted[key] = (value as num).toDouble();
        });

        _cachedRates = converted;
        _lastFetchTime = DateTime.now();
        await _persistRates(converted);
        return converted;
      }
    } catch (e) {
      debugPrint('ExchangeRateService: Failed to fetch rates: $e');
      // Fall through to return cached rates
    }

    return _cachedRates;
  }

  /// Convert [amountInBaseCurrency] from base currency to [targetCurrency].
  ///
  /// Returns the original amount if rates are unavailable or target is base.
  double convert(double amountInBaseCurrency, String targetCurrency) {
    if (_cachedRates == null || targetCurrency == _baseCurrency) {
      return amountInBaseCurrency;
    }
    final rate = _cachedRates![targetCurrency];
    if (rate == null) return amountInBaseCurrency; // Unknown currency
    return amountInBaseCurrency * rate;
  }

  /// Convenience: convert and return a user-friendly label for the rate.
  /// e.g. "1 PHP ≈ 0.017 USD"
  String rateLabel(String targetCurrency) {
    if (_cachedRates == null) return '';
    final rate = _cachedRates![targetCurrency];
    if (rate == null) return '';
    return '1 $_baseCurrency ≈ ${rate.toStringAsFixed(3)} $targetCurrency';
  }

  /// Short rate label without the base currency prefix, e.g. "0.017 USD".
  String shortRateLabel(String targetCurrency) {
    if (_cachedRates == null) return '';
    final rate = _cachedRates![targetCurrency];
    if (rate == null) return '';
    return '${rate.toStringAsFixed(3)} $targetCurrency';
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persistRates(Map<String, double> rates) async {
    try {
      final data = {
        'rates': rates.map((k, v) => MapEntry(k, v.toString())),
        'timestamp': _lastFetchTime!.toIso8601String(),
        'baseCurrency': _baseCurrency,
      };
      await _storage.write(
        key: 'exchange_rates_cache',
        value: json.encode(data),
      );
    } catch (e) {
      debugPrint('ExchangeRateService: Failed to persist rates: $e');
    }
  }

  Future<void> _loadCachedRates() async {
    try {
      final stored = await _storage.read(key: 'exchange_rates_cache');
      if (stored == null) return;
      final data = json.decode(stored) as Map<String, dynamic>;
      final rawRates = data['rates'] as Map<String, dynamic>;
      _cachedRates = rawRates.map(
        (k, v) => MapEntry(k, double.tryParse(v as String) ?? 0.0),
      );
      _lastFetchTime = DateTime.tryParse(data['timestamp'] as String? ?? '');
      _baseCurrency = data['baseCurrency'] as String? ?? 'PHP';
    } catch (e) {
      debugPrint('ExchangeRateService: Failed to load cached rates: $e');
    }
  }
}
