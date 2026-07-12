import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import 'package:intl/intl.dart';

import '../../Shared_Widgets/main_ui_helper.dart';
import 'New_Order_Page/new_order_page.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback callBack;
  OrderCard({super.key, required this.order, required this.callBack});

  final formatter = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    if (order.totalAmount < 0) {
      order.totalAmount *= -1;
    }
    double payment =
        order.totalAmount +
        (order.tax.first == '%'
            ? order.totalAmount * order.tax.second / 100
            : order.tax.second) -
        (order.discount.first == '%'
            ? order.totalAmount * order.discount.second / 100
            : order.discount.second);
    viewOrder(Order order) {
      order.adjustment = payment-order.totalAmount;
      UiHelper.pushPage(
        context: context,
        page: NewOrderPage(
          sell: order.orderType == 'sell' ? true : false,
          order: order,
          callback: callBack,
        ),
      );
    }

    Color statusColor;
    String statusText = order.paymentStatus;

    switch (statusText) {
      case 'Paid':
        statusColor = MyColors.success;
        break;
      case 'Overdue':
        statusColor = MyColors.error;
        break;
      case 'Pending':
      default:
        statusColor = MyColors.warning;
        break;
    }
    double percent = payment > 0 ? (1 - (order.paidAmount.abs() / payment)) : 0.0;
    print(percent);
    return ScaledContainer(
      child: Hero(
        tag: "${order.id}",
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 140,
            width: 380,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: MyColors.primary.withOpacity(0.1),
                hoverColor: MyColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  Order? oldOrder = await getOrderById(currentDB!, order.id ?? 0);
                  if (oldOrder == null) return;
                  oldOrder.editable = false;
                  oldOrder.totalAmount = oldOrder.totalAmount.abs();
                  oldOrder.paidAmount = oldOrder.paidAmount.abs();
                  viewOrder(oldOrder);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${order.id}',
                            style: MyFont.medium(12, color: MyColors.textSecondary),
                          ),
                          InkWell(
                            onTap: () async {
                              Order? oldOrder = await getOrderById(currentDB!, order.id ?? 0);
                              if (oldOrder == null) return;
                              oldOrder.editable = false;
                              oldOrder.totalAmount = oldOrder.totalAmount.abs();
                              oldOrder.paidAmount = oldOrder.paidAmount.abs();
                              viewOrder(oldOrder);
                            },
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 14, color: MyColors.sidebarSelected),
                                const SizedBox(width: 4),
                                Text(
                                  "View",
                                  style: MyFont.bold(12, color: MyColors.sidebarSelected),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        order.name,
                        style: MyFont.bold(16, color: MyColors.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Text(
                        DateFormat('dd MMM yyyy - hh:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(order.orderTimestamp),
                        ),
                        style: MyFont.medium(12, color: MyColors.textSecondary),
                      ),
                      // Progress
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: 1 - percent,
                            backgroundColor: MyColors.lightestGrey,
                            color: statusColor.withAlpha(175),
                            minHeight: 3,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rs. ${NumberFormat.decimalPattern().format(payment)}',
                            style: MyFont.bold(18, color: MyColors.textMain),
                          ),
                          Row(
                            children: [
                              // if (order.paymentStatus != 'Paid')
                              //   _statusBadge(
                              //     order.paymentStatus,
                              //     order.paymentStatus == 'Overdue' ? const Color(0xFFFEEFEF) : const Color(0xFFFFF8ED),
                              //     order.paymentStatus == 'Overdue' ? const Color(0xFFEE5D50) : const Color(0xFFFFB547),
                              //   ),
                              // const SizedBox(width: 8),
                              _statusBadge(
                                order.orderStatus,
                                order.orderStatus == 'Completed' ? MyColors.success.withAlpha(30) : MyColors.warning.withAlpha(30),
                                order.orderStatus == 'Completed' ? MyColors.success : MyColors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: MyFont.bold(12, color: textColor),
      ),
    );
  }
}
