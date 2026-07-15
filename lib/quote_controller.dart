import 'package:flutter/material.dart';

import 'calculator.dart';
import 'models.dart';
import 'utils.dart';

class LineRowControllers {
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController rate;

  /// qty/rate are nullable: null means "no real value yet" so the field
  /// starts empty and shows its hint text, matching how the currency field
  /// shows "USD" as a hint rather than a real pre-filled value. Passing an
  /// actual number (e.g. when reusing a saved quote) fills in a real value.
  LineRowControllers({String name = '', double? qty, double? rate})
      : name = TextEditingController(text: name),
        qty = TextEditingController(text: qty == null ? '' : formatQty(qty)),
        rate = TextEditingController(text: rate == null ? '' : formatQty(rate));

  double get qtyValue => double.tryParse(qty.text) ?? 0;
  double get rateValue => double.tryParse(rate.text) ?? 0;
  double get amount => qtyValue * rateValue;

  void dispose() {
    name.dispose();
    qty.dispose();
    rate.dispose();
  }
}

class QuoteController extends ChangeNotifier {
  final List<LineRowControllers> rows = [];
  final TextEditingController serviceCtrl = TextEditingController();
  final TextEditingController grandCtrl = TextEditingController(text: '0');
  String dealType = 'sale';
  bool noCharges = false;
  bool isEditingGrand = false;
  bool _reverseUpdate = false;

  /// When multiple currency lines exist, editing "Total Payable" needs to
  /// know which line should absorb the difference. Null means "none picked
  /// yet" (editing is disabled) unless there's exactly one row, in which
  /// case that row is used implicitly.
  int? selectedRowIndex;

  QuoteTotals totals = QuoteTotals.empty;

  QuoteController() {
    serviceCtrl.addListener(recalculate);
    addRow();
  }

  void addRow({String name = '', double? qty, double? rate}) {
    final row = LineRowControllers(name: name, qty: qty, rate: rate);
    row.name.addListener(recalculate);
    row.qty.addListener(recalculate);
    row.rate.addListener(recalculate);
    rows.add(row);
    // Once a second line shows up, default selection to the line that was
    // just added — that's the one most likely being filled in next.
    if (rows.length > 1) {
      selectedRowIndex = rows.length - 1;
    }
    recalculate();
  }

  void selectRow(int index) {
    selectedRowIndex = index;
    notifyListeners();
  }

  void removeRow(int index) {
    rows[index].dispose();
    rows.removeAt(index);
    if (rows.isEmpty) {
      selectedRowIndex = null;
      addRow();
      return;
    }

    if (selectedRowIndex != null) {
      if (selectedRowIndex == index) {
        selectedRowIndex = null;
      } else if (selectedRowIndex! > index) {
        selectedRowIndex = selectedRowIndex! - 1;
      }
    }
    if (rows.length <= 1) selectedRowIndex = null;
    recalculate();
  }

  void setDealType(String type) {
    dealType = type == 'purchase' ? 'purchase' : 'sale';
    recalculate();
  }

  void setNoCharges(bool value) {
    noCharges = value;
    recalculate();
  }

  void beginGrandEdit() {
    isEditingGrand = true;
  }

  void endGrandEdit() {
    isEditingGrand = false;
    _calculateFromGrand();
  }

  void _calculateFromGrand() {
    if (_reverseUpdate) return;

    final targetIndex = rows.length == 1 ? 0 : selectedRowIndex;
    if (targetIndex == null || targetIndex >= rows.length) {
      recalculate();
      return;
    }

    final rate = rows[targetIndex].rateValue;
    if (rate == 0) {
      recalculate();
      return;
    }

    // The GST/charges formula always applies to the combined CN total across
    // every line, never per-line — solveCnTotalForGrand already gives us
    // that combined total for the requested grand total. The other lines'
    // amounts are already "spent", so only the remainder is this line's job.
    double fixedAmount = 0;
    for (int i = 0; i < rows.length; i += 1) {
      if (i != targetIndex) fixedAmount += rows[i].amount;
    }

    final targetGrand = double.tryParse(grandCtrl.text) ?? 0;
    final service = double.tryParse(serviceCtrl.text) ?? 0;
    final cnTotal = solveCnTotalForGrand(targetGrand, service, dealType, noCharges: noCharges);
    final qty = (cnTotal - fixedAmount) / rate;

    _reverseUpdate = true;
    rows[targetIndex].qty.text = formatQty(qty.isFinite && qty > 0 ? qty : 0);
    _reverseUpdate = false;
    recalculate();
  }

  void recalculate() {
    final cnTotal = rows.fold<double>(0, (sum, r) => sum + r.amount);
    final service = double.tryParse(serviceCtrl.text) ?? 0;

    totals = computeTotals(cnTotal: cnTotal, service: service, dealType: dealType, noCharges: noCharges);

    if (!isEditingGrand) {
      grandCtrl.text = totals.overLimit ? '' : formatMoney(totals.grand);
    }

    notifyListeners();
  }

  bool get grandEditable => rows.length == 1 || (selectedRowIndex != null && selectedRowIndex! < rows.length);

  void clear() {
    for (final r in rows) {
      r.dispose();
    }
    rows.clear();
    serviceCtrl.text = '';
    dealType = 'sale';
    noCharges = false;
    selectedRowIndex = null;
    addRow();
  }

  void loadExchange(Exchange exchange) {
    for (final r in rows) {
      r.dispose();
    }
    rows.clear();
    selectedRowIndex = null;

    if (exchange.items.isEmpty) {
      addRow();
    } else {
      for (final item in exchange.items) {
        addRow(name: item.name, qty: item.qty, rate: item.rate);
      }
    }

    selectedRowIndex = null;
    serviceCtrl.text = formatQty(exchange.service);
    dealType = exchange.dealType;
    noCharges = false;
    recalculate();
  }

  Exchange buildExchangeForSave() {
    final items = rows
        .map((r) => ExchangeItem(name: r.name.text, qty: r.qtyValue, rate: r.rateValue))
        .toList();

    return Exchange(
      createdAt: DateTime.now(),
      dealType: dealType,
      cnTotal: totals.cnTotal,
      service: totals.service,
      gstExchange: totals.cnGST,
      gstService: totals.serviceGST,
      grandTotal: totals.grand,
      items: items,
    );
  }

  @override
  void dispose() {
    serviceCtrl.dispose();
    grandCtrl.dispose();
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }
}
