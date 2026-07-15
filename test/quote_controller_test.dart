import 'package:exchange_app/quote_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('addRow auto-selects the new line once a second line exists', () {
    final controller = QuoteController();
    expect(controller.selectedRowIndex, isNull);
    expect(controller.grandEditable, isTrue); // implicit single-row editing

    controller.addRow(name: 'SGD', qty: 1, rate: 60);
    expect(controller.selectedRowIndex, 1);
    expect(controller.grandEditable, isTrue);
  });

  test('editing the total for the selected row solves only that row, holding others fixed', () {
    final controller = QuoteController();

    // Row 0: USD 500 * 95 = 47500, already "spent".
    controller.rows[0].name.text = 'USD';
    controller.rows[0].qty.text = '500';
    controller.rows[0].rate.text = '95';
    controller.recalculate();

    // Row 1: SGD at a known rate — addRow() auto-selects it.
    controller.addRow(name: 'SGD', qty: 1, rate: 60);
    expect(controller.selectedRowIndex, 1);

    // Target total corresponding to SGD qty = 200:
    // cnTotal = 47500 + 200*60 = 59500; GST at that slab = 45 + 34500*0.0018 = 107.1 -> rounds to 107.
    // grand = 59500 + 107 = 59607.
    controller.beginGrandEdit();
    controller.grandCtrl.text = '59607';
    controller.endGrandEdit();

    // Row 0 (already-spent line) must stay untouched.
    expect(controller.rows[0].qtyValue, 500);
    expect(controller.rows[0].rateValue, 95);

    // Row 1 (selected line) should absorb the remainder: ~200.
    expect(controller.rows[1].qtyValue, closeTo(200, 0.5));

    // The overall GST/charges formula must still apply to the combined total.
    expect(controller.totals.grand, closeTo(59607, 1));
  });

  test('grand total is not editable when multiple rows exist and none is selected', () {
    final controller = QuoteController();
    controller.addRow(name: 'SGD', qty: 1, rate: 60);
    controller.selectedRowIndex = null;
    expect(controller.grandEditable, isFalse);
  });

  test('removing the selected row clears the selection', () {
    final controller = QuoteController();
    controller.addRow(name: 'SGD', qty: 1, rate: 60);
    expect(controller.selectedRowIndex, 1);

    controller.removeRow(1);
    expect(controller.selectedRowIndex, isNull);
    expect(controller.rows.length, 1);
  });
}
