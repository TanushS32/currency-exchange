class ExchangeItem {
  final int? id;
  final int? exchangeId;
  final String name;
  final double qty;
  final double rate;

  const ExchangeItem({
    this.id,
    this.exchangeId,
    required this.name,
    required this.qty,
    required this.rate,
  });

  double get amount => qty * rate;

  ExchangeItem copyWith({String? name, double? qty, double? rate}) {
    return ExchangeItem(
      id: id,
      exchangeId: exchangeId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
    );
  }

  Map<String, dynamic> toMap({int? exchangeId}) {
    return {
      if (id != null) 'id': id,
      'exchange_id': exchangeId ?? this.exchangeId,
      'name': name,
      'qty': qty,
      'rate': rate,
      'amount': amount,
    };
  }

  factory ExchangeItem.fromMap(Map<String, dynamic> map) {
    return ExchangeItem(
      id: map['id'] as int?,
      exchangeId: map['exchange_id'] as int?,
      name: (map['name'] ?? '') as String,
      qty: (map['qty'] as num?)?.toDouble() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Exchange {
  final int? id;
  final DateTime createdAt;
  final String dealType; // 'sale' | 'purchase'
  final double cnTotal;
  final double service;
  final double gstExchange;
  final double gstService;
  final double grandTotal;
  final List<ExchangeItem> items;

  const Exchange({
    this.id,
    required this.createdAt,
    required this.dealType,
    required this.cnTotal,
    required this.service,
    required this.gstExchange,
    required this.gstService,
    required this.grandTotal,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'created_at': createdAt.toIso8601String(),
      'deal_type': dealType,
      'cn_total': cnTotal,
      'service': service,
      'gst_exchange': gstExchange,
      'gst_service': gstService,
      'grand_total': grandTotal,
    };
  }

  factory Exchange.fromMap(Map<String, dynamic> map, {List<ExchangeItem> items = const []}) {
    return Exchange(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      dealType: (map['deal_type'] ?? 'sale') as String,
      cnTotal: (map['cn_total'] as num?)?.toDouble() ?? 0,
      service: (map['service'] as num?)?.toDouble() ?? 0,
      gstExchange: (map['gst_exchange'] as num?)?.toDouble() ?? 0,
      gstService: (map['gst_service'] as num?)?.toDouble() ?? 0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0,
      items: items,
    );
  }
}
