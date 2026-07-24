import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';


class PaymentTransaction {
  final int? id;
  final int personId;
  String name;
  final int orderId;
  final double amount;
  final double paidAmount;
  final String paymentStatus;      // Pending, Paid, Overdue
  final int dueDate;               // store as int (timestamp)
  final String paymentMethod;      // Digital, Cash, Bank, Other
  final int timestamp;             // created time
  final int paymentTimestamp;      // payment time
  final String remark;

  PaymentTransaction({
    this.id,
    required this.personId,
    required this.name,
    required this.orderId,
    required this.amount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.dueDate,
    required this.paymentMethod,
    required this.timestamp,
    required this.paymentTimestamp,
    required this.remark,
  });

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'],
      personId: map['person_id'] ?? 0,
      name: map['name'] ?? '',
      orderId: map['order_id'] ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      paidAmount: map['paid_amount']?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status'] ?? 'Paid',
      dueDate: map['due_date'] ?? 0,
      paymentMethod: map['payment_method'] ?? 'Cash',
      timestamp: map['timestamp'] ?? 0,
      paymentTimestamp: map['payment_timestamp'] ?? 0,
      remark: map['remark'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_id': personId,
      'name': name,
      'order_id': orderId,
      'amount': amount,
      'paid_amount': paidAmount,
      'payment_status': paymentStatus,
      'due_date': dueDate,
      'payment_method': paymentMethod,
      'timestamp': timestamp,
      'payment_timestamp': paymentTimestamp,
      'remark': remark,
    };
  }
}
/// Insert New Transaction
Future<int> insertTransaction(Database db, PaymentTransaction p) async {
  final data = p.toMap(); // keep your map as it is
  if (p.paidAmount.abs() >= p.amount.abs() && p.amount != 0) {
    data['payment_status'] = 'Paid';
  }
  data.remove('id'); // <-- remove id safely
  return await db.insert('payment_transactions', data);
}

/// Update Transaction (only allowed rows if Payment Status is not 'Paid'

