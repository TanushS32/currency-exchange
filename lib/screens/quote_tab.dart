import 'package:flutter/material.dart';

import '../database.dart';
import '../quote_controller.dart';
import '../theme.dart';
import '../utils.dart';
import 'preview_screen.dart';

class QuoteTab extends StatefulWidget {
  final QuoteController controller;
  final VoidCallback onSaved;

  const QuoteTab({super.key, required this.controller, required this.onSaved});

  @override
  State<QuoteTab> createState() => _QuoteTabState();
}

class _QuoteTabState extends State<QuoteTab> {
  bool _saving = false;

  Future<void> _save({bool silent = false}) async {
    final controller = widget.controller;
    if (controller.totals.overLimit) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CN value exceeds ₹10,00,000.')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final exchange = controller.buildExchangeForSave();
      await AppDatabase.instance.saveExchange(exchange);
      widget.onSaved();
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openPreview() {
    final controller = widget.controller;
    if (controller.totals.overLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CN value exceeds ₹10,00,000.')),
      );
      return;
    }
    _save(silent: true);
    final exchange = controller.buildExchangeForSave();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PreviewScreen(
        dealType: exchange.dealType,
        items: exchange.items,
        totals: controller.totals,
        timestamp: exchange.createdAt,
      ),
    ));
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear quote?'),
        content: const Text('This will reset all currency lines and charges.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              widget.controller.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: _confirmClear,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _DealPill(controller: controller),
              const SizedBox(height: 14),
              _LinesSection(controller: controller),
              const SizedBox(height: 10),
              _ChargesRow(controller: controller),
              const SizedBox(height: 14),
              _TotalHero(controller: controller),
              if (controller.totals.overLimit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '⚠️ CN value exceeds ₹10,00,000.',
                    style: TextStyle(color: Color(0xFF9F1239), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _save(),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _openPreview,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Preview & Share'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone segmented pill — no card chrome, it's the primary switch for
/// the whole quote so it reads as the top-level control, not "one more box".
class _DealPill extends StatelessWidget {
  final QuoteController controller;
  const _DealPill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(child: _PillButton('SALE', controller.dealType == 'sale', () => controller.setDealType('sale'))),
          Expanded(
              child: _PillButton('PURCHASE', controller.dealType == 'purchase', () => controller.setDealType('purchase'))),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PillButton(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]) : null,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Receipt-style line items: no per-row box chrome, just a currency name,
/// a small "qty × rate" caption underneath, and the amount on the right —
/// reads like a real receipt line rather than a stack of form fields.
class _LinesSection extends StatelessWidget {
  final QuoteController controller;
  const _LinesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CURRENCY LINES',
                  style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: AppColors.muted, fontWeight: FontWeight.w700)),
              InkWell(
                onTap: () => controller.addRow(),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.accentDark),
                      SizedBox(width: 2),
                      Text('Add', style: TextStyle(color: AppColors.accentDark, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(
              children: [
                for (int i = 0; i < controller.rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Dismissible(
                    key: ObjectKey(controller.rows[i]),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 4),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    ),
                    onDismissed: (_) => controller.removeRow(i),
                    child: _ReceiptLine(controller: controller, index: i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final QuoteController controller;
  final int index;
  const _ReceiptLine({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final row = controller.rows[index];
    final multiRow = controller.rows.length > 1;
    final selected = multiRow && controller.selectedRowIndex == index;

    // The amount permanently lives on its own second line, on purpose — that
    // frees the first line to give currency/qty/rate generous proportional
    // width (Expanded, never a fixed pixel size that content could outgrow
    // and get scrolled/hidden inside). Nothing here wraps conditionally;
    // this two-line shape is fixed so it's predictable on every screen size.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (multiRow)
                InkWell(
                  onTap: () => controller.selectRow(index),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      size: 18,
                      color: selected ? AppColors.accent : AppColors.muted,
                    ),
                  ),
                ),
              Expanded(
                flex: 10,
                child: TextField(
                  controller: row.name,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'e.g. USD',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 9,
                child: TextField(
                  key: ValueKey('qty-$index'),
                  controller: row.qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Qty',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const Text(' × ', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              Expanded(
                flex: 9,
                child: TextField(
                  key: ValueKey('rate-$index'),
                  controller: row.rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Rate',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              if (multiRow)
                InkWell(
                  onTap: () => controller.removeRow(index),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '₹${formatMoney(row.amount)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything charges-related in one slim, low-chrome row instead of a
/// dedicated card — this is a secondary control, not a primary section.
class _ChargesRow extends StatelessWidget {
  final QuoteController controller;
  const _ChargesRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: controller.noCharges
                  ? const Text('Service charges skipped',
                      style: TextStyle(fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic))
                  : Row(
                      children: [
                        const Text('Service ', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: controller.serviceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              prefixText: '₹ ',
                              hintText: 'Amount',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const Text('No charges', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: controller.noCharges,
                onChanged: controller.setNoCharges,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The hero of the page: a big, unmissable total (the thing users actually
/// care about), with the GST/CN breakdown tucked behind a details toggle
/// instead of always cluttering the view.
class _TotalHero extends StatefulWidget {
  final QuoteController controller;
  const _TotalHero({required this.controller});

  @override
  State<_TotalHero> createState() => _TotalHeroState();
}

class _TotalHeroState extends State<_TotalHero> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final totals = controller.totals;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.receiptTotalBg, Color(0xFFF0FDF4)],
        ),
        border: Border.all(color: AppColors.receiptTotalBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text('TOTAL PAYABLE',
                    style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: AppColors.receiptTotalText, fontWeight: FontWeight.w700)),
              ),
              if (!controller.noCharges)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_expanded ? 'Hide details' : 'Details',
                            style: const TextStyle(fontSize: 11, color: AppColors.receiptTotalText, fontWeight: FontWeight.w600)),
                        Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 16, color: AppColors.receiptTotalText),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('₹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.receiptTotalText)),
              Expanded(
                child: TextField(
                  controller: controller.grandCtrl,
                  enabled: controller.grandEditable,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onTap: controller.beginGrandEdit,
                  onTapOutside: (_) => controller.endGrandEdit(),
                  onSubmitted: (_) => controller.endGrandEdit(),
                  style: const TextStyle(color: AppColors.receiptTotalText, fontWeight: FontWeight.w800, fontSize: 34, height: 1.1),
                  decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                ),
              ),
            ],
          ),
          if (controller.rows.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                controller.grandEditable
                    ? 'Editing ${_lineLabel(controller, controller.selectedRowIndex!)} — other lines stay fixed'
                    : 'Select a currency line below to edit the total directly',
                style: const TextStyle(fontSize: 11, color: AppColors.receiptTotalText),
              ),
            ),
          if (_expanded && !controller.noCharges) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.receiptTotalBorder),
            ),
            _detailRow('CN Value', '₹${formatMoney2(totals.cnTotal)}'),
            _detailRow('GST on CN', '₹${formatMoney2(totals.cnGST)}'),
            _detailRow('Service Charges', '₹${formatMoney2(totals.service)}'),
            _detailRow('GST on Service', '₹${formatMoney2(totals.serviceGST)}'),
          ],
        ],
      ),
    );
  }

  String _lineLabel(QuoteController controller, int index) {
    final name = controller.rows[index].name.text.trim();
    return name.isEmpty ? 'line ${index + 1}' : name;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.receiptTotalText)),
          Text(value, style: const TextStyle(fontSize: 12, color: AppColors.receiptTotalText, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
