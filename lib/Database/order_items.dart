import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';

class OrderItem {
  final int? id;
  final int? orderId;
  final int productId;
  int quantity;
  final double weight;
  double price;
  final double discount;
  final double tax;
  final Uint8List? image;
  final String? name;
  final String? sku;

  OrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.quantity,
    this.weight = 0.0,
    this.price = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.image,
    this.name = '',
    this.sku = '',
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    id: map['id'] as int?,
    orderId: map['order_id'],
    productId: map['product_id'],
    quantity: (map['quantity'] as num).toInt(),
    weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
    image: map['image'] as Uint8List?,
    name: map['name'] as String?,
    sku: map['sku'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'quantity': quantity,
    'weight': weight,
    'price': price,
    'discount': discount,
    'tax': tax,
    'image': image,
  };
}

Future<Map<String, int>> orderItemCount(Database db, int orderId) async {
  final result = await db.rawQuery('''
    SELECT COUNT(*) AS itemCount, SUM(quantity) AS totalQuantity
    FROM order_items
    WHERE order_id = ?
  ''', [orderId]);

  final row = result.first;
  return {
    'itemCount': (row['itemCount'] as int?) ?? 0,
    'totalQuantity': ((row['totalQuantity'] as num?)?.toInt()) ?? 0,
  };
}

Future<List<OrderItem>> getOrderItemsByOrderId(Database db, int orderId) async {
  final result = await db.query(
    'order_items',
    where: 'order_id = ?',
    whereArgs: [orderId],
  );

  return result.map((row) {
    return OrderItem(
      id: row['id'] as int?,
      orderId: row['order_id'] as int?,
      productId: row['product_id'] as int,
      quantity: ((row['quantity'] as num).toInt()),
      weight: (row['weight'] as num?)?.toDouble() ?? 0,
      price: (row['price'] as num).toDouble(),
      discount: (row['discount'] as num?)?.toDouble() ?? 0,
      tax: (row['tax'] as num?)?.toDouble() ?? 0,
      image: row['image'] as Uint8List?,
      name: row['name'] as String?,
      sku: row['sku'] as String?,
    );
  }).toList();
}


