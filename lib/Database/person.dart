import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Person {
  final int? id;
   String name;
  final String? phone;
  final String? address;
  final String? email;
  final String type;
  final String personType;
  final Uint8List? image;
  final double payment;
  final double incoming;
  final double outgoing;



  Person({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.payment = 0.0,
    this.incoming = 0.0,
    this.outgoing = 0.0,
    this.image,
    this.type = 'local',
    this.personType = 'customer',
  });

  Map<String, dynamic> toMap({required String table}) {
    final map = {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email' : email,
      'payment' : payment,
      'image': image,
      'type': type,
      'personType' : personType,
    };
    return map;
  }

  factory Person.fromMap(Map<String, dynamic> map, {required String table}) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      email:  map['email'] as String?,
      payment: (map['payment'] as num?)?.toDouble() ?? 0.0,
      incoming: (map['incoming'] as num?)?.toDouble() ?? 0.0,
      outgoing: (map['outgoing'] as num?)?.toDouble() ?? 0.0,
      image: (map['image'] != null && map['image'] is Uint8List)
          ? map['image'] as Uint8List
          : null,
      type: map['type'] as String? ?? 'local',
      personType: map['personType'] as String? ?? 'customer'
    );
  }

  static Future<int> insert(Database db, Person person) async {
    try{
      String table = 'persons';
      return await db.insert(table, person.toMap(table: table));
    }catch(e){
      debugPrint(e.toString());
      return -1;
    }
  }

  static Future<List<Person>> getAll(Database db) async {
    String table = 'persons';
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'personType = ?',
      whereArgs: ['customer'],);
    return maps.map((map) => Person.fromMap(map, table: table)).toList();
  }
}


Future<List<Person>> getPersons(
    Database db, {
      required String personType,
      required int page,
      required int pageSize,
      String? search,
      int scope = 0,
    }) async {
  final offset = page * pageSize;

  final List<String> whereClauses = ['p.personType = ?'];
  final List<Object?> args = [personType];

  // 🔹 Scope filters
  if (scope == 2) {
    whereClauses.add("p.type = 'major'");
  } else if (scope == 3) {
    whereClauses.add("p.type = 'local'");
  }

  // 🔹 Case-insensitive search
  if (search != null && search.trim().isNotEmpty) {
    whereClauses.add('''
      (
        LOWER(p.name) LIKE ?
        OR LOWER(p.phone) LIKE ?
        OR LOWER(p.email) LIKE ?
        OR LOWER(p.address) LIKE ?
      )
    ''');
    final q = '%${search.toLowerCase()}%';
    args.addAll([q, q, q, q]);
  }

  // 🔹 Pending-only scope (transaction-based, NOT person table)
  final havingClause = (scope == 1)
      ? 'HAVING total_payment > 0 OR total_payment < 0'
      : '';

  final result = await db.rawQuery('''
    SELECT 
      p.*,
      IFNULL(SUM(
        CASE 
          WHEN t.payment_status IN ('Pending','Overdue')
          THEN (t.amount - t.paid_amount)
          ELSE 0
        END
      ), 0) AS total_payment,
      IFNULL(SUM(
        CASE 
          WHEN t.payment_status IN ('Pending','Overdue') AND t.amount > 0 
          THEN (t.amount - t.paid_amount) 
          ELSE 0 
        END
      ), 0) AS incoming,
      IFNULL(SUM(
        CASE 
          WHEN t.payment_status IN ('Pending','Overdue') AND t.amount < 0
          THEN ABS(t.amount - t.paid_amount) 
          ELSE 0 
        END
      ), 0) AS outgoing
    FROM persons p
    LEFT JOIN payment_transactions t
      ON t.person_id = p.id
    WHERE ${whereClauses.join(' AND ')}
    GROUP BY p.id
    $havingClause
    LIMIT ? OFFSET ?
  ''', [...args, pageSize, offset]);

  return result.map((map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      email: map['email'] as String?,
      payment: (map['total_payment'] as num).toDouble(),
      incoming: (map['incoming'] as num).toDouble(),
      outgoing: (map['outgoing'] as num).toDouble(),
      image: map['image'] as Uint8List?,
      type: map['type'] as String,
      personType: map['personType'] as String,
    );
  }).toList();
}



