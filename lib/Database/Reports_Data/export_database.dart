import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// Export database to Excel in the background to avoid UI freezing.
Future<String?> exportDatabaseToExcel(
  Database db,
  String folderPath, {
  String? fileName,
}) async {
  // Since we can't pass a Database object to an isolate, 
  // we pass the path and let the isolate open its own connection.
  final dbPath = db.path;
  
  return compute(_exportTask, {
    'dbPath': dbPath,
    'folderPath': folderPath,
    'fileName': fileName,
  });
}

Future<String?> _exportTask(Map<String, dynamic> params) async {
  final String dbPath = params['dbPath'];
  final String folderPath = params['folderPath'];
  final String? fileName = params['fileName'];

  Database? db;
  try {
    // Initialize FFI for the isolate
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    db = await openDatabase(dbPath, readOnly: true);
    
    final workbook = xlsio.Workbook();

    final tables = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type='table'
      AND name NOT LIKE 'sqlite_%'
      AND name NOT LIKE 'android_metadata';
      ''',
    );

    if (tables.isEmpty) {
      workbook.dispose();
      return null;
    }

    final List<String> usedSheetNames = [];

    for (int i = 0; i < tables.length; i++) {
      final tableName = tables[i]['name'] as String;
      String sanitizedSheetName = _sanitizeSheetName(tableName);

      // Handle potential name collisions after truncation/sanitization
      int counter = 1;
      String originalSanitized = sanitizedSheetName;
      while (usedSheetNames.contains(sanitizedSheetName)) {
        String suffix = "_$counter";
        int maxLen = 31 - suffix.length;
        sanitizedSheetName = (originalSanitized.length > maxLen
                ? originalSanitized.substring(0, maxLen)
                : originalSanitized) +
            suffix;
        counter++;
      }
      usedSheetNames.add(sanitizedSheetName);

      final xlsio.Worksheet sheet;
      if (i == 0) {
        sheet = workbook.worksheets[0];
        sheet.name = sanitizedSheetName;
      } else {
        sheet = workbook.worksheets.addWithName(sanitizedSheetName);
      }

      final rows = await db.query(tableName);

      if (rows.isEmpty) {
        sheet.getRangeByIndex(1, 1).setText("No data available in this table");
        continue;
      }

      final columnNames = rows.first.keys.toList();

      // Write headers
      for (int c = 0; c < columnNames.length; c++) {
        final cell = sheet.getRangeByIndex(1, c + 1);
        cell.setText(_sanitizeString(columnNames[c]));
        cell.cellStyle.bold = true;
      }

      // Write data
      for (int r = 0; r < rows.length; r++) {
        final row = rows[r];

        for (int c = 0; c < columnNames.length; c++) {
          final value = row[columnNames[c]];
          final cell = sheet.getRangeByIndex(r + 2, c + 1);

          if (value == null) {
            cell.setText('');
          } else if (value is int) {
            cell.setNumber(value.toDouble());
          } else if (value is double) {
            cell.setNumber(value);
          } else if (value is bool) {
            cell.setText(value ? "TRUE" : "FALSE");
          } else {
            cell.setText(_sanitizeString(value.toString()));
          }
        }
      }

      // Auto-fit columns
      for (int c = 1; c <= columnNames.length; c++) {
        sheet.autoFitColumn(c);
      }
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    String finalFileName = fileName ?? "Inventory_Backup_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    if (!finalFileName.toLowerCase().endsWith('.xlsx')) {
      finalFileName += '.xlsx';
    }
    
    final fullPath = p.join(folderPath, finalFileName);

    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    return fullPath;
  } catch (e) {
    stderr.writeln("Error exporting database: $e");
    return null;
  } finally {
    await db?.close();
  }
}

/// Sanitizes the sheet name to comply with Excel constraints:
/// 1. Maximum 31 characters.
/// 2. Cannot contain characters: \ / ? * [ ] :
/// 3. Cannot be empty.
String _sanitizeSheetName(String name) {
  String sanitized = name.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_');
  // Remove control characters (0x00 to 0x1F)
  sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F]'), '');
  if (sanitized.length > 31) {
    sanitized = sanitized.substring(0, 31);
  }
  return sanitized.isEmpty ? 'Sheet' : sanitized;
}

/// Sanitizes string content to avoid Excel corruption:
/// 1. Truncates to Excel's cell limit (32,767 characters).
/// 2. Removes illegal XML 1.0 control characters that cause "sharedStrings.xml" errors.
String _sanitizeString(String input) {
  if (input.length > 32767) {
    input = input.substring(0, 32767);
  }
  // Remove invalid XML control characters: #x00-#x08, #x0B, #x0C, #x0E-#x1F
  return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
}
