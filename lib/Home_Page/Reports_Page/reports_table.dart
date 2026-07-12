import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Home_Page/Reports_Page/reports_utils.dart';
import 'package:sqflite/sqflite.dart';
import '../../Database/Reports_Data/stock_snapshot_logic.dart';
import '../../Shared_Widgets/app_cursor_overlay.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
import '../Products_Panel/update_product/update_product_stock.dart';

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

/// Builds the reports table widget with synchronized scrolling and "grab to move" support
class ReportsTable extends StatefulWidget {
  final List<StockSnapshotRow> matrix;
  final List<ProductStockValue> stockValues;
  final ScrollController leftController;
  final ScrollController rightController;
  final Database? db;
  final VoidCallback onChange;

  const ReportsTable({
    super.key,
    required this.matrix,
    required this.stockValues,
    required this.leftController,
    required this.rightController,
    this.db,
    required this.onChange,
  });

  @override
  State<ReportsTable> createState() => _ReportsTableState();
}

class _ReportsTableState extends State<ReportsTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalController.hasClients) {
        //_horizontalController.jumpTo(_horizontalController.position.maxScrollExtent);

       // Or use animation:
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

    // Only Date columns + Current Stock column
    final double totalDataWidth =
        ReportsConstants.dataColWidth * (days.length + 1);

    final Set<int> categoryChangeIndices = {};
    for (int i = 1; i < widget.matrix.length; i++) {
      if (widget.matrix[i].category != widget.matrix[i - 1].category && sortCategory != 0) {
        categoryChangeIndices.add(i);
      }
    }


    return ScrollConfiguration(
      behavior: ReportsScrollBehavior(),
      child: Container(
        decoration: UiHelper.myDecoration(
        ),
        margin: const EdgeInsets.only(bottom: 10, right: 10),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FrozenProductColumn(
              matrix: widget.matrix,
              controller: widget.leftController,
              stockValueMap: stockValueMap,
              grandTotalValue: grandTotalValue,
              horizontalController: _horizontalController,
              categoryChangeIndices: categoryChangeIndices,
            ),
            _ScrollableDataArea(
              db: widget.db,
              matrix: widget.matrix,
              days: days,
              totalDataWidth: totalDataWidth,
              controller: widget.rightController,
              horizontalController: _horizontalController,
              onChange: widget.onChange,
              categoryChangeIndices: categoryChangeIndices,
            ),
          ],
        ),
      ),
    );
  }
}

/// Frozen left column displaying product names, unit price and total value
class _FrozenProductColumn extends StatelessWidget {
  final List<StockSnapshotRow> matrix;
  final ScrollController controller;
  final Map<int, ProductStockValue> stockValueMap;
  final double grandTotalValue;
  final ScrollController horizontalController;
  final Set<int> categoryChangeIndices;

  const _FrozenProductColumn({
    required this.matrix,
    required this.controller,
    required this.stockValueMap,
    required this.grandTotalValue,
    required this.horizontalController,
    required this.categoryChangeIndices,
  });

