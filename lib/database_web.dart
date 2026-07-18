import 'dart:convert';

import 'package:web/web.dart' as web;

import 'models.dart';

/// Web has no sqflite implementation, and the WASM/worker-based option
/// (sqflite_common_ffi_web) proved fragile in this environment. Since the
/// data here is just a small list of saved quotes — not complex queries —
/// plain JSON in localStorage is simpler and far more reliable. Mobile keeps
/// using the real sqflite-backed AppDatabase in database_io.dart, untouched.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _storageKey = 'exchange_history';

  List<Map<String, dynamic>> _readAll() {
    final raw = web.window.localStorage.getItem(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  void _writeAll(List<Map<String, dynamic>> records) {
    web.window.localStorage.setItem(_storageKey, jsonEncode(records));
  }

  Future<int> saveExchange(Exchange exchange) async {
    final records = _readAll();
    final nextId = records.isEmpty
        ? 1
        : (records.map((r) => r['id'] as int).reduce((a, b) => a > b ? a : b) + 1);

    records.add({
      ...exchange.toMap(),
      'id': nextId,
      'items': exchange.items.map((i) => i.toMap()).toList(),
    });
    _writeAll(records);
    return nextId;
  }

  Future<List<Exchange>> loadHistory({int limit = 50}) async {
    final records = _readAll();
    records.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return records.take(limit).map(_exchangeFromRecord).toList();
  }

  Future<Exchange?> getExchange(int id) async {
    final records = _readAll();
    for (final r in records) {
      if (r['id'] == id) return _exchangeFromRecord(r);
    }
    return null;
  }

  Future<void> deleteExchange(int id) async {
    final records = _readAll();
    records.removeWhere((r) => r['id'] == id);
    _writeAll(records);
  }

  Exchange _exchangeFromRecord(Map<String, dynamic> r) {
    final items = (r['items'] as List).cast<Map<String, dynamic>>().map(ExchangeItem.fromMap).toList();
    return Exchange.fromMap(r, items: items);
  }
}
