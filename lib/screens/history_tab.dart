import 'package:flutter/material.dart';

import '../database.dart';
import '../models.dart';
import '../quote_controller.dart';
import '../theme.dart';
import '../utils.dart';

class HistoryTab extends StatefulWidget {
  final QuoteController controller;
  final ValueChanged<Exchange> onLoad;

  const HistoryTab({super.key, required this.controller, required this.onLoad});

  @override
  State<HistoryTab> createState() => HistoryTabState();
}

class HistoryTabState extends State<HistoryTab> {
  List<Exchange> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => _loading = true);
    final history = await AppDatabase.instance.loadHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  Future<void> _delete(Exchange exchange) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this quote?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteExchange(exchange.id!);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Text('No history yet', style: TextStyle(color: AppColors.muted)),
                )
              : RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _history.length,
                    itemBuilder: (context, index) => _HistoryCard(
                      exchange: _history[index],
                      onLoad: () => widget.onLoad(_history[index]),
                      onDelete: () => _delete(_history[index]),
                    ),
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Exchange exchange;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _HistoryCard({required this.exchange, required this.onLoad, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${formatMoney(exchange.grandTotal)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: exchange.dealType == 'purchase' ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  exchange.dealType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: exchange.dealType == 'purchase' ? const Color(0xFF9A3412) : AppColors.receiptTotalText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(formatDateTime(exchange.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          if (exchange.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...exchange.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(item.name.isEmpty ? '—' : item.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('${formatQty(item.qty)} × ${formatQty(item.rate)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('₹${formatMoney(item.amount)}',
                            textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLoad,
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Reuse'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
