import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


class DBInfo {
  int? id;
  String dbName;
  String description;
  Uint8List? image;
  String location;
  String phone;
  String backupDir;
  int lastBackup;
  int backupFreq;

  DBInfo({
    this.id,
    required this.dbName,
    this.description = '',
    this.image,
    this.location = '',
    this.phone = '',
    this.backupDir = '',
    this.lastBackup = 0,
    this.backupFreq = 0
  });

  // Convert from DB row to Info object
  factory DBInfo.fromMap(Map<String, dynamic> map) {
    return DBInfo(
      id: map['id'],
      dbName: map['db_name'],
      description: map['description'] ?? '',
      image: map['image'],
      location: map['location'] ?? '',
      phone: map['phone'] ?? '',
      backupDir: map['backupDir'] ?? '',
      lastBackup: map['lastBackup'] ?? 0,
      backupFreq: map['backupFreq'] ?? 0,
    );
  }

  // Convert Info object to Map for DB insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'db_name': dbName,
      'description': description,
      'image': image,
      'location': location,
      'phone': phone,
      'backupDir': backupDir,
      'lastBackup': lastBackup,
      'backupFreq': backupFreq,
    };
  }
}


Future<bool> updateDBInfo(Database db, DBInfo info) async {
  // Fetch first row using rowid
  final row = await db.query(
    'info',
    columns: ['rowid'],
    limit: 1,
  );

  if (row.isEmpty) return false;

  final int rowId = row.first['rowid'] as int;

  final rows = await db.update(
    'info',
    {
      'db_name': info.dbName,
      'description': info.description,
      'image': info.image,
      'location': info.location,
      'phone': info.phone,
    },
    where: 'rowid = ?',
    whereArgs: [rowId],
  );

  return rows > 0;
}



Future<DBInfo> getDBInfo(Database db) async {
  try {
    final result = await db.query(
      'info',
      columns: ['db_name', 'description', 'image','phone','location','backupDir','lastBackup','backupFreq'],
      limit: 1,
    );
    final i = DBInfo.fromMap(result.first);
    print(i.dbName);
    return DBInfo.fromMap(result.first);
  }catch(e){
    debugPrint(e.toString());
    return DBInfo(dbName: 'Company Name',location: '',phone: '');
  }
}

