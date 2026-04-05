import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';


class PaymentTransaction {
  final int? id;
  final int personId;
  String name;
  final int orderId;
  final double amount;
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
  final data = p.toMap();       // keep your map as it is
  data.remove('id');            // <-- remove id safely
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
    }) async
{

  // Fetch current status
  final check = await db.query(
    'payment_transactions',
    columns: ['payment_status', 'order_id'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );

  if (check.isEmpty) return false; // Not found

  final currentStatus = check.first['payment_status'] as String;
  final currentOrderId = check.first['order_id'] as int;

  if (currentStatus == 'Paid') {
    return false; // Cannot overwrite paid transaction
  }

  // Update transaction only
  final rows = await db.update(
    'payment_transactions',
    {
      'payment_status': paymentStatus,
      'due_date': dueDate,
      'payment_method': paymentMethod,
      'payment_timestamp': paymentTimestamp,
      'remark': remark,
    },
    where: 'id = ?',
    whereArgs: [id],
  );

  // If update failed, stop here
  if (rows <= 0) return false;

  // Reflect on ORDER if orderId > 0 or transaction has an order > 0
  final targetOrderId = currentOrderId;
  if (targetOrderId > 0) {
    // If transaction is Paid => Complete the order
    if (paymentStatus == 'Paid') {
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
          'payment_status': paymentStatus,
          'due_date': dueDate,
        },
        where: 'id = ?',
        whereArgs: [targetOrderId],
      );
    }
  }

  return true;
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
}) async
{
  final whereClauses = <String>[];
  final whereArgs = <dynamic>[];

  // --- Status Filter ---
  switch (status) {
    case 1: whereClauses.add("payment_status = ?"); whereArgs.add("Paid"); break;
    case 2: whereClauses.add("payment_status = ?"); whereArgs.add("Pending"); break;
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
}) async
{
  final whereClauses = <String>[];
  final whereArgs = <dynamic>[];

  // --- Status Filter ---
  switch (status) {
    case 1: whereClauses.add("payment_status = ?"); whereArgs.add("Paid"); break;
    case 2: whereClauses.add("payment_status = ?"); whereArgs.add("Pending"); break;
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