  @override
  Widget build(BuildContext context) {
    final double totalWidth = ReportsConstants.productColWidth +
        ReportsConstants.dataColWidth +
        ReportsConstants.totalValueWidth;
    return SizedBox(
      width: totalWidth,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (horizontalController.hasClients) {
            horizontalController.jumpTo(
              (horizontalController.offset - details.delta.dx).clamp(
                horizontalController.position.minScrollExtent,
                horizontalController.position.maxScrollExtent,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Header
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (controller.hasClients) {
                  controller.jumpTo(
                    (controller.offset - details.delta.dy).clamp(
                      controller.position.minScrollExtent,
                      controller.position.maxScrollExtent,
                    ),
                  );
                }
              },
              child: Container(
                height: ReportsConstants.headerHeight,
                decoration: BoxDecoration(
                  color: MyColors.blue.withAlpha(20),
                  border: Border(
                    right: BorderSide(
                      color: MyColors.lightGrey,
                      width: ReportsConstants.borderWidth,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: ReportsConstants.productColWidth,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: MyColors.lightGrey,
                            width: ReportsConstants.borderWidth,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Product',
                        style: MyFont.semiBold(16, color: MyColors.darkBlue),
                      ),
                    ),
                    ReportsCellBuilder.buildCell(
                      'Unit Price',
                      ReportsConstants.dataColWidth,
                      isHeader: true,
                    ),
                    Container(
                      width: ReportsConstants.totalValueWidth - 1,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: MyColors.lightGrey,
                            width: ReportsConstants.borderWidth,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Total Value\n${NumberFormat.decimalPattern().format(grandTotalValue)}',
                          style: MyFont.semiBold(14, color: MyColors.darkBlue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Body
            Expanded(
              child: ScrollConfiguration(
                behavior: ReportsScrollBehavior().copyWith(scrollbars: false),
                child: ListView.builder(
                  controller: controller,
                  itemCount: matrix.length,
                  itemBuilder: (context, index) {
                    final row = matrix[index];
                    bool change = categoryChangeIndices.contains(index);

                    final stockVal = stockValueMap[row.productId];
                    return Column(
                      children: [
                        if(change)
                          Container(
                            height: 0.7,
                            color: MyColors.info.withAlpha(150),
                          ),
                        Container(
                          height: ReportsConstants.rowHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: MyColors.lightGrey,
                                width: ReportsConstants.borderWidth,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: ReportsConstants.productColWidth,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: MyColors.lightGrey,
                                      width: ReportsConstants.borderWidth,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  row.productName,
                                  style: MyFont.semiBold(13, color: MyColors.darkBlue),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ReportsCellBuilder.buildCell(
                                NumberFormat.decimalPattern().format(stockVal?.basePrice ?? 0.0),
                                ReportsConstants.dataColWidth,
                                bold: true,
                              ),
                              ReportsCellBuilder.buildCell(
                                NumberFormat.decimalPattern().format(stockVal?.totalValue ?? 0.0),
                                ReportsConstants.totalValueWidth,
                                bold: true,
                              ),
                            ],
                          ),
                        ),

                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrollable data area
class _ScrollableDataArea extends StatelessWidget {
  final Database? db;
  final List<StockSnapshotRow> matrix;
  final List<DateTime> days;
  final double totalDataWidth;
  final ScrollController controller;
  final ScrollController horizontalController;
  final VoidCallback onChange;
  final Set<int> categoryChangeIndices;

  const _ScrollableDataArea({
    required this.db,
    required this.matrix,
    required this.days,
    required this.totalDataWidth,
    required this.controller,
    required this.horizontalController,
    required this.onChange,
    required this.categoryChangeIndices,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalDataWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DataHeader(days: days, verticalController: controller),
                _DataBody(
                  db: db,
                  matrix: matrix,
                  days: days,
                  controller: controller,
                  onChange: onChange,
                  categoryChangeIndices: categoryChangeIndices,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row for data columns
class _DataHeader extends StatelessWidget {
  final List<DateTime> days;
  final ScrollController verticalController;

  const _DataHeader({required this.days, required this.verticalController});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (verticalController.hasClients) {
          verticalController.jumpTo(
            (verticalController.offset - details.delta.dy).clamp(
              verticalController.position.minScrollExtent,
              verticalController.position.maxScrollExtent,
            ),
          );
        }
      },
      child: Container(
        height: ReportsConstants.headerHeight,
        color: MyColors.blue.withAlpha(20),
        child: Row(
          children: [
            ...days.map(
              (d) => ReportsCellBuilder.buildCell(
                DateFormat('dd MMM yy').format(d),
                ReportsConstants.dataColWidth,
                isHeader: true,
              ),
            ),
            ReportsCellBuilder.buildCell(
              'Current',
              ReportsConstants.dataColWidth,
              isHeader: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Body rows for data
class _DataBody extends StatelessWidget {
  final Database? db;
  final List<StockSnapshotRow> matrix;
  final List<DateTime> days;
  final ScrollController controller;
  final VoidCallback onChange;
  final Set<int> categoryChangeIndices;

  const _DataBody({
    required this.db,
    required this.matrix,
    required this.days,
    required this.controller,
    required this.onChange,
    required this.categoryChangeIndices,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: controller,
        itemCount: matrix.length,
        itemBuilder: (context, rowIndex) {
          final row = matrix[rowIndex];
          bool change = categoryChangeIndices.contains(rowIndex);
          return Column(
            children: [
              if(change)
                Container(
                  height: 0.7,
                  color: MyColors.info.withAlpha(150),
                ),
              Container(
                height: ReportsConstants.rowHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: MyColors.lightGrey,
                      width: ReportsConstants.borderWidth,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    ...row.dailyStock.map(
                      (info) => ReportsCellBuilder.buildDataCell(
                        context: context,
                        db: db,
                        productId: row.productId,
                        productName: row.productName,
                        date: info.date,
                        info: info,
                        width: ReportsConstants.dataColWidth,
                        limit: row.lowStockLimit,
                        originalLowStock: row.originalLowStock,
                        onChange: onChange,
                      ),
                    ),
                    ReportsCellBuilder.buildCurrentStockCell(
                      row.currentStock,
                      ReportsConstants.dataColWidth,
                      row.lowStockLimit,
                      row.originalLowStock,
                      row.productId,
                      context,
                      onChange,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Cell builders for the Reports table
class ReportsCellBuilder {
  /// Build a generic table cell with text
  static Widget buildCell(
    String text,
    double width, {
    bool isHeader = false,
    Alignment alignment = Alignment.center,
    double padding = 5,
    bool bold = false,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: padding),
      alignment: alignment,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: MyColors.lightGrey,
            width: ReportsConstants.borderWidth,
          ),
        ),
      ),
      child: Text(
        text,
        style: isHeader
            ? MyFont.semiBold(16, color: MyColors.darkBlue)
            : bold
                ? MyFont.semiBold(14, color: MyColors.darkBlue)
                : MyFont.normal(14, color: MyColors.darkBlue),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Build a data cell with stock information
  static Widget buildDataCell(
    {
    required BuildContext context,
    required Database? db,
    required int productId,
    required String productName,
    required DateTime date,
    required DayStockInfo info,
    required double width,
    required int limit,
    required int originalLowStock,
    required VoidCallback onChange,
  }
  ) {
    final textColor = ReportsUtils.getTextColor(info.stockAtEnd, limit, originalLowStock);
    String sp = "${info.sold.toStringAsFixed(0)}${info.purchased.toStringAsFixed(0)}";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: db == null
            ? null
            : () => _showDayMovementDialog(
                  context: context,
                  db: db,
                  productId: productId,
                  productName: productName,
                  date: date,
                  onChange: onChange,
                ),
        child: MouseRegion(
          cursor: db == null ? MouseCursor.defer : SystemMouseCursors.click,
          onEnter: (_){
            isClickable =true;
          },
          onExit: (_) {
            isClickable = false;
          },
        child: Container(
            width: width,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: MyColors.lightGrey,
                  width: ReportsConstants.borderWidth,
                ),
              ),
            ),
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                softWrap: true,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: info.stockAtEnd == 0 ? '__' : info.stockAtEnd.toStringAsFixed(0),
                      style: MyFont.bold(15, color: textColor),
                    ),
                    if (info.sold != 0 || info.purchased != 0)
                      TextSpan(
                        text: '\n',
                        style: MyFont.normal(12, color: MyColors.black),
                      ),
                    if (info.sold != 0)
                      TextSpan(
                        text: 'Sell: -${info.sold.toStringAsFixed(0)}',
                        style: MyFont.normal(12, color: MyColors.black),
                      ),
                    if (info.sold != 0 && info.purchased != 0)
                      TextSpan(
                        text: (sp.length > 8) ? '\n' : ' | ',
                        style: MyFont.normal(12, color: MyColors.black),
                      ),
                    if (info.purchased != 0)
                      TextSpan(
                        text: 'Buy: +${info.purchased.toStringAsFixed(0)}',
                        style: MyFont.normal(12, color: MyColors.black),
                      ),
                    if (info.adjustment != 0)
                      TextSpan(
                        text: '\nAdj: ${info.adjustment > 0 ? '+' : ''}${info.adjustment.toStringAsFixed(0)}',
                        style: MyFont.normal(14, color: MyColors.black),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showDayMovementDialog({
    required BuildContext context,
    required Database db,
    required int productId,
    required String productName,
    required DateTime date,
    required VoidCallback onChange,
  }) async {
    final movements = await getProductMovementsForDate(
      db,
      productId: productId,
      date: date,
    );

    if (!context.mounted) return;

    final title = '${DateFormat('dd MMM yyyy').format(date)} • $productName';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: MyColors.mainBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: MyFont.semiBold(18, color: MyColors.darkBlue),
          ),
          content: SizedBox(
            width: 700,
            child: movements.isEmpty
                ? Text(
                    'No stock movements found for this day.',
                    style: MyFont.normal(14, color: MyColors.darkBlue),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: MyColors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text('Time', style: MyFont.semiBold(13, color: MyColors.darkBlue))),
                              Expanded(flex: 2, child: Text('Type', style: MyFont.semiBold(13, color: MyColors.darkBlue))),
                              Expanded(flex: 1, child: Text('Before', style: MyFont.semiBold(13, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('Change', style: MyFont.semiBold(13, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('After', style: MyFont.semiBold(13, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...movements.map((movement) {
                          final time = DateFormat('hh:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(movement.timestamp),
                          );
                          final changeText = movement.quantityChange > 0
                              ? '+${movement.quantityChange}'
                              : movement.quantityChange.toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: movement.quantityChange == 0
                                  ? MyColors.translucent
                                  : movement.quantityChange > 0
                                  ? MyColors.success.withAlpha(50)
                                  : MyColors.error.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MyColors.lightGrey, width: 0.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(time, style: MyFont.normal(15, color: MyColors.darkBlue))),
                                    Expanded(flex: 2, child: Text(movement.movementType, style: MyFont.semiBold(15, color: MyColors.darkBlue))),
                                    Expanded(flex: 1, child: Text(movement.stockBefore.toString(), style: MyFont.normal(15, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                                    Expanded(flex: 1, child: Text(changeText, style: MyFont.semiBold(13, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                                    Expanded(flex: 1, child: Text(movement.stockAfter.toString(), style: MyFont.normal(15, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                                  ],
                                ),
                                if ((movement.remark ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${movement.remark}',
                                    style: MyFont.normal(13, color: MyColors.black),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
          actions: [
            SizedBox(
              width: 110,
              child: UiHelper.myButton(
                callback: () => Navigator.of(dialogContext).pop(),
                title: 'Close',
                textSize: 15,
                borderRadius: 10,
                elevation: 0,
              ),
            ),
            if(DateFormat('dd MMM yyyy').format(date) == DateFormat('dd MMM yyyy').format(DateTime.now()))
            SizedBox(
              width: 110,
              child: UiHelper.myButton(
                callback: (){
                  UiHelper.pushPage(
                    context: context,
                    opaque: false,
                    barrierColor: Colors.black54,
                    barrierDismissible: true,

                    page:  UpdateProductStock(
                      id: productId,
                      onSave: () {
                        Navigator.of(dialogContext).pop();
                        _showDayMovementDialog(
                          context: context,
                          db: db,
                          productId: productId,
                          productName: productName,
                          date: date,
                          onChange: onChange,
                        );
                        onChange();
                      },
                    ),
                  );
                },
                filled: true,
                title: 'Update Stock',
                textSize: 15,
                borderRadius: 10,
                elevation: 0,
              ),
            ),

          ],
        );
      },
    );
  }

  /// Build a current stock cell
  static Widget buildCurrentStockCell(
    double stock,
    double width,
    int limit,
    int originalLowStock,
    int productId,
    BuildContext context,
    VoidCallback onChange,
  ) {
    final textColor = ReportsUtils.getTextColor(stock, limit, originalLowStock);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>  UiHelper.pushPage(
          context: context,
          opaque: false,
          barrierColor: Colors.black54,
          barrierDismissible: true,

          page:  UpdateProductStock(
            id: productId,
            onSave: () {
              onChange();
            },
          ),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_){
            isClickable =true;
          },
          onExit: (_) {
            isClickable = false;
          },
          child: Container(
            width: width,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: MyColors.lightGrey,
                  width: ReportsConstants.borderWidth,
                ),
              ),
            ),
            child: Text(
              NumberFormat.decimalPattern().format(stock),
              style: MyFont.bold(16, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
