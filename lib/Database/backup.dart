import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_info.dart';
import 'Reports_Data/export_database.dart';

/// Check frequency and trigger backup for a single DB
Future<void> checkAndBackupDatabase(Database db) async {
  DBInfo info = await getDBInfo(db);
  final now = DateTime.now();
  final lastBackup = DateTime.fromMillisecondsSinceEpoch(info.lastBackup);

  // Always perform Excel backups (Daily, Weekly, Monthly)
  await _handleExcelBackups(db, info, lastBackup, now);

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

    debugPrint('🪢Backup success: $success');

    if (success) {
      // Only update DB info if backup succeeded
      info.lastBackup = now.millisecondsSinceEpoch;
      await updateDBBackupInfo(db, info);
    }
  }
}

/// Handles Excel backups (Daily, Weekly, Monthly) based on lastBackup timestamp
Future<void> _handleExcelBackups(Database db, DBInfo info, DateTime lastBackup, DateTime now) async {
  try {
    final username = Platform.environment['USERNAME'] ?? 'User';
    final defaultBackupDir = 'C:\\Users\\$username\\AppData\\Roaming\\Odventory\\Backup';
    final backupDir = info.backupDir.isEmpty ? defaultBackupDir : info.backupDir;
    
    final dir = Directory(backupDir);
    if (!await dir.exists()) await dir.create(recursive: true);

    // 1. Daily Backup: Required if lastBackup was not today
    if (!isSameDay(lastBackup, now)) {
      final file = File(p.join(backupDir, "${info.dbName} Daily Backup.xlsx"));
      // Safeguard: don't re-export if we already did it today
      if (!await file.exists() || !isSameDay(await file.lastModified(), now)) {
        final result = await exportDatabaseToExcel(db, backupDir, fileName: "${info.dbName} Daily Backup");
        if (result == null) await addBackupLog(info.dbName, false, "Daily Excel export failed");
      }
    }

    // 2. Weekly Backup: Required if lastBackup was 7+ days ago
    if (now.difference(lastBackup).inDays >= 7) {
      final file = File(p.join(backupDir, "${info.dbName} weekly Backup.xlsx"));
      // Safeguard: don't re-export if we already did it in the last 7 days
      if (!await file.exists() || now.difference(await file.lastModified()).inDays >= 7) {
        final result = await exportDatabaseToExcel(db, backupDir, fileName: "${info.dbName} weekly Backup");
        if (result == null) await addBackupLog(info.dbName, false, "Weekly Excel export failed");
      }
    }

    // 3. Monthly Backup: Required if lastBackup was in a previous month/year
    if (now.year > lastBackup.year || now.month > lastBackup.month) {
      final file = File(p.join(backupDir, "${info.dbName} monthly Backup.xlsx"));
      bool fileNeedsUpdate = !await file.exists();
      if (!fileNeedsUpdate) {
        final lastMod = await file.lastModified();
        fileNeedsUpdate = (now.year > lastMod.year || now.month > lastMod.month);
      }
      
      if (fileNeedsUpdate) {
        final result = await exportDatabaseToExcel(db, backupDir, fileName: "${info.dbName} monthly Backup");
        if (result == null) await addBackupLog(info.dbName, false, "Monthly Excel export failed");
      }
    }
  } catch (e) {
    debugPrint('Excel backup failed: $e');
    await addBackupLog(info.dbName, false, "Excel backup process failed: $e");
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
    if (!await dbFile.exists()) {
      await addBackupLog(info.dbName, false, "Source database file not found");
      return false;
    }

    final backupPath = p.join(backupDir, p.basename(db.path));
    await dbFile.copy(backupPath);

    // Verify backup file exists
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      await addBackupLog(info.dbName, false, "Backup file verification failed");
      return false;
    }

    // Save backupDir to info if it was empty
    if (info.backupDir.isEmpty) info.backupDir = backupDir;

    await addBackupLog(info.dbName, true, null);
    return true;
  } catch (e) {
    debugPrint('Backup failed: $e');
    await addBackupLog(info.dbName, false, e.toString());
    return false;
  }
}

/// Adds a log entry for the backup process to SharedPreferences
Future<void> addBackupLog(String dbName, bool success, String? error) async {
  final log = {
    'dbName': dbName,
    'datetime': DateTime.now().toIso8601String(),
    'status': success ? 'Success' : 'Failed',
    'error': error ?? '',
  };
  try {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('backup_logs') ?? [];
    logs.add(jsonEncode(log));
    // Keep only last 100 logs to prevent SharedPreferences from growing too large
    if (logs.length > 100) {
      logs = logs.sublist(logs.length - 100);
    }
    await prefs.setStringList('backup_logs', logs);
  } catch (e) {
    debugPrint('Failed to save backup log: $e');
  }
}

/// Clears all backup logs from SharedPreferences
Future<void> clearBackupLogs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backup_logs');
  } catch (e) {
    debugPrint('Failed to clear backup logs: $e');
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
