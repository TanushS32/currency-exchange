import 'package:flutter/material.dart';

import '../models.dart';
import '../quote_controller.dart';
import 'history_tab.dart';
import 'quote_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final QuoteController _controller = QuoteController();
  final GlobalKey<HistoryTabState> _historyKey = GlobalKey<HistoryTabState>();
  int _tabIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSaved() {
    _historyKey.currentState?.refresh();
  }

  void _onLoadFromHistory(Exchange exchange) {
    _controller.loadExchange(exchange);
    setState(() => _tabIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          QuoteTab(controller: _controller, onSaved: _onSaved),
          HistoryTab(key: _historyKey, controller: _controller, onLoad: _onLoadFromHistory),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.currency_exchange_rounded), label: 'Quote'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
        ],
      ),
    );
  }
}
