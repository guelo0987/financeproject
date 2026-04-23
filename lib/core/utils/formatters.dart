import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../preferences/app_preferences.dart';

String currencyPrefix(String currency) {
  switch (currency.trim().toUpperCase()) {
    case 'USD':
      return 'US\$';
    case 'EUR':
      return '€';
    case 'MXN':
      return 'MX\$';
    case 'COP':
      return 'COP\$';
    case 'ARS':
      return 'AR\$';
    case 'CLP':
      return 'CLP\$';
    case 'DOP':
      return 'RD\$';
    default:
      return 'RD\$';
  }
}

String currentCurrencyPrefix() {
  return currencyPrefix(AppFormattingPreferences.currencyCode);
}

String currentLocaleTag() {
  return AppFormattingPreferences.localeTag;
}

String formatMoney(
  double value, {
  String currency = '',
  bool signed = false,
  bool keepDecimals = false,
}) {
  final effectiveCurrency = currency.trim().isEmpty
      ? AppFormattingPreferences.currencyCode
      : currency.trim().toUpperCase();
  final formatter = NumberFormat(
    keepDecimals ? '#,##0.00' : '#,##0',
    AppFormattingPreferences.localeTag,
  );
  final prefix = currencyPrefix(effectiveCurrency);
  final base = '$prefix${formatter.format(value.abs())}';

  if (signed) {
    if (value > 0) return '+$base';
    if (value < 0) return '-$base';
  }

  return value < 0 ? '-$base' : base;
}

/// Formats a double value as Dominican Peso (RD$).
String fmtRD(double val) => formatMoney(val);

/// Formats with sign prefix (+ for income, - for expense).
String fmtRDSigned(double val) => formatMoney(val, signed: true);

DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime? parseDateOnly(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final match = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
  if (match != null) {
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  return dateOnly(parsed.toLocal());
}

DateTimeRange normalizeDateRange(DateTimeRange range) {
  return DateTimeRange(
    start: dateOnly(range.start),
    end: DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    ),
  );
}

String formatDateByPattern(
  DateTime value, {
  String pattern = 'd MMM yyyy',
}) {
  return DateFormat(pattern, AppFormattingPreferences.localeTag).format(value);
}
