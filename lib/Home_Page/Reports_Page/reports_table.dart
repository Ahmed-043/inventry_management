import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Home_Page/Reports_Page/reports_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import '../../Database/Reports_Data/stock_snapshot_logic.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
import 'data_cells.dart';

/// Custom ScrollBehavior to enable mouse dragging and other devices
class ReportsScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// Builds the reports table widget using a virtualized 2D TableView.
class ReportsTable extends StatefulWidget {
  final List<StockSnapshotRow> matrix;
  final List<ProductStockValue> stockValues;
  final Database? db;
  final VoidCallback onChange;

  const ReportsTable({
    super.key,
    required this.matrix,
    required this.stockValues,
    this.db,
    required this.onChange,
  });

  @override
  State<ReportsTable> createState() => _ReportsTableState();
}

class _ReportsTableState extends State<ReportsTable> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalController.hasClients) {
        _horizontalController.animateTo(
          _horizontalController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matrix.isEmpty) return const Center(child: Text('No Data'));

    final List<DateTime> days = widget.matrix.first.dailyStock.map((e) => e.date).toList();
    final Map<int, ProductStockValue> stockValueMap = {
      for (var v in widget.stockValues) v.productId: v
    };
    final double grandTotalValue = widget.stockValues.fold(0, (sum, item) => sum + item.totalValue);

    final Set<int> categoryChangeIndices = {};
    for (int i = 1; i < widget.matrix.length; i++) {
      if (widget.matrix[i].category != widget.matrix[i - 1].category && sortCategory != 0) {
        categoryChangeIndices.add(i);
      }
    }

    final int columnCount = 3 + days.length + 1; // Product, Price, Total + Days + Current
    final int rowCount = widget.matrix.length + 1; // Header + Data

    return ScrollConfiguration(
      behavior: ReportsScrollBehavior(),
      child: Container(
        decoration: UiHelper.myDecoration(),
        margin: const EdgeInsets.only(bottom: 5),
        clipBehavior: Clip.antiAlias,
        child: TableView.builder(
          verticalDetails: ScrollableDetails.vertical(controller: _verticalController),
          horizontalDetails: ScrollableDetails.horizontal(controller: _horizontalController),
          diagonalDragBehavior: .weightedEvent,
          rowCount: rowCount,
          columnCount: columnCount,
          pinnedRowCount: 1,
          pinnedColumnCount: 3,
          columnBuilder: (index) {
            double width = ReportsConstants.dataColWidth;
            if (index == 0) width = ReportsConstants.productColWidth;
            if (index == 2) width = ReportsConstants.totalValueWidth;
            if (index >  2) width = ReportsConstants.dataColWidth + 20;
            return TableSpan(
              extent: FixedTableSpanExtent(width),
              foregroundDecoration: TableSpanDecoration(
                border: TableSpanBorder(
                  trailing: BorderSide(
                    color: MyColors.lightGrey,
                    width: ReportsConstants.borderWidth,
                  ),
                ),
              ),
            );
          },
          rowBuilder: (index) {
            if (index == 0) {
              return TableSpan(
                extent: const FixedTableSpanExtent(ReportsConstants.headerHeight),
                backgroundDecoration: TableSpanDecoration(
                  color: MyColors.blue.withAlpha(20),
                ),
                foregroundDecoration: const TableSpanDecoration(
                  border: TableSpanBorder(
                    trailing: BorderSide(
                      color: MyColors.lightGrey,
                      width: ReportsConstants.borderWidth,
                    ),
                  ),
                ),
              );
            }

            bool hasSeparator = categoryChangeIndices.contains(index - 1);
            double height = ReportsConstants.rowHeight + (hasSeparator ? 0.7 : 0);

            return TableSpan(
              extent: FixedTableSpanExtent(height),
              foregroundDecoration: TableSpanDecoration(
                border: TableSpanBorder(
                  trailing: BorderSide(
                    color: MyColors.lightGrey,
                    width: ReportsConstants.borderWidth,
                  ),
                  leading: hasSeparator
                      ? BorderSide(color: MyColors.info.withAlpha(150), width: 0.7)
                      : BorderSide.none,
                ),
              ),

            );
          },
          cellBuilder: (context, vicinity) {
            final int row = vicinity.row;
            final int col = vicinity.column;

            if (row == 0) {
              return TableViewCell(child: _buildHeaderCell(col, days, grandTotalValue));
            }

            final int matrixIndex = row - 1;
            final stockRow = widget.matrix[matrixIndex];
            final stockVal = stockValueMap[stockRow.productId];

            return TableViewCell(
              child: _buildDataCell(
                context,
                col,
                stockRow,
                stockVal,
                days,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(int col, List<DateTime> days, double grandTotalValue) {
    String text = '';
    if (col == 0) {
      text = 'Product';
    } else if (col == 1) {
      text = 'Unit Price';
    } else if (col == 2) {
      text = 'Total Value\n${NumberFormat.decimalPattern().format(grandTotalValue)}';
    } else if (col < 3 + days.length) {
      text = DateFormat('dd MMM yy').format(days[col - 3]);
    } else {
      text = 'Current';
    }

    return Tooltip(
      textStyle: MyFont.semiBold(16, color: MyColors.translucent) ,
      message: col == 2 ? NumberFormat.decimalPattern().format(grandTotalValue) : '',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        child: Text(
          text,
          style: MyFont.semiBold(col == 2 ? 14 : 14, color: MyColors.darkBlue),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDataCell(
    BuildContext context,
    int col,
    StockSnapshotRow row,
    ProductStockValue? stockVal,
    List<DateTime> days,
  ) {
    if (col == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.centerLeft,
        child: Text(
          row.productName,
          style: MyFont.semiBold(13, color: MyColors.darkBlue),
          maxLines: 3,
        ),
      );
    } else if (col == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        child: Text(
          NumberFormat.decimalPattern().format(stockVal?.basePrice ?? 0.0),
          style: MyFont.semiBold(14, color: MyColors.darkBlue),
        ),
      );
    } else if (col == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        child: Text(
          NumberFormat.decimalPattern().format(stockVal?.totalValue ?? 0.0),
          style: MyFont.semiBold(14, color: MyColors.darkBlue),
        ),
      );
    } else if (col < 3 + days.length) {
      final info = row.dailyStock[col - 3];
      return VirtualizedDataCell(
        db: widget.db,
        productId: row.productId,
        productName: row.productName,
        date: info.date,
        info: info,
        limit: row.lowStockLimit,
        originalLowStock: row.originalLowStock,
        onChange: widget.onChange,
      );
    } else {
      return VirtualizedCurrentStockCell(
        stock: row.currentStock,
        limit: row.lowStockLimit,
        originalLowStock: row.originalLowStock,
        productId: row.productId,
        onChange: widget.onChange,
      );
    }
  }
}
