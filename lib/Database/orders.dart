
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import 'order_items.dart';

class TwoValue {
  String first;
  dynamic second;

  TwoValue({this.first = '', this.second});
}


class Order {
   int? id;
   int personId;
   String name;
   String orderType; // buy / sell
   double totalAmount;
   double totalWeight;
   String orderStatus; // pending / completed / canceled
   String paymentStatus; // pending / paid / overdue
   String paymentMethod;
   int orderTimestamp; // epoch
   int paymentTimestamp = 0; // epoch
   int dueDateTimestamp = 0; // epoch
   String remark;
   double adjustment; // manual adjustment to total amount , not used in table
   TwoValue tax = TwoValue(first: '%', second: 0.0); // not to use
   TwoValue discount = TwoValue(first: 'Rs', second: 0.0); //not to use
   bool editable = true;
   bool update = false;
   bool cancel = false;

  Order({
    this.id,
    required this.personId,
    required this.name,
    required this.orderType,
    this.totalAmount = 0.0,
    this.totalWeight = 0.0,
    this.orderStatus = 'Pending',
    this.paymentStatus = 'Paid',
    this.paymentMethod = 'Cash',
    required this.orderTimestamp,
    this.dueDateTimestamp = 0,
    this.remark = '',
    this.adjustment = 0.0,
    this.editable = true,
    this.update = false,
    this.cancel = false,

  });

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'] as int?,
    personId: map['person_id'] ?? 0,
    name: map['name'] ?? '',
    orderType: map['order_type'],
    totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
    totalWeight: (map['total_weight'] as num?)?.toDouble() ?? 0.0,
    orderStatus: map['order_status'] ?? 'pending',
    paymentStatus: map['payment_status'] ?? 'pending',
    orderTimestamp: map['order_timestamp'],
    dueDateTimestamp: map['due_date'],
    remark: map['remark'] ?? '',

  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'person_id': personId,
    'name': name,
    'order_type': orderType,
    'total_amount': totalAmount,
    'total_weight': totalWeight,
    'order_status': orderStatus,
    'payment_status': paymentStatus,
    'order_timestamp': orderTimestamp,
    'due_date' :  dueDateTimestamp,
    'remark': remark,
  };
}

Future<int> registerOrder(Order order, List<OrderItem> items, Database db) async {
  debugPrint("Regestring Order: ${order.dueDateTimestamp}");
  return await db.transaction((txn) async {
    // Flip sign if it's a buy (receiving)
    final sign = order.orderType == 'buy' ? -1 : 1;

    // 1️⃣ Insert Order
    final orderId = await txn.insert('orders', {
      'person_id': order.personId,
      'name': order.name,
      'order_type': order.orderType,
      'total_amount': order.totalAmount * sign,
      'total_weight': order.totalWeight,
      'tax': '${order.tax.first},${order.tax.second}',
      'discount': '${order.discount.first},${order.discount.second}',
      'order_status': order.orderStatus,
      'payment_status': order.paymentStatus,
      'order_timestamp': order.orderTimestamp,
      'due_date' : order.paymentStatus == 'Overdue' ? order.dueDateTimestamp : 0,
      'remark': order.remark,
    });

    // 2️⃣ Insert Order Items
    for (final item in items) {
      await txn.insert('order_items', {
        'order_id': orderId,
        'product_id': item.productId,
        'name': item.name ?? '',
        'sku': item.sku ?? '',
        'quantity': item.quantity,
        'weight': item.weight,
        'price': item.price * sign,
        'discount': item.discount * sign,
        'tax': item.tax * sign,
      });

      // 4️⃣ Deduct or Add main product stock
      //final stockChange = order.orderType == 'buy' ? item.quantity : -item.quantity;
      // await txn.rawUpdate(
      //   'UPDATE products SET stock = stock + ? WHERE id = ?',
      //   [stockChange, item.productId],
      // );
    }

    // 3️⃣ Handle Product Stock and Sold
    await handleProductUpdates(order, items, txn);

    // 3️⃣ Insert Payment Transaction
    await txn.insert('payment_transactions', {
      'person_id': order.personId,
      'name': order.name,
      'order_id': orderId,
      'amount': order.totalAmount * sign,
      'payment_status': order.paymentStatus,
      'due_date': order.dueDateTimestamp,
      'payment_method': order.paymentMethod,
      'timestamp': order.orderTimestamp,
      'remark': order.remark,
      'payment_timestamp': order.paymentTimestamp,
    });

    return orderId;
  });
}

