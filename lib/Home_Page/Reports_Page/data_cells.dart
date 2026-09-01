
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Home_Page/Reports_Page/reports_utils.dart';
import 'package:inventry_management/Home_Page/Reports_Page/stock_movements.dart';
import 'package:sqflite/sqflite.dart';

import '../../Database/Reports_Data/stock_snapshot_logic.dart';
import '../../Shared_Widgets/app_cursor_overlay.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
import '../Products_Panel/update_product/update_product_stock.dart';

class VirtualizedDataCell extends StatelessWidget {
  final Database? db;
  final int productId;
  final String productName;
  final DateTime date;
  final DayStockInfo info;
  final int limit;
  final int originalLowStock;
  final VoidCallback onChange;

  const VirtualizedDataCell({super.key,
    required this.db,
    required this.productId,
    required this.productName,
    required this.date,
    required this.info,
    required this.limit,
    required this.originalLowStock,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ReportsUtils.getTextColor(info.stockAtEnd, limit, originalLowStock);
    String sp = "${info.sold.toStringAsFixed(0)}${info.purchased.toStringAsFixed(0)}";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: db == null
            ? null
            : () {
          getProductMovementsForDate(db!, productId: productId, date: date).then((value) {
            if (!context.mounted) return;
            UiHelper.pushPage(
              context: context,
              opaque: false,
              barrierDismissible: true,
              instantOpen: true,
              page: StockMovements(
                movements: value,
                productId: productId,
                productName: productName,
                date: date,
                onChange: onChange,
              ),
            );
          });
        },
        child: MouseRegion(
          cursor: db == null ? MouseCursor.defer : SystemMouseCursors.click,
          onEnter: (_) => isClickable = true,
          onExit: (_) => isClickable = false,
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
    );
  }
}

class VirtualizedCurrentStockCell extends StatelessWidget {
  final double stock;
  final int limit;
  final int originalLowStock;
  final int productId;
  final VoidCallback onChange;

  const VirtualizedCurrentStockCell({super.key,
    required this.stock,
    required this.limit,
    required this.originalLowStock,
    required this.productId,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ReportsUtils.getTextColor(stock, limit, originalLowStock);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => UiHelper.pushPage(
          context: context,
          opaque: false,
          barrierColor: Colors.black54,
          barrierDismissible: true,
          page: UpdateProductStock(
            id: productId,
            onSave: onChange,
          ),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => isClickable = true,
          onExit: (_) => isClickable = false,
          child: Center(
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
