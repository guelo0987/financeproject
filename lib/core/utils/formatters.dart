/// Formats a double value as Dominican Peso (RD$).
/// Handles negative values (shown without sign in some contexts).
String fmtRD(double val) {
  final absVal = val.abs();
  final formatted = absVal.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return 'RD\$$formatted';
}

/// Formats with sign prefix (+ for income, - for expense).
String fmtRDSigned(double val) {
  final prefix = val >= 0 ? '+' : '-';
  return '$prefix${fmtRD(val)}';
}