/// 🔧 Handles product stock & sold updates (main + nested components)
Future<void> handleProductUpdates(
    Order order, List<OrderItem> items, Transaction txn) async {
  Future<void> increaseSoldRecursively(int id, int qty) async {
    final data =
    await txn.rawQuery('SELECT components FROM products WHERE id = ?', [id]);
    if (data.isEmpty) return;

    final components = (data.first['components'] ?? '').toString().trim();
    if (components.isEmpty) return;

    for (final comp in components.split(',').map((e) => e.trim())) {
      final compId = int.tryParse(comp);
      if (compId != null) {
        await txn.rawUpdate(
          'UPDATE products SET sold = sold + ? WHERE id = ?',
          [qty, compId],
        );
        await increaseSoldRecursively(compId, qty); // recurse for nested
      }
    }
  }

  if (order.orderType == 'buy') {
    // ➕ Add stock for main products only
    for (final item in items) {
      await txn.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [item.quantity, item.productId],
      );
    }
  } else {
    // ➖ Deduct stock for main products & increase sold (including nested)
    for (final item in items) {
      await txn.rawUpdate(
        'UPDATE products SET stock = stock - ?, sold = sold + ? WHERE id = ?',
        [item.quantity, item.quantity, item.productId],
      );
      await increaseSoldRecursively(item.productId, item.quantity);
    }
  }
}


/// Return Orders List from DB
Future<List<Order>> fetchFilteredOrders(
    Database db, {
      String? searchValue,
      int selectedIndex = 0,
      DateTime? fromDate,
      DateTime? toDate,
      int pageNo = 1,
      int pageSize = 20,
      int orderType = 0,
    }) async
{

  final where = <String>[];
  final args = <dynamic>[];

  // --- Search ---
  if (searchValue != null && searchValue.trim().isNotEmpty) {
    final val = searchValue.trim();
    final id = int.tryParse(val);
    if (id != null) {
      where.add('(o.id = ?)');
      args.addAll([id]);
    } else {
      where.add('(o.name LIKE ? OR o.remark LIKE ?)');
      args.addAll(['%$val%', '%$val%']);
    }
  }

  // --- Status filter ---
  switch (selectedIndex) {
    case 1:
      where.add("o.order_status = 'Completed'");
      break;
    case 2:
      where.add("(o.order_status = 'Pending' OR o.payment_status = 'Pending')");
      break;
    case 3:
      where.add("o.order_status = 'Canceled'");
      break;
  }

  // --- Order type filter ---
  if (orderType == 1) {
    where.add('o.total_amount >= 0');
  } else if (orderType == 2) {
    where.add('o.total_amount < 0');
  }

  // --- Date range ---
  if (fromDate != null && fromDate.millisecondsSinceEpoch > 0) {
    where.add('o.order_timestamp >= ?');
    args.add(fromDate.millisecondsSinceEpoch);
  }
  if (toDate != null && toDate.millisecondsSinceEpoch > 0) {
    where.add('o.order_timestamp <= ?');
    args.add(toDate.millisecondsSinceEpoch);
  }

  final whereSQL = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
  final offset = (pageNo - 1) * pageSize;

  // ------ FIXED QUERY (avoid overwriting due_date) ------
  final result = await db.rawQuery('''
    SELECT 
      o.*, 
      t.payment_method,
      t.due_date AS txn_due_date     -- renamed to avoid overwriting
    FROM orders o
    LEFT JOIN payment_transactions t 
      ON t.order_id = o.id 
      AND t.id = (
          SELECT tt.id FROM payment_transactions tt
          WHERE tt.order_id = o.id
          ORDER BY tt.id DESC LIMIT 1
      )
    $whereSQL
    ORDER BY o.id DESC
    LIMIT ? OFFSET ?
  ''', [...args, pageSize, offset]);

  // ------ MAPPING ------
  return result.map((row) {
    final order = Order(
      id: row['id'] as int?,
      personId: row['person_id'] as int? ?? 0,
      name: row['name'] as String? ?? '',
      orderType: row['order_type'] as String? ?? 'sell',
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalWeight: (row['total_weight'] as num?)?.toDouble() ?? 0.0,
      orderStatus: row['order_status'] as String? ?? 'Pending',
      paymentStatus: row['payment_status'] as String? ?? 'Pending',
      paymentMethod: row['payment_method'] as String? ?? 'Cash',

      // ------------------------ FIX HERE ------------------------
      // use ONLY orders.due_date, NEVER payment_transactions.due_date
      dueDateTimestamp: row['due_date'] as int? ?? 0,
      // ----------------------------------------------------------

      orderTimestamp: row['order_timestamp'] as int? ?? 0,
      remark: row['remark'] as String? ?? '',
      adjustment: 0.0,
    );

    // --- Parse tax & discount ---
    final taxParts = (row['tax'] as String?)?.split(',') ?? ['%', '0'];
    final discParts = (row['discount'] as String?)?.split(',') ?? ['Rs', '0'];

    final tax = TwoValue(first: taxParts[0], second: double.tryParse(taxParts[1]) ?? 0.0);
    final discount = TwoValue(first: discParts[0], second: double.tryParse(discParts[1]) ?? 0.0);

    order.tax = tax;
    order.discount = discount;

    // --- Adjustment ---
    final taxVal  = tax.first == '%' ? order.totalAmount * tax.second / 100 : tax.second;
    final discVal = discount.first == '%' ? order.totalAmount * discount.second / 100 : discount.second;

    order.adjustment = taxVal - discVal;
    order.editable = false;

    return order;
  }).toList();
}

