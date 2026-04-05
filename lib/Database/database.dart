import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:inventry_management/Database/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_factory.dart';


Database? currentDB;
int? productsPerPage, transactionsPerPage, personsPerPage, ordersPerPage;
double? cardSize;
double? personCardSize;
bool performanceMode = false, plainUi = true, tileUi = false;
int lowStockLimit = 50, sortCategory = 0,sort = 9;

Future<bool> createDatabase({required String dbName, Directory? path, Uint8List? image}) async {
  await initDatabaseFactory();

  Directory docsDir = path ?? await getApplicationDocumentsDirectory();
  if (dbName.trim().isEmpty) dbName = 'default_db';

  String dbPath = p.join(docsDir.path, "Odventory", "$dbName.db");

  if (await File(dbPath).exists()) {
    // if it exists, open and assign to currentDB
    currentDB = await openDatabase(dbPath);
    return false;
  }

  await Directory(p.dirname(dbPath)).create(recursive: true);

  // assign currentDB instead of a local db variable
  currentDB = await openDatabase(dbPath);

  try {
    await createTables(currentDB!);
    await savePath(dbPath: dbPath);
    await currentDB!.insert(
      'info',
      {
        'db_name': dbName,
        'description': '',
        if (image != null) 'image': image,
      },
    );
  } catch (e) {
    debugPrint("Database creation error: ${e.toString()}");
  }

  return true;
}


Future<void> createTables(Database db) async {
  for (final entry in dbSchema.entries) {
    final table = entry.key;
    final cols = entry.value.entries.map((e) => '${e.key} ${e.value}').join(', ');
    await db.execute('CREATE TABLE $table ($cols)');
  }
}

Future<bool> validateDatabaseSchema(Database db) async {
  bool isValid = true;

  // Fetch all user-defined tables
  final tablesResult = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");

  final existingTables = tablesResult.map((t) => (t['name'] ?? '').toString()).toSet();
  final requiredTables = dbSchema.keys.toSet();

  // 🔍 Check missing tables
  final missingTables = requiredTables.difference(existingTables);
  if (missingTables.isNotEmpty) {
    debugPrint("❌ Missing tables: $missingTables");
    isValid = false;
  }

  // 🔍 Check missing columns in existing tables
  for (final table in requiredTables.intersection(existingTables)) {
    final pragma = await db.rawQuery("PRAGMA table_info($table)");
    final existingCols = pragma.map((r) => r['name'].toString()).toSet();
    final requiredCols = dbSchema[table]!.keys.toSet();
    final missingCols = requiredCols.difference(existingCols);

    if (missingCols.isNotEmpty) {
      debugPrint("❌ Table '$table' is missing columns: $missingCols");
      debugPrint("   Existing columns: $existingCols");
      debugPrint("   Required columns: $requiredCols");
      isValid = false;
    }
  }

  if (isValid) {
    debugPrint("✅ Database schema is fully valid (all tables + columns OK)");
  } else {
    debugPrint("❌ Database schema is invalid — see details above.");
  }

  return isValid;
}

Future<void> ensureDatabaseSchema(Database db) async {
  for (final entry in dbSchema.entries) {
    final table = entry.key;
    final cols = entry.value;

    // Step 1: Check if table exists
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    final tableExists = (result.first['count'] as int? ?? 0) > 0;

    // Step 2: Create table if missing
    if (!tableExists) {
      final defs = cols.entries.map((e) => "${e.key} ${e.value}").join(", ");
      await db.execute("CREATE TABLE $table ($defs)");
      continue;
    }

    // Step 3: Check and add missing columns
    final existingCols = (await db.rawQuery("PRAGMA table_info($table)"))
        .map((row) => row['name'] as String)
        .toSet();

    for (final colEntry in cols.entries) {
      if (!existingCols.contains(colEntry.key)) {
        await db.execute("ALTER TABLE $table ADD COLUMN ${colEntry.key} ${colEntry.value}");
      }
    }
  }
}

Future<void> savePath({required String dbPath}) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> dbs = prefs.getStringList('db_paths') ?? [];

  // only save the path
  if (!dbs.contains(dbPath)) dbs.add(dbPath);

  await prefs.setStringList('db_paths', dbs);
  prefs.setString('dbPath',dbPath);
}

Future<List<String>> getDbPaths() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('db_paths') ?? [];
}

clearPref(){
  clear();
}
clear() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.clear();
}

Future<void> syncDatabases() async {
  // Get the documents directory
  final Directory docsDir = await getApplicationDocumentsDirectory();
  final Directory odventoryDir = Directory(p.join(docsDir.path, "Odventory"));

  if (!await odventoryDir.exists()) return; // No database folder

  // List all .db files
  final dbFiles = odventoryDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.db'))
      .map((f) => f.path)
      .toList();

  final prefs = await SharedPreferences.getInstance();
  final existingDbs = prefs.getStringList('db_paths') ?? [];

  // Add only new DB paths
  for (final dbPath in dbFiles) {
    if (!existingDbs.contains(dbPath)) {
      existingDbs.add(dbPath);
    }
  }

  await prefs.setStringList('db_paths', existingDbs);
}