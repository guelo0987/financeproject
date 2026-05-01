import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../preferences/app_preferences.dart';

String currencyPrefix(String currency) {
  final normalized = currency.trim().toUpperCase();
  switch (normalized) {
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
      return normalized.isEmpty
          ? '${AppFormattingPreferences.currencyCode}\$'
          : '$normalized\$';
  }
}

String currentCurrencyPrefix() {
  return currencyPrefix(AppFormattingPreferences.currencyCode);
}

String currentLocaleTag() {
  return AppFormattingPreferences.localeTag;
}

String moneyLocaleForCurrency(String currency) {
  final normalized = currency.trim().toUpperCase();
  if (normalized == 'DOP') return 'en_US';
  return AppFormattingPreferences.localeTag;
}

double? parseMoneyInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final cleaned = trimmed
      .replaceAll(RegExp(r'[^0-9,.\-]'), '')
      .replaceAll(' ', '');
  if (cleaned.isEmpty || cleaned == '-' || cleaned == '.' || cleaned == ',') {
    return null;
  }

  final lastComma = cleaned.lastIndexOf(',');
  final lastDot = cleaned.lastIndexOf('.');
  String normalized = cleaned;

  if (lastComma >= 0 && lastDot >= 0) {
    final decimalSeparator = lastComma > lastDot ? ',' : '.';
    final groupSeparator = decimalSeparator == ',' ? '.' : ',';
    normalized = cleaned
        .replaceAll(groupSeparator, '')
        .replaceAll(decimalSeparator, '.');
  } else if (lastComma >= 0) {
    final parts = cleaned.split(',');
    final lastPart = parts.last;
    final commaLooksDecimal =
        parts.length == 2 && lastPart.isNotEmpty && lastPart.length <= 2;
    normalized = commaLooksDecimal
        ? cleaned.replaceAll(',', '.')
        : cleaned.replaceAll(',', '');
  } else {
    final parts = cleaned.split('.');
    final lastPart = parts.last;
    final dotLooksGrouped =
        parts.length > 2 || (parts.length == 2 && lastPart.length == 3);
    if (dotLooksGrouped) {
      normalized = cleaned.replaceAll('.', '');
    }
  }

  return double.tryParse(normalized);
}

String formatMoneyInputValue(double value, {String currency = ''}) {
  final effectiveCurrency = currency.trim().isEmpty
      ? AppFormattingPreferences.currencyCode
      : currency.trim().toUpperCase();
  return NumberFormat(
    '#,##0.##',
    moneyLocaleForCurrency(effectiveCurrency),
  ).format(value.abs());
}

class ThousandsNumberInputFormatter extends TextInputFormatter {
  const ThousandsNumberInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final limited = digitsOnly.length > maxDigits
        ? digitsOnly.substring(0, maxDigits)
        : digitsOnly;
    final normalized = limited.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = normalized.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
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
    moneyLocaleForCurrency(effectiveCurrency),
  );
  final prefix = currencyPrefix(effectiveCurrency);
  final base = '$prefix${formatter.format(value.abs())}';

  if (signed) {
    if (value > 0) return '+$base';
    if (value < 0) return '-$base';
  }

  return value < 0 ? '-$base' : base;
}

/// Formats a double value using the active app currency.
String fmtRD(double val) => formatMoney(val);

/// Formats with sign prefix (+ for income, - for expense) using app currency.
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

String formatDateByPattern(DateTime value, {String pattern = 'd MMM yyyy'}) {
  return DateFormat(pattern, AppFormattingPreferences.localeTag).format(value);
}