Future<Person?> getPersonById(Database db, int id) async {
  final List<Map<String, dynamic>> maps = await db.query(
    'persons',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );

  if (maps.isNotEmpty) {
    return Person.fromMap(maps.first, table: 'persons');
  } else {
    return null; // no person found
  }
}


Future<int> updatePerson(Database db, {
  required int id,
  String? name,
  String? phone,
  String? address,
  String? email,
  String? type,
  String? personType,
  Uint8List? image,
}) async {
  final Map<String, dynamic> values = {};
  if (name != null) values['name'] = name;
   values['phone'] = phone;
   values['address'] = address;
   values['email'] = email;
  if (type != null) values['type'] = type;
  if (personType != null) values['personType'] = personType;
   values['image'] = image;

  return await db.update(
    'persons',
    values,
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> deletePerson(Database db, int id) async {
  return await db.delete(
    'persons',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<List<Person>> getAllPersons(
    Database db, {
      String? search,
      int filter = 0, // 0=all, 1=customers, 2=suppliers
    }) async {
  String? where;
  List<Object?>? whereArgs;

  if (search != null && search.isNotEmpty) {
    where = 'LOWER(name) LIKE ?';
    whereArgs = ['%${search.toLowerCase()}%'];
  }

  if (filter == 1) {
    where = (where != null) ? '$where AND personType = ?' : 'personType = ?';
    (whereArgs ??= []).add('customer');
  } else if (filter == 2) {
    where = (where != null) ? '$where AND personType = ?' : 'personType = ?';
    (whereArgs ??= []).add('supplier');
  }

  final maps = await db.query(
    'persons',
    where: where,
    whereArgs: whereArgs,
  );

  return maps.map((map) => Person(
    id: map['id'] as int?,
    name: map['name'] as String,
    phone: map['phone'] as String?,
    address: map['address'] as String?,
    email: map['email'] as String?,
    payment: (map['payment'] as num?)?.toDouble() ?? 0.0,
    image: map['image'] as Uint8List?,
    type: map['type'] as String,
    personType: map['personType'] as String,
  )).toList();
}

Future<List<Map<String, dynamic>>> getPersonIdsAndNames(Database db) async {
  final result = await db.query(
    'persons',
    columns: ['id', 'name'], // only id and name
  );
  return result; // List of maps: [{'id': 1, 'name': 'Ali'}, ...]
}

Future<Map<String, int>> getPersonsCountByType(
    Database db, {
      required String personType,
      String? search,
    }) async {
  final List<String> whereClauses = ['p.personType = ?'];
  final List<Object?> args = [personType];

  // 🔹 Case-insensitive search
  if (search != null && search.trim().isNotEmpty) {
    whereClauses.add('''
      (
        LOWER(p.name) LIKE ?
        OR LOWER(p.phone) LIKE ?
        OR LOWER(p.email) LIKE ?
        OR LOWER(p.address) LIKE ?
      )
    ''');
    final q = '%${search.toLowerCase()}%';
    args.addAll([q, q, q, q]);
  }

  final result = await db.rawQuery('''
    SELECT
      COUNT(DISTINCT p.id) AS all_count,

      COUNT(DISTINCT CASE 
        WHEN p.type = 'major' THEN p.id 
      END) AS major_count,

      COUNT(DISTINCT CASE 
        WHEN p.type = 'local' THEN p.id 
      END) AS local_count,

      COUNT(DISTINCT CASE 
        WHEN t.payment_status IN ('Pending','Overdue')
             AND t.amount > 0
        THEN p.id
      END) AS pending_count

    FROM persons p
    LEFT JOIN payment_transactions t
      ON t.person_id = p.id
    WHERE ${whereClauses.join(' AND ')}
  ''', args);

  final row = result.first;

  return {
    'all': (row['all_count'] as int?) ?? 0,
    'pending': (row['pending_count'] as int?) ?? 0,
    'major': (row['major_count'] as int?) ?? 0,
    'local': (row['local_count'] as int?) ?? 0,
  };
}