Future<bool> updatePaymentIfNotPaid(
  Database db, {
  required int id,
  required String paymentStatus,
  required int dueDate,
  required String paymentMethod,
  required int paymentTimestamp,
  required String remark,
  double? paidAmount,
}) async {
  // Fetch current status
  final check = await db.query(
    'payment_transactions',
    columns: ['payment_status', 'order_id', 'amount'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );

  if (check.isEmpty) return false; // Not found

  final currentStatus = check.first['payment_status'] as String;
  final currentOrderId = check.first['order_id'] as int;
  final amount = (check.first['amount'] as num).toDouble();

  if (currentStatus == 'Paid') {
    return false; // Cannot overwrite paid transaction
  }

  String finalStatus = paymentStatus;
  if (paidAmount != null && paidAmount.abs() >= amount.abs() && amount != 0) {
    finalStatus = 'Paid';
  }

  // Update transaction only
  final updateData = {
    'payment_status': finalStatus,
    'due_date': dueDate,
    'payment_method': paymentMethod,
    'payment_timestamp': paymentTimestamp,
    'remark': remark,
  };

  if (paidAmount != null) {
    updateData['paid_amount'] = paidAmount;
  }

  final rows = await db.update(
    'payment_transactions',
    updateData,
    where: 'id = ?',
    whereArgs: [id],
  );

  // If update failed, stop here
  if (rows <= 0) return false;

  // Reflect on ORDER if orderId > 0 or transaction has an order > 0
  final targetOrderId = currentOrderId;
  if (targetOrderId > 0) {
    // If transaction is Paid => Complete the order
    await db.update(
      'orders',
      {
        'paid_amount': paidAmount,
      },
      where: 'id = ?',
      whereArgs: [targetOrderId],
    );
    if (finalStatus == 'Paid') {
      await db.update(
        'orders',
        {
          'payment_status': 'Paid',
          'order_status': 'Completed',
          'due_date': dueDate,
        },
        where: 'id = ?',
        whereArgs: [targetOrderId],
      );
    } else {
      // For Pending/Overdue → only update payment status + due date
      await db.update(
        'orders',
        {
          'payment_status': finalStatus,
          'due_date': dueDate,
        },
        where: 'id = ?',
        whereArgs: [targetOrderId],
      );
    }
  }

  return true;
}

/// Distribute payments across pending transactions for a person
Future<void> distributePayments(
    Database db, {
      required int personId,
      double pay = 0, // for negative amounts (outgoing)
      double receive = 0, // for positive amounts (incoming)
    }) async {
  if (pay <= 0 && receive <= 0) return;

  await db.transaction((txn) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1️⃣ Handle PAY (Outgoing/Negative Transactions)
    if (pay > 0) {
      final outgoing = await txn.query(
        'payment_transactions',
        where: "person_id = ? AND amount < 0 AND payment_status != 'Paid'",
        whereArgs: [personId],
        orderBy: 'id ASC',
      );

      double remainingPay = pay;
      for (var row in outgoing) {
        if (remainingPay <= 0) break;

        final id = row['id'] as int;
        final amount = (row['amount'] as num).toDouble();
        final currentPaid = (row['paid_amount'] as num).toDouble();
        final orderId = row['order_id'] as int;

        final needed = (amount - currentPaid).abs();
        final toApply = remainingPay < needed ? remainingPay : needed;

        final newPaid = currentPaid - toApply; // More negative
        remainingPay -= toApply;

        String newStatus = row['payment_status'] as String;
        final Map<String, dynamic> transUpdate = {
          'paid_amount': newPaid,
          'payment_status': newStatus,
        };

        if (newPaid.abs() >= amount.abs() - 0.01) { // small epsilon for double precision
          newStatus = 'Paid';
          transUpdate['payment_status'] = 'Paid';
          transUpdate['payment_timestamp'] = now;
        }

        await txn.update(
          'payment_transactions',
          transUpdate,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (orderId > 0) {
          final Map<String, dynamic> orderUpdate = {
            'paid_amount': newPaid,
            'payment_status': newStatus,
            'order_status': newStatus == 'Paid' ? 'Completed' : 'Pending',
          };
          await txn.update(
            'orders',
            orderUpdate,
            where: 'id = ?',
            whereArgs: [orderId],
          );
        }
      }
    }

    // 2️⃣ Handle RECEIVE (Incoming/Positive Transactions)
    if (receive > 0) {
      final incoming = await txn.query(
        'payment_transactions',
        where: "person_id = ? AND amount > 0 AND payment_status != 'Paid'",
        whereArgs: [personId],
        orderBy: 'id ASC',
      );

      double remainingReceive = receive;
      for (var row in incoming) {
        if (remainingReceive <= 0) break;

        final id = row['id'] as int;
        final amount = (row['amount'] as num).toDouble();
        final currentPaid = (row['paid_amount'] as num).toDouble();
        final orderId = row['order_id'] as int;

        final needed = amount - currentPaid;
        final toApply = remainingReceive < needed ? remainingReceive : needed;

        final newPaid = currentPaid + toApply;
        remainingReceive -= toApply;

        String newStatus = row['payment_status'] as String;
        final Map<String, dynamic> transUpdate = {
          'paid_amount': newPaid,
          'payment_status': newStatus,
        };

        if (newPaid >= amount - 0.01) {
          newStatus = 'Paid';
          transUpdate['payment_status'] = 'Paid';
          transUpdate['payment_timestamp'] = now;
        }

        await txn.update(
          'payment_transactions',
          transUpdate,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (orderId > 0) {
          final Map<String, dynamic> orderUpdate = {
            'paid_amount': newPaid,
            'payment_status': newStatus,
            'order_status': newStatus == 'Paid' ? 'Completed' : 'Pending',
          };
          await txn.update(
            'orders',
            orderUpdate,
            where: 'id = ?',
            whereArgs: [orderId],
          );
        }
      }
    }
  });
}



/// Retrieves Transaction Details as List
Future<List<PaymentTransaction>> getTransactions({
  required Database db,
  int status = 0,
  int type = 0,
  int startDate = 0,
  int endDate = 0,
  int dueStart = 0,
  int dueEnd = 0,
  int pageNo = 0,
  int pageSize = 0,
  String? search,
  int? personId,
}) async
{
  final whereClauses = <String>[];
  final whereArgs = <dynamic>[];

  // --- Person Filter ---
  if (personId != null && personId != 0) {
    whereClauses.add("person_id = ?");
    whereArgs.add(personId);
  }

  // --- Status Filter ---
  switch (status) {
    case 1: whereClauses.add("payment_status = ?"); whereArgs.add("Paid"); break;
    case 2: 
      whereClauses.add("payment_status IN (?, ?)"); 
      whereArgs.addAll(["Pending", "Overdue"]); 
      break;
    case 3: whereClauses.add("payment_status = ?"); whereArgs.add("Overdue"); break;
  }

  // --- Type Filter ---
  String? method;
  switch (type) {
    case 1: method = "Cash"; break;
    case 2: method = "Digital"; break;
    case 3: method = "Bank"; break;
    case 4: method = "Other"; break;
  }
  if (method != null) {
    whereClauses.add("payment_method = ?");
    whereArgs.add(method);
  }

  // --- Timestamp Range ---
  if (startDate > 0) { whereClauses.add("timestamp >= ?"); whereArgs.add(startDate); }
  if (endDate > 0) { whereClauses.add("timestamp <= ?"); whereArgs.add(endDate); }
  if (dueStart > 0) { whereClauses.add("due_date >= ?"); whereArgs.add(dueStart); }
  if (dueEnd > 0) { whereClauses.add("due_date <= ?"); whereArgs.add(dueEnd); }

// --- Search Filter ---
  if (search != null && search.isNotEmpty) {
    final cleanSearch = search.toLowerCase().replaceAll(RegExp(r'[ _\-\.,\"\ \\?/()]'), '');

    final parsedInt = int.tryParse(search);

    if (parsedInt != null) {
      // Exact integer → search only order_id
      whereClauses.add("order_id = ?");
      whereArgs.add(parsedInt);
    } else {
      // String search → remark + transaction.name + person.name
      final likePattern = '%$cleanSearch%';

      whereClauses.add("""
      (
        REPLACE(LOWER(payment_transactions.remark), ' ', '') LIKE ? OR
        REPLACE(LOWER(payment_transactions.name), ' ', '') LIKE ? OR
        payment_transactions.person_id IN (
          SELECT id FROM persons
          WHERE REPLACE(LOWER(name), ' ', '') LIKE ?
        )
      )
    """);

      whereArgs.addAll([likePattern, likePattern, likePattern]);
    }
  }

  // Build WHERE clause
  final whereString = whereClauses.isEmpty ? "" : "WHERE " + whereClauses.join(" AND ");

  // Pagination
  String limitString = "";
  if (pageSize > 0) {
  final offset = (pageNo) * pageSize;
  limitString = " LIMIT $pageSize OFFSET $offset";
  }

  final query = """
    SELECT payment_transactions.* FROM payment_transactions
    $whereString
    ORDER BY id DESC
    $limitString
  """;

  final result = await db.rawQuery(query, whereArgs);
  return result.map((e) => PaymentTransaction.fromMap(e)).toList();
}

/// Transactions Info
Future<int> getTransactionsCount({
  required Database db,
  int status = 0,
  int type = 0,
  int startDate = 0,
  int endDate = 0,
  int dueStart = 0,
  int dueEnd = 0,
  String? search,
  int? personId,
}) async
{
  final whereClauses = <String>[];
  final whereArgs = <dynamic>[];

  // --- Person Filter ---
  if (personId != null && personId != 0) {
    whereClauses.add("person_id = ?");
    whereArgs.add(personId);
  }

  // --- Status Filter ---
  switch (status) {
    case 1: whereClauses.add("payment_status = ?"); whereArgs.add("Paid"); break;
    case 2: 
      whereClauses.add("payment_status IN (?, ?)"); 
      whereArgs.addAll(["Pending", "Overdue"]); 
      break;
    case 3: whereClauses.add("payment_status = ?"); whereArgs.add("Overdue"); break;
  }

  // --- Type Filter ---
  String? method;
  switch (type) {
    case 1: method = "Cash"; break;
    case 2: method = "Digital"; break;
    case 3: method = "Bank"; break;
    case 4: method = "Other"; break;
  }
  if (method != null) {
    whereClauses.add("payment_method = ?");
    whereArgs.add(method);
  }

  // --- Date Filters ---
  if (startDate > 0) { whereClauses.add("timestamp >= ?"); whereArgs.add(startDate); }
  if (endDate > 0) { whereClauses.add("timestamp <= ?"); whereArgs.add(endDate); }
  if (dueStart > 0) { whereClauses.add("due_date >= ?"); whereArgs.add(dueStart); }
  if (dueEnd > 0) { whereClauses.add("due_date <= ?"); whereArgs.add(dueEnd); }

  // --- Search Filter ---
  if (search != null && search.isNotEmpty) {
    final cleanSearch =
    search.toLowerCase().replaceAll(RegExp(r'[ _\-\.,\"\ \\?/()]'), '');
    final parsedInt = int.tryParse(search);

    if (parsedInt != null) {
      whereClauses.add("order_id = ?");
      whereArgs.add(parsedInt);
    } else {
      final likePattern = '%$cleanSearch%';
      whereClauses.add("""
        (
          REPLACE(LOWER(payment_transactions.remark), ' ', '') LIKE ? OR
          REPLACE(LOWER(payment_transactions.name), ' ', '') LIKE ? OR
          payment_transactions.person_id IN (
            SELECT id FROM persons
            WHERE REPLACE(LOWER(name), ' ', '') LIKE ?
          )
        )
      """);
      whereArgs.addAll([likePattern, likePattern, likePattern]);
    }
  }

  final whereString =
  whereClauses.isEmpty ? "" : "WHERE ${whereClauses.join(" AND ")}";

  final query = """
    SELECT COUNT(*) as count
    FROM payment_transactions
    $whereString
  """;

  final result = await db.rawQuery(query, whereArgs);
  return (result.first.values.first as int?) ?? 0;
}


class newTransaction {
   int? id;
   int personId = 0;
   String name = "";
   String phone = "";
   int orderId = 0;
   double amount = 0.0;
   double paidAmount = 0.0;
   String paymentStatus = "Paid";      // Pending, Paid, Overdue
   int dueDate = 0;               // store as int (timestamp)
   String paymentMethod = "Digital";      // Digital, Cash, Bank, Other
   int timestamp = 0;             // created time
   int paymentTimestamp = 0;      // payment time
   String type = "Incoming";
   String remark = "";
    Uint8List? image;
    bool editable = true;
    newTransaction(){
      timestamp = DateTime.now().millisecondsSinceEpoch;
      paymentTimestamp = timestamp;
      print(paymentTimestamp);
    }
}