String formatQty(double value) {
  if (value.isNaN || !value.isFinite) return '';
  // 6 decimal places, not 4: low-value currencies (e.g. VND, IDR trade
  // around 0.003-0.005 INR) need that extra precision, or the displayed
  // rate rounds away enough of itself that qty × displayed-rate stops
  // matching the actual stored amount once quantities run into the millions.
  var fixed = value.toStringAsFixed(6);
  fixed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return fixed;
}

String formatMoney(double value) {
  if (value.isNaN || !value.isFinite) return '0';
  return value.round().toString();
}

String formatMoney2(double value) {
  if (value.isNaN || !value.isFinite) return '0.00';
  return value.toStringAsFixed(2);
}

String formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $h:$min';
}