/// return Order Numbers only
Future<Map<String, List<Map<String, int>>>> getOrderCounts(Database db) async {
  final result = await db.rawQuery('''
    SELECT
      SUM(CASE WHEN order_type = 'sell' THEN 1 ELSE 0 END) AS allSell,
      SUM(CASE WHEN order_type = 'buy' THEN 1 ELSE 0 END) AS allBuy,
      SUM(CASE WHEN order_status = 'Completed' AND order_type = 'sell' THEN 1 ELSE 0 END) AS completedSell,
      SUM(CASE WHEN order_status = 'Completed' AND order_type = 'buy' THEN 1 ELSE 0 END) AS completedBuy,
      SUM(CASE WHEN order_status = 'Pending' AND order_type = 'sell' THEN 1 ELSE 0 END) AS pendingSell,
      SUM(CASE WHEN order_status = 'Pending' AND order_type = 'buy' THEN 1 ELSE 0 END) AS pendingBuy,
      SUM(CASE WHEN order_status = 'Canceled' AND order_type = 'sell' THEN 1 ELSE 0 END) AS canceledSell,
      SUM(CASE WHEN order_status = 'Canceled' AND order_type = 'buy' THEN 1 ELSE 0 END) AS canceledBuy
    FROM orders
  ''');

  final r = result.first;
  return {
    'All': [
      {'Total': (r['allSell'] as int) + (r['allBuy'] as int)},
      {'Sell': r['allSell'] as int},
      {'Buy': r['allBuy'] as int},
    ],
    'Completed': [
      {'Total': (r['completedSell'] as int) + (r['completedBuy'] as int)},
      {'Sell': r['completedSell'] as int},
      {'Buy': r['completedBuy'] as int},
    ],
    'Pending': [
      {'Total': (r['pendingSell'] as int) + (r['pendingBuy'] as int)},
      {'Sell': r['pendingSell'] as int},
      {'Buy': r['pendingBuy'] as int},
    ],
    'Canceled': [
      {'Total': (r['canceledSell'] as int) + (r['canceledBuy'] as int)},
      {'Sell': r['canceledSell'] as int},
      {'Buy': r['canceledBuy'] as int},
    ],
  };
}


///single Order fetch
Future<Order?> getOrderById(Database db, int orderId) async {
  final rows = await db.query(
    'orders',
    where: 'id = ?',
    whereArgs: [orderId],
    limit: 1,
  );

  if (rows.isEmpty) return null;

  final row = rows.first;

  // Parse discount and tax stored as "%,0.0" or "Rs,0.0"
  TwoValue parseTwoValue(String? value, String defaultFirst) {
    if (value == null || !value.contains(',')) return TwoValue(first: defaultFirst, second: 0.0);
    final parts = value.split(',');
    return TwoValue(first: parts[0], second: double.tryParse(parts[1]) ?? 0.0);
  }

  final discount = parseTwoValue(row['discount'] as String?, 'Rs');
  final tax = parseTwoValue(row['tax'] as String?, '%');

  final order = Order.fromMap(row);
  order.discount = discount;
  order.tax = tax;
  return order;
}

///update Order

Future<bool> updatePendingOrderFromObject(
    Database db, {
      required Order order,
    }) async {
  if (order.id == null) return false;

  return await db.transaction((txn) async {
    // 1️⃣ Check current order status
    final result = await txn.query(
      'orders',
      columns: ['order_status'],
      where: 'id = ?',
      whereArgs: [order.id],
      limit: 1,
    );

    if (result.isEmpty) return false;

    final currentStatus = result.first['order_status'] as String;

    // 2️⃣ Always update REMARKS (both tables)
    await txn.update(
      'orders',
      {'remark': order.remark},
      where: 'id = ?',
      whereArgs: [order.id],
    );

    await txn.update(
      'payment_transactions',
      {'remark': order.remark},
      where: 'order_id = ?',
      whereArgs: [order.id],
    );
    // ❌ Only pending orders can be updated
    // if (currentStatus.toLowerCase() != 'pending') {
    //   return false;
    // }

    // 2️⃣ Update ORDER (only allowed fields)
    await txn.update(
      'orders',
      {
        'order_status': order.orderStatus,
        'payment_status': order.paymentStatus,
        'due_date': order.dueDateTimestamp,
        'remark': order.remark,
      },
      where: 'id = ?',
      whereArgs: [order.id],
    );

    // 3️⃣ Update TRANSACTIONS linked to this order
    await txn.update(
      'payment_transactions',
      {
        'payment_status': order.paymentStatus,
        'due_date': order.dueDateTimestamp,
        'payment_method': order.paymentMethod,
        'remark': order.remark,
        'payment_timestamp': order.paymentTimestamp,
      },
      where: 'order_id = ?',
      whereArgs: [order.id],
    );

    return true;
  });
}
