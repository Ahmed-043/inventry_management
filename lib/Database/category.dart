import 'package:sqflite/sqflite.dart';

class DBCategory {
  final int id;
  final String name;
  final int? sequence;

  DBCategory({required this.id, required this.name, this.sequence});

  factory DBCategory.fromMap(Map<String, dynamic> map) {
    return DBCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      sequence: map['sequence'] as int?,
    );
  }
}



Future<List<DBCategory>> getAllCategories(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'sequence ASC'
    );
    return maps.map((map) => DBCategory.fromMap(map)).toList();
  }

Future<void> updateAllSequences(Database db, List<DBCategory> categories) async {
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (int i = 0; i < categories.length; i++) {
        batch.update(
          'categories',
          {'sequence': i + 1},
          where: 'id = ?',
          whereArgs: [categories[i].id],
        );
      }

      await batch.commit(noResult: true);
    });
  }
