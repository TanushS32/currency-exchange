String formatQty(double value) {
  if (value.isNaN || !value.isFinite) return '';
  var fixed = value.toStringAsFixed(4);
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
