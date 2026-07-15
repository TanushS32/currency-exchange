/// Ports the exact GST/pricing rules from the desktop app
/// (static/app.js: computeCnGst / computeGrandForCn / solveCnTotalForGrand).
library;

const double cnLimit = 1000000;

double computeCnGst(double cnTotal) {
  if (cnTotal.isNaN || !cnTotal.isFinite || cnTotal <= 0) return 45;

  if (cnTotal <= 25000) {
    return 45;
  }
  if (cnTotal <= 100000) {
    return 45 + (cnTotal - 25000) * 0.0018;
  }
  return 45 + (100000 - 25000) * 0.0018 + (cnTotal - 100000) * 0.0009;
}

double computeGrandForCn(double cnTotal, double service, String dealType, {bool noCharges = false}) {
  if (noCharges) return cnTotal;

  final cnGST = computeCnGst(cnTotal);
  final serviceGST = service * 0.18;
  final chargesRounded = (cnGST + service + serviceGST).round();
  return dealType == 'purchase' ? cnTotal - chargesRounded : cnTotal + chargesRounded;
}

double solveCnTotalForGrand(double targetGrand, double service, String dealType, {bool noCharges = false}) {
  if (targetGrand.isNaN || !targetGrand.isFinite || targetGrand <= 0) return 0;

  if (noCharges) return targetGrand;

  final minGrand = computeGrandForCn(0, service, dealType);
  if (dealType == 'sale' && targetGrand <= minGrand) return 0;

  double low = 0;
  double high = targetGrand > 1 ? targetGrand : 1;
  int guard = 0;

  // computeGrandForCn is monotonically increasing in cnTotal for both deal
  // types (charges grow sub-linearly relative to cnTotal), so both cases
  // use the same "increasing function" bisection direction.
  while (computeGrandForCn(high, service, dealType) < targetGrand && guard < 60) {
    high *= 2;
    guard += 1;
  }

  for (int i = 0; i < 40; i += 1) {
    final mid = (low + high) / 2;
    final grand = computeGrandForCn(mid, service, dealType);
    if (grand >= targetGrand) {
      high = mid;
    } else {
      low = mid;
    }
  }

  return high;
}

class QuoteTotals {
  final double cnTotal;
  final double cnGST;
  final double service;
  final double serviceGST;
  final int chargesRounded;
  final double grand;
  final bool overLimit;

  const QuoteTotals({
    required this.cnTotal,
    required this.cnGST,
    required this.service,
    required this.serviceGST,
    required this.chargesRounded,
    required this.grand,
    required this.overLimit,
  });

  static const empty = QuoteTotals(
    cnTotal: 0,
    cnGST: 0,
    service: 0,
    serviceGST: 0,
    chargesRounded: 0,
    grand: 0,
    overLimit: false,
  );
}

QuoteTotals computeTotals({
  required double cnTotal,
  required double service,
  required String dealType,
  bool noCharges = false,
}) {
  if (cnTotal > cnLimit) {
    return QuoteTotals(
      cnTotal: cnTotal,
      cnGST: 0,
      service: service,
      serviceGST: 0,
      chargesRounded: 0,
      grand: 0,
      overLimit: true,
    );
  }

  if (noCharges) {
    return QuoteTotals(
      cnTotal: cnTotal,
      cnGST: 0,
      service: 0,
      serviceGST: 0,
      chargesRounded: 0,
      grand: cnTotal,
      overLimit: false,
    );
  }

  final cnGST = computeCnGst(cnTotal);
  final serviceGST = service * 0.18;
  final chargesRounded = (cnGST + service + serviceGST).round();
  final grand = dealType == 'purchase' ? cnTotal - chargesRounded : cnTotal + chargesRounded;

  return QuoteTotals(
    cnTotal: cnTotal,
    cnGST: cnGST,
    service: service,
    serviceGST: serviceGST,
    chargesRounded: chargesRounded,
    grand: grand,
    overLimit: false,
  );
}
