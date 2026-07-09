import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../Database/Reports_Data/stock_snapshot_logic.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';

/// Constants used throughout the Reports module
class ReportsConstants {
  // Table dimensions
  static const double productColWidth = 150;
  static const double dataColWidth = 120;
  static const double totalValueWidth = 135;
  static const double rowHeight = 60;
  static const double headerHeight = 50;

  // Search debounce duration
  static const int searchDebounceMsec = 500;

  // UI spacing
  static const double horizontalPadding = 10;
  static const double verticalSpacing = 10;

  // Date picker defaults
  static const int minDateYear = 2000;

  // Border styling
  static const double borderWidth = 0.5;

  // Export settings
  static const String csvDateFormat = 'dd MMM';
  static const String exportFileName = 'Stock_Snapshot';
  static const String exportText = 'Stock Snapshot Report';
}

/// Utility functions for the Reports module
class ReportsUtils {
  /// Get background color based on stock level
  static Color getStockColor(double stock, int limit) {
    if (stock <= 0) return MyColors.error.withAlpha(50);
    if (stock <= limit) return MyColors.warning.withAlpha(50);
    return MyColors.success.withAlpha(50);
  }

  /// Get text color based on stock level
  static Color getTextColor(double stock, int limit) {
    if (stock <= 0) return MyColors.error;
    if (stock <= limit) return MyColors.warning;
    return MyColors.success;
  }

  /// Export matrix data to CSV and save via File Picker
  static Future<void> exportToCSV(
    BuildContext context,
    List<StockSnapshotRow>? matrix,
    List<ProductStockValue>? stockValues,
  ) async {
    if (matrix == null || matrix.isEmpty) return;

    final stockValueMap = {
      for (var v in stockValues ?? []) v.productId: v
    };

    double grandTotal = 0;
    for (var row in matrix) {
      final val = stockValueMap[row.productId];
      grandTotal += val?.totalValue ?? 0;
    }

    final List<DateTime> days = matrix.first.dailyStock.map((e) => e.date).toList();
    final header = [
      'Product',
      ...days.map((d) => DateFormat(ReportsConstants.csvDateFormat).format(d)),
      'Current Stock',
      'Unit Value',
      'Total Value (${grandTotal.toStringAsFixed(2)})'
    ];

    String csvData = header.join(',') + '\n';

    for (var row in matrix) {
      final val = stockValueMap[row.productId];
      List<String> line = [
        row.productName,
        ...row.dailyStock.map((e) => e.stockAtEnd.toString()),
        row.currentStock.toString(),
        val?.basePrice.toStringAsFixed(2) ?? '0.00',
        val?.totalValue.toStringAsFixed(2) ?? '0.00',
      ];
      csvData += line.join(',') + '\n';
    }

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report',
        fileName: '${ReportsConstants.exportFileName}_${DateTime.now().millisecondsSinceEpoch}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile == null) return;

      final file = File(outputFile);
      await file.writeAsString(csvData);

      if (context.mounted) {
        UiHelper.showToast(context, 'Report exported successfully!', type: 1);
      }
    } catch (e) {
      if (context.mounted) {
        UiHelper.showToast(context, 'Export failed: $e', type: 3);
      }
    }
  }
}

