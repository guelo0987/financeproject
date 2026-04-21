import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _moneyWholeFormatter = NumberFormat('#,##0', 'en_US');
final NumberFormat _moneyDecimalFormatter = NumberFormat('#,##0.00', 'en_US');

String _currencyPrefix(String currency) {
  switch (currency.trim().toUpperCase()) {
    case 'USD':
      return 'US\$';
    case 'EUR':
      return '€';
    default:
      return 'RD\$';
  }
}

String formatMoney(
  double value, {
  String currency = 'DOP',
  bool signed = false,
  bool keepDecimals = false,
}) {
  final formatter = keepDecimals
      ? _moneyDecimalFormatter
      : _moneyWholeFormatter;
  final prefix = _currencyPrefix(currency);
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
