import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Database/Reports_Data/inventory_movments.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';

class StockMovements extends StatefulWidget {
  final int productId;
  final String productName;
  final DateTime date;
  final VoidCallback onChange;
  final List<InventoryMovement> movements;

  const StockMovements({
    super.key,
    required this.productId,
    required this.productName,
    required this.date,
    required this.onChange,
    required this.movements,
  });

  @override
  State<StockMovements> createState() => _StockMovementsState();
}

class _StockMovementsState extends State<StockMovements> {
  late List<InventoryMovement> _movements;

  @override
  void initState() {
    super.initState();
    _movements = widget.movements;
  }

  // Future<void> _refreshMovements() async {
  //   if (currentDB == null) return;
  //   final updatedMovements = await getProductMovementsForDate(
  //     currentDB!,
  //     productId: widget.productId,
  //     date: widget.date,
  //   );
  //   if (mounted) {
  //     setState(() {
  //       _movements = updatedMovements;
  //     });
  //   }
  // }

  Widget _buildRemark(String remark) {
    final colonIndex = remark.indexOf(':');
    if (colonIndex == -1) {
      return Text(
        remark,
        style: MyFont.normal(13, color: MyColors.black),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: remark.substring(0, colonIndex + 1),
            style: MyFont.normal(13, color: MyColors.black),
          ),
          TextSpan(
            text: remark.substring(colonIndex + 1),
            style: MyFont.semiBold(13, color: MyColors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('dd MMM yyyy').format(widget.date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Center(
        child: AlertDialog(
          backgroundColor: MyColors.mainBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.productName,
                style: MyFont.semiBold(18, color: MyColors.darkBlue),
              ),
              Text(
                title,
                style: MyFont.semiBold(18, color: MyColors.darkBlue),
              ),
            ],
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 700,
              child: _movements.isEmpty
                  ? Text(
                      'No stock movements found for this day.',
                      style: MyFont.normal(14, color: MyColors.darkBlue),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),

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
                          ..._movements.map((movement) {
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
                                      Expanded(flex: 1, child: Text(changeText, style: MyFont.semiBold(15, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                                      Expanded(flex: 1, child: Text(movement.stockAfter.toString(), style: MyFont.normal(15, color: MyColors.darkBlue), textAlign: TextAlign.center)),
                                    ],
                                  ),
                                  if ((movement.remark ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    _buildRemark(movement.remark!),
                                  ],

                                ],
                              ),
                            );
                          }),

                        ],
                      ),
                    ),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
          actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          // actions: [
          //   SizedBox(
          //     width: 110,
          //     child: UiHelper.myButton(
          //       callback: () => Navigator.of(context).pop(),
          //       title: 'Close',
          //       textSize: 15,
          //       borderRadius: 10,
          //       elevation: 0,
          //     ),
          //   ),
          //   if (DateFormat('dd MMM yyyy').format(widget.date) == DateFormat('dd MMM yyyy').format(DateTime.now()))
          //     SizedBox(
          //       width: 110,
          //       child: UiHelper.myButton(
          //         callback: () {
          //           UiHelper.pushPage(
          //             context: context,
          //             opaque: false,
          //             barrierColor: Colors.black54,
          //             barrierDismissible: true,
          //             page: UpdateProductStock(
          //               id: widget.productId,
          //               onSave: () {
          //                 widget.onChange();
          //                 _refreshMovements();
          //               },
          //             ),
          //           );
          //         },
          //         filled: true,
          //         title: 'Update Stock',
          //         textSize: 15,
          //         borderRadius: 10,
          //         elevation: 0,
          //       ),
          //     ),
          // ],
        ),
      ),
    );
  }
}
