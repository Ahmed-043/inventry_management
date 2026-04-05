import 'package:flutter/cupertino.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

deleteProduct(Database db, int id) async {
  var a =  await db.delete(
    'products',
    where: 'id = ?',
    whereArgs: [id],
  );
  debugPrint("Deleted rows: $a");
}
