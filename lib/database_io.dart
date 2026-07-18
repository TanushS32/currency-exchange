import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'exchange.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE exchange (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            deal_type TEXT NOT NULL DEFAULT 'sale',
            cn_total REAL NOT NULL,
            service REAL NOT NULL,
            gst_exchange REAL NOT NULL,
            gst_service REAL NOT NULL,
            grand_total REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE exchange_item (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exchange_id INTEGER NOT NULL,
            name TEXT,
            qty REAL,
            rate REAL,
            amount REAL,
            FOREIGN KEY (exchange_id) REFERENCES exchange (id) ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<int> saveExchange(Exchange exchange) async {
    final db = await database;
    return db.transaction((txn) async {
      final exchangeId = await txn.insert('exchange', exchange.toMap());
      for (final item in exchange.items) {
        await txn.insert('exchange_item', item.toMap(exchangeId: exchangeId));
      }
      return exchangeId;
    });
  }

  Future<List<Exchange>> loadHistory({int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      'exchange',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    final results = <Exchange>[];
    for (final row in rows) {
      final itemRows = await db.query(
        'exchange_item',
        where: 'exchange_id = ?',
        whereArgs: [row['id']],
      );
      results.add(Exchange.fromMap(
        row,
        items: itemRows.map(ExchangeItem.fromMap).toList(),
      ));
    }
    return results;
  }

  Future<Exchange?> getExchange(int id) async {
    final db = await database;
    final rows = await db.query('exchange', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final itemRows = await db.query(
      'exchange_item',
      where: 'exchange_id = ?',
      whereArgs: [id],
    );
    return Exchange.fromMap(rows.first, items: itemRows.map(ExchangeItem.fromMap).toList());
  }

  Future<void> deleteExchange(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('exchange_item', where: 'exchange_id = ?', whereArgs: [id]);
      await txn.delete('exchange', where: 'id = ?', whereArgs: [id]);
    });
  }
}
