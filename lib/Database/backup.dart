import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_info.dart';

/// Check frequency and trigger backup for a single DB
Future<void> checkAndBackupDatabase(Database db) async {
  DBInfo info = await getDBInfo(db);
  final now = DateTime.now();
  final lastBackup = DateTime.fromMillisecondsSinceEpoch(info.lastBackup);

  bool shouldBackup = false;

  switch (info.backupFreq) {
    case 1: // daily
      shouldBackup = !isSameDay(lastBackup, now);
      break;
    case 2: // weekly
      shouldBackup = now.difference(lastBackup).inDays >= 7;
      break;
    case 3: // monthly
      shouldBackup = (now.year > lastBackup.year) || (now.month > lastBackup.month);
      break;
    default:
      return; // no backup
  }

  if (shouldBackup) {
    final success = await backupDatabase(db, info);
    if (success) {
      // Only update DB info if backup succeeded
      info.lastBackup = now.millisecondsSinceEpoch;
      await updateDBBackupInfo(db, info);
    }
  }
}

/// Perform backup and verify success
Future<bool> backupDatabase(Database db, DBInfo info) async {
  try {
    final username = Platform.environment['USERNAME'] ?? 'User';
    final defaultBackupDir = 'C:\\Users\\$username\\AppData\\Roaming\\Odventory\\Backup';
    final backupDir = info.backupDir.isEmpty ? defaultBackupDir : info.backupDir;

    final dir = Directory(backupDir);
    if (!await dir.exists()) await dir.create(recursive: true);

    final dbFile = File(db.path); // Correct: actual DB file path
    if (!await dbFile.exists()) return false;

    final backupPath = p.join(backupDir, p.basename(db.path));
    await dbFile.copy(backupPath);

    // Verify backup file exists
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) return false;

    // Save backupDir to info if it was empty
    if (info.backupDir.isEmpty) info.backupDir = backupDir;

    return true;
  } catch (e) {
    debugPrint('Backup failed: $e');
    return false;
  }
}

/// Update DBInfo table with new backup info
Future<void> updateDBBackupInfo(Database db, DBInfo info) async {
  await db.update(
    'info',
    {
      'backupDir': info.backupDir,
      'lastBackup': info.lastBackup,
    },
    where: 'db_name = ?',
    whereArgs: [info.dbName],
  );
}

/// Helper: check if two dates are same day
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
