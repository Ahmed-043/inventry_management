import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;
import 'package:sqflite_common/sqflite.dart' as common;

Future<void> initDatabaseFactory() async {
  if (kIsWeb) {
    common.databaseFactory = ffi_web.databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    ffi.sqfliteFfiInit();
    common.databaseFactory = ffi.databaseFactoryFfi;
  } else {
    common.databaseFactory = sqflite.databaseFactory;
  }
}
