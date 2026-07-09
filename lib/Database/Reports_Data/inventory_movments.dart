import 'package:sqflite/sqflite.dart';

class InventoryMovement {
  final int? id;
  final int productId;
  final int? orderId;
  final int? orderItemId;
  final String movementType; // 'Purchase', 'Sale', 'Purchase Return', 'Sales Return', 'Stock Adjustment', 'Opening Stock', 'Stock Transfer', 'Stock Correction'
  final int quantityChange;
  final int stockBefore;
  final int stockAfter;
  final double? unitCost;
  final int? unitPrice;
  final int? totalValue;
  final String? location;
  final int timestamp;
  final String? remark;

  InventoryMovement({
    this.id,
    required this.productId,
    this.orderId,
    this.orderItemId,
    required this.movementType,
    required this.quantityChange,
    required this.stockBefore,
    required this.stockAfter,
    this.unitCost,
    this.unitPrice,
    this.totalValue,
    this.location,
    required this.timestamp,
    this.remark,
  });

  /// Create an InventoryMovement instance from a Map (usually from Database)
  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      orderId: map['order_id'] as int?,
      orderItemId: map['order_item_id'] as int?,
      movementType: map['movement_type'] as String,
      quantityChange: (map['quantity_change'] as num).toInt(),
      stockBefore: (map['stock_before'] as num).toInt(),
      stockAfter: (map['stock_after'] as num).toInt(),
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      unitPrice: (map['unit_price'] as num?)?.toInt(),
      totalValue: (map['total_value'] as num?)?.toInt(),
      location: map['location'] as String?,
      timestamp: map['timestamp'] as int,
      remark: map['remark'] as String?,
    );
  }

  /// Convert an InventoryMovement instance to a Map for Database insertion/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'order_id': orderId,
      'order_item_id': orderItemId,
      'movement_type': movementType,
      'quantity_change': quantityChange,
      'stock_before': stockBefore,
      'stock_after': stockAfter,
      'unit_cost': unitCost,
      'unit_price': unitPrice,
      'total_value': totalValue,
      'location': location,
      'timestamp': timestamp,
      'remark': remark,
    };
  }
}

/// Global function to insert an inventory movement into the database
Future<int> insertInventoryMovement(Database db, InventoryMovement movement) async {
  return await db.insert('inventory_movements', movement.toMap());
}
