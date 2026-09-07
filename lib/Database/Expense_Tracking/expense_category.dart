import 'package:flutter/cupertino.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ExpenseCategory {
  final int? id;
  final String name;
  final String icon;
  final int sequence;
  final int active;

  ExpenseCategory({
    this.id,
    required this.name,
    this.icon = '',
    this.sequence = 0,
    this.active = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'sequence': sequence,
      'active': active,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '',
      sequence: map['sequence'] as int? ?? 0,
      active: map['active'] as int? ?? 1,
    );
  }

  static Future<int> insert(Database db, ExpenseCategory category) async {
    try {
      return await db.insert('expense_categories', category.toMap());
    } catch (e) {
      debugPrint(e.toString());
      return -1;
    }
  }

  static Future<List<ExpenseCategory>> getAll(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_categories',
      orderBy: 'sequence ASC',
    );
    return maps.map((map) => ExpenseCategory.fromMap(map)).toList();
  }

  static Future<int> update(Database db, ExpenseCategory category) async {
    return await db.update(
      'expense_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      'expense_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
