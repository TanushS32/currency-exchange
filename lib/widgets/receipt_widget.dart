import 'package:flutter/material.dart';

import '../calculator.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';

enum ReceiptStyle { modern, ledger }

class ReceiptView extends StatelessWidget {
  final ReceiptStyle style;
  final String dealType;
  final List<ExchangeItem> items;
  final QuoteTotals totals;
  final DateTime timestamp;

  const ReceiptView({
    super.key,
    required this.style,
    required this.dealType,
    required this.items,
    required this.totals,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    if (style == ReceiptStyle.ledger) {
      return _LedgerReceipt(this);
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: _ModernReceipt(this),
    );
  }
}

class _ModernReceipt extends StatelessWidget {
  final ReceiptView data;
  const _ModernReceipt(this.data);

  @override
  Widget build(BuildContext context) {
    final visibleItems = data.items.where((i) => i.amount != 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text(
                'SYSTEM GENERATED',
                style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.muted, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Currency Exchange',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              data.dealType == 'purchase' ? 'Purchase Confirmation' : 'Credit Note Confirmation',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              formatDateTime(data.timestamp),
              style: const TextStyle(fontSize: 11, color: Color(0xFFB2BAC7)),
            ),
          ],
        ),
        const _DashedDivider(),
        const Text(
          'EXCHANGE DETAILS',
          style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...visibleItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name.isEmpty ? '—' : item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${formatQty(item.qty)} × ${formatQty(item.rate)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('₹${formatMoney(item.amount)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )),
        const _DashedDivider(),
        _SummaryRow('Exchange Value', '₹${formatMoney(data.totals.cnTotal)}'),
        const SizedBox(height: 4),
        if (data.totals.cnGST > 0) ...[
          _SummaryRow('GST on Exchange', '₹${formatMoney2(data.totals.cnGST)}', muted: true),
          _SummaryRow('Service Charges', '₹${formatMoney(data.totals.service)}', muted: true),
          _SummaryRow('GST on Service', '₹${formatMoney2(data.totals.serviceGST)}', muted: true),
        ],
        const _DashedDivider(),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.receiptTotalBg,
            border: Border.all(color: AppColors.receiptTotalBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text('TOTAL SETTLEMENT AMOUNT',
                  style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: AppColors.receiptTotalText, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('₹${formatMoney(data.totals.grand)}',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.receiptTotalText)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'This is a system-generated exchange confirmation.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Pixel-matches the desktop app's #excel-canvas / #printable-excel layout
/// (templates/app.html) so downloaded/shared images look identical between
/// the desktop and mobile apps: fixed 560dp card, same colors/spacing.
class _LedgerReceipt extends StatelessWidget {
  final ReceiptView data;
  const _LedgerReceipt(this.data);

  static const _tableBorder = Color(0xFFE2E8F0);
  static const _headerTextColor = Color(0xFF475569);
  static const _totalTextColor = Color(0xFF166534);

  @override
  Widget build(BuildContext context) {
    final visibleItems = data.items.where((i) => i.amount != 0).toList();
    final showCharges = data.totals.cnGST > 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _tableBorder),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0F0F172A), blurRadius: 30, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showCharges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE0F2FE), Color(0xFFF1F5F9)],
                  ),
                  border: Border.all(color: _tableBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PAYMENT FROM SAVINGS ACCOUNT ONLY',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3, color: AppColors.ink),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _tableBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      border: Border(bottom: BorderSide(color: _tableBorder)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: _HeaderCell('CURRENCY', alignRight: false)),
                        Expanded(flex: 2, child: _HeaderCell('CN', alignRight: true)),
                        Expanded(flex: 2, child: _HeaderCell('RATE', alignRight: true)),
                        Expanded(flex: 2, child: _HeaderCell('RS.', alignRight: true)),
                      ],
                    ),
                  ),
                  for (int i = 0; i < visibleItems.length; i++)
                    _row(
                      showBottomBorder: i != visibleItems.length - 1 || showCharges,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(visibleItems[i].name.isEmpty ? '—' : visibleItems[i].name,
                              style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatQty(visibleItems[i].qty),
                              textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatQty(visibleItems[i].rate),
                              textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatMoney(visibleItems[i].amount),
                              textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                        ),
                      ],
                    ),
                  if (showCharges)
                    _row(
                      showBottomBorder: false,
                      children: [
                        const Expanded(
                          flex: 7,
                          child: Text('GST & Charges',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatMoney(data.totals.chargesRounded.toDouble()),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ),
                      ],
                    ),
                  Container(
                    color: AppColors.receiptTotalBg,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 7,
                          child: Text('TOTAL',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _totalTextColor)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatMoney(data.totals.grand),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _totalTextColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({required List<Widget> children, required bool showBottomBorder}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: showBottomBorder ? const Border(bottom: BorderSide(color: _tableBorder)) : null,
      ),
      child: Row(children: children),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _HeaderCell(this.text, {required this.alignRight});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: _LedgerReceipt._headerTextColor,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  const _SummaryRow(this.label, this.value, {this.muted = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: muted ? 12 : 14,
      color: muted ? AppColors.muted : AppColors.ink,
      fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashPainter(),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
