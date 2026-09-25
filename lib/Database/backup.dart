import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_info.dart';
import 'Reports_Data/export_database.dart';
import '../utils/google_drive_service.dart';

/// Check frequency and trigger backup for a single DB
Future<void> checkAndBackupDatabase(Database db) async {
  debugPrint("🔄 BACKUP SCHEDULER CHECKING");
  
  DBInfo info = await getDBInfo(db);
  final now = DateTime.now();
  final lastBackup = DateTime.fromMillisecondsSinceEpoch(info.lastBackup);
  final lastCloudBackup = DateTime.fromMillisecondsSinceEpoch(info.lastCloudBackup);

  // Always perform Excel backups (Daily, Weekly, Monthly)
  await _handleExcelBackups(db, info, lastBackup, now);

  bool shouldBackupLocal = false;
  bool shouldBackupCloud = false;

  if (info.backupFreq != 0) {
    switch (info.backupFreq) {
      case 1: // daily
        shouldBackupLocal = !isSameDay(lastBackup, now);
        shouldBackupCloud = info.googleBackup == 1 && !isSameDay(lastCloudBackup, now);
        break;
      case 2: // weekly
        shouldBackupLocal = now.difference(lastBackup).inDays >= 7;
        shouldBackupCloud = info.googleBackup == 1 && now.difference(lastCloudBackup).inDays >= 7;
        break;
      case 3: // monthly
        shouldBackupLocal = (now.year > lastBackup.year) || (now.month > lastBackup.month);
        shouldBackupCloud = info.googleBackup == 1 && ((now.year > lastCloudBackup.year) || (now.month > lastCloudBackup.month));
        break;
    }
  }

  if (!shouldBackupLocal && !shouldBackupCloud) {
    debugPrint("✅ Already backed up for today / Frequency not met");
    return;
  }

  // Handle Local Backup
  if (shouldBackupLocal) {
    debugPrint("📂 Starting Scheduled Local Backup...");
    final success = await backupDatabase(db, info);
    debugPrint('🪢Local Backup success: $success');
    if (success) {
      info.lastBackup = now.millisecondsSinceEpoch;
      await updateDBBackupInfo(db, info);
    }
  }

  // Handle Cloud Backup independently if enabled
  if (shouldBackupCloud) {
    debugPrint("☁️ Starting Scheduled Cloud Backup...");
    final googleService = GoogleDriveService();
    final user = await googleService.getCurrentUser();
    if (user != null) {
      final dbFile = File(db.path);
      final cloudSuccess = await googleService.uploadFile(dbFile);
      if (cloudSuccess) {
        debugPrint('☁️Cloud Backup success');
        info.lastCloudBackup = now.millisecondsSinceEpoch;
        await updateDBBackupInfo(db, info);
        await addBackupLog(info.dbName, true, "Cloud backup completed successfully", type: "Cloud");
      } else {
        debugPrint('☁️Cloud Backup failed');
        await addBackupLog(info.dbName, false, "Cloud upload failed", type: "Cloud");
      }
    } else {
      debugPrint('☁️Cloud Backup failed: User not logged in');
      await addBackupLog(info.dbName, false, "Cloud backup failed: Google account not connected", type: "Cloud");
    }
  }
}

Timer? _backupTimer;

/// Starts a periodic timer that checks every hour if a backup is due.
/// This handles the case where the app remains open across midnight.
void startBackupScheduler(Database db) {
  _backupTimer?.cancel();
  // Check once immediately
  checkAndBackupDatabase(db);
  
  // Then check every 30 minutes
  _backupTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
    try {
      if (db.isOpen) {
        await checkAndBackupDatabase(db);
      } else {
        timer.cancel();
        _backupTimer = null;
      }
    } catch (e) {
      debugPrint("Error in BackupScheduler: $e");
    }
  });
}

/// Stops the periodic backup timer.
void stopBackupScheduler() {
  _backupTimer?.cancel();
  _backupTimer = null;
  debugPrint("🛑 BACKUP SCHEDULER STOPPED");
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

    final String dbPath = db.path;
    final String backupPath = p.join(backupDir, p.basename(dbPath));

    // SQLite's VACUUM INTO requires the destination file to NOT exist.
    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    // Use a SEPARATE connection for the backup to avoid locking the main "live" connection.
    // This implements the "backup with copy of database" approach.
    final Database backupConnection = await openDatabase(
      dbPath,
      readOnly: true,
      singleInstance: false, // Ensure we get a fresh connection
    );

    try {
      final escapedPath = backupPath.replaceAll("'", "''");
      await backupConnection.execute("VACUUM INTO '$escapedPath'");
    } finally {
      await backupConnection.close();
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
Future<void> addBackupLog(String dbName, bool success, String? error, {String type = "Local"}) async {
  final log = {
    'dbName': dbName,
    'datetime': DateTime.now().toIso8601String(),
    'status': success ? 'Success' : 'Failed',
    'error': error ?? '',
    'type': type,
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
      'lastCloudBackup': info.lastCloudBackup,
    },
    where: 'db_name = ?',
    whereArgs: [info.dbName],
  );
}

/// Helper: check if two dates are same day
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
