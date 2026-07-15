import 'package:exchange_app/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeCnGst', () {
    test('flat 45 for zero/negative/small CN', () {
      expect(computeCnGst(0), 45);
      expect(computeCnGst(-10), 45);
      expect(computeCnGst(25000), 45);
    });

    test('mid slab (25k-100k) applies 0.18% above 25k', () {
      expect(computeCnGst(50000), closeTo(45 + 25000 * 0.0018, 1e-9));
    });

    test('top slab (>100k) applies 0.09% above 100k', () {
      final expected = 45 + 75000 * 0.0018 + 50000 * 0.0009;
      expect(computeCnGst(150000), closeTo(expected, 1e-9));
    });
  });

  group('computeTotals', () {
    test('sale adds rounded charges to CN total', () {
      final totals = computeTotals(cnTotal: 10000, service: 0, dealType: 'sale');
      expect(totals.cnGST, 45);
      expect(totals.chargesRounded, 45);
      expect(totals.grand, 10045);
    });

    test('purchase subtracts rounded charges from CN total', () {
      final totals = computeTotals(cnTotal: 10000, service: 0, dealType: 'purchase');
      expect(totals.grand, 9955);
    });

    test('flags overLimit above 10,00,000', () {
      final totals = computeTotals(cnTotal: 1000001, service: 0, dealType: 'sale');
      expect(totals.overLimit, isTrue);
    });

    test('noCharges zeroes GST/service and grand equals CN value', () {
      for (final dealType in ['sale', 'purchase']) {
        final totals = computeTotals(
          cnTotal: 8000,
          service: 500,
          dealType: dealType,
          noCharges: true,
        );
        expect(totals.cnGST, 0);
        expect(totals.service, 0);
        expect(totals.serviceGST, 0);
        expect(totals.chargesRounded, 0);
        expect(totals.grand, 8000);
      }
    });
  });

  group('solveCnTotalForGrand (reverse calc round-trips)', () {
    for (final dealType in ['sale', 'purchase']) {
      test('round-trips for $dealType', () {
        const service = 200.0;
        const originalCn = 42000.0;
        final grand = computeGrandForCn(originalCn, service, dealType);
        final solvedCn = solveCnTotalForGrand(grand, service, dealType);
        expect(solvedCn, closeTo(originalCn, 1));
      });
    }
  });
}
