import 'package:flutter/cupertino.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Expense {
  final int? id;
  final int categoryId;
  final String title;
  final double amount; // Positive for income, negative for outgone
  final String paymentMethod;
  final int expenseDate;
  final int personId;
  final String personName;
  final String remark;
  final int createdAt;

  Expense({
    this.id,
    this.categoryId = 0,
    required this.title,
    required this.amount,
    this.paymentMethod = 'Cash',
    required this.expenseDate,
    this.personId = 0,
    this.personName = '',
    this.remark = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'amount': amount,
      'payment_method': paymentMethod,
      'expense_date': expenseDate,
      'person_id': personId,
      'person_name': personName,
      'remark': remark,
      'created_at': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? 'Cash',
      expenseDate: map['expense_date'] as int? ?? 0,
      personId: map['person_id'] as int? ?? 0,
      personName: map['person_name'] as String? ?? '',
      remark: map['remark'] as String? ?? '',
      createdAt: map['created_at'] as int? ?? 0,
    );
  }

  static Future<int> insert(Database db, Expense expense) async {
    try {
      return await db.insert('expenses', expense.toMap());
    } catch (e) {
      debugPrint(e.toString());
      return -1;
    }
  }

  static Future<int> addIncome(Database db, {
    required String title,
    required double amount,
    int categoryId = 0,
    String paymentMethod = 'Cash',
    int? date,
    int personId = 0,
    String personName = '',
    String remark = '',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expense = Expense(
      title: title,
      amount: amount.abs(), // Ensure positive
      categoryId: categoryId,
      paymentMethod: paymentMethod,
      expenseDate: date ?? now,
      personId: personId,
      personName: personName,
      remark: remark,
      createdAt: now,
    );
    return await insert(db, expense);
  }

  static Future<int> addExpense(Database db, {
    required String title,
    required double amount,
    int categoryId = 0,
    String paymentMethod = 'Cash',
    int? date,
    int personId = 0,
    String personName = '',
    String remark = '',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expense = Expense(
      title: title,
      amount: -amount.abs(), // Ensure negative
      categoryId: categoryId,
      paymentMethod: paymentMethod,
      expenseDate: date ?? now,
      personId: personId,
      personName: personName,
      remark: remark,
      createdAt: now,
    );
    return await insert(db, expense);
  }

  static Future<List<Expense>> getAll(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'expense_date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  static Future<List<Expense>> getByDateRange(Database db, int start, int end) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'expense_date BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'expense_date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  static Future<int> update(Database db, Expense expense) async {
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<double> getTotalIncome(Database db) async {
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses WHERE amount > 0');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<double> getTotalExpense(Database db) async {
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses WHERE amount < 0');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<double> getNetBalance(Database db) async {
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<List<Expense>> getExpenses({
    required Database db,
    String? search,
    int? categoryId,
    String? paymentMethod,
    int? type, // 0: All, 1: Incoming (+), 2: Outgoing (-)
    int? startDate,
    int? endDate,
    int? personId,
    int pageNo = 0,
    int pageSize = 0,
  }) async {
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (search != null && search.trim().length >= searchSubstringLen) {
      final normalizedSearch = search.replaceAll(RegExp(r'[\s\-_.,]'), '').toLowerCase();
      final List<String> searchOrClauses = [];

      for (int i = 0; i <= normalizedSearch.length - searchSubstringLen; i++) {
        final window = normalizedSearch.substring(i, i + searchSubstringLen);
        final pattern = '%$window%';
        
        const normalization = "LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(%s, ' ', ''), '-', ''), '_', ''), '.', ''), ',', ''))";
        
        searchOrClauses.add("${normalization.replaceFirst('%s', 'title')} LIKE ?");
        whereArgs.add(pattern);
        searchOrClauses.add("${normalization.replaceFirst('%s', 'remark')} LIKE ?");
        whereArgs.add(pattern);
        searchOrClauses.add("${normalization.replaceFirst('%s', 'person_name')} LIKE ?");
        whereArgs.add(pattern);
      }

      if (searchOrClauses.isNotEmpty) {
        whereClauses.add('(${searchOrClauses.join(' OR ')})');
      }
    }
    if (categoryId != null && categoryId != 0) {
      whereClauses.add("category_id = ?");
      whereArgs.add(categoryId);
    }
    if (paymentMethod != null && paymentMethod != 'All') {
      whereClauses.add("payment_method = ?");
      whereArgs.add(paymentMethod);
    }
    if (type == 1) {
      whereClauses.add("amount > 0");
    } else if (type == 2) {
      whereClauses.add("amount < 0");
    }
    if (startDate != null && startDate != 0) {
      whereClauses.add("expense_date >= ?");
      whereArgs.add(startDate);
    }
    if (endDate != null && endDate != 0) {
      whereClauses.add("expense_date <= ?");
      whereArgs.add(endDate);
    }
    if (personId != null && personId != 0) {
      whereClauses.add("person_id = ?");
      whereArgs.add(personId);
    }

    String? where = whereClauses.isEmpty ? null : whereClauses.join(" AND ");

    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'expense_date DESC',
      limit: pageSize > 0 ? pageSize : null,
      offset: pageSize > 0 ? pageNo * pageSize : null,
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  static Future<int> getExpensesCount({
    required Database db,
    String? search,
    int? categoryId,
    String? paymentMethod,
    int? type, // 0: All, 1: Incoming (+), 2: Outgoing (-)
    int? startDate,
    int? endDate,
    int? personId,
  }) async {
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (search != null && search.trim().length >= searchSubstringLen) {
      final normalizedSearch = search.replaceAll(RegExp(r'[\s\-_.,]'), '').toLowerCase();
      final List<String> searchOrClauses = [];

      for (int i = 0; i <= normalizedSearch.length - searchSubstringLen; i++) {
        final window = normalizedSearch.substring(i, i + searchSubstringLen);
        final pattern = '%$window%';
        
        const normalization = "LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(%s, ' ', ''), '-', ''), '_', ''), '.', ''), ',', ''))";
        
        searchOrClauses.add("${normalization.replaceFirst('%s', 'title')} LIKE ?");
        whereArgs.add(pattern);
        searchOrClauses.add("${normalization.replaceFirst('%s', 'remark')} LIKE ?");
        whereArgs.add(pattern);
        searchOrClauses.add("${normalization.replaceFirst('%s', 'person_name')} LIKE ?");
        whereArgs.add(pattern);
      }

      if (searchOrClauses.isNotEmpty) {
        whereClauses.add('(${searchOrClauses.join(' OR ')})');
      }
    }
    if (categoryId != null && categoryId != 0) {
      whereClauses.add("category_id = ?");
      whereArgs.add(categoryId);
    }
    if (paymentMethod != null && paymentMethod != 'All') {
      whereClauses.add("payment_method = ?");
      whereArgs.add(paymentMethod);
    }
    if (type == 1) {
      whereClauses.add("amount > 0");
    } else if (type == 2) {
      whereClauses.add("amount < 0");
    }
    if (startDate != null && startDate != 0) {
      whereClauses.add("expense_date >= ?");
      whereArgs.add(startDate);
    }
    if (endDate != null && endDate != 0) {
      whereClauses.add("expense_date <= ?");
      whereArgs.add(endDate);
    }
    if (personId != null && personId != 0) {
      whereClauses.add("person_id = ?");
      whereArgs.add(personId);
    }

    String? where = whereClauses.isEmpty ? null : whereClauses.join(" AND ");

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses ${where != null ? "WHERE $where" : ""}',
      whereArgs,
    );
    return (result.first.values.first as int?) ?? 0;
  }
}
