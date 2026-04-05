import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
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
      UiHelper.pushPage(context: context, page:  NewOrderPage(
        sell: order.orderType == 'sell' ? true : false,
        order: order,
        callback: callBack,
      ));
    }

    return Hero(
      tag: "${order.id}",
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 180,
          width: 580,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
              border: UiHelper.myBorder(),
              boxShadow: UiHelper.myBoxShadow()
          ),
          child: Container(
            padding: EdgeInsets.only(left: 10,right: 10, top: 5),

            decoration: BoxDecoration(
              color:  Colors.white,

              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: .spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Order ID: ",
                                style: MyFont.semiBold(18, color: MyColors.black),
                              ),
                              Text(
                                "#${order.id}",
                                style: MyFont.semiBold(18, color: MyColors.black),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Date: ",
                                style: MyFont.semiBold(14, color: MyColors.grey),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(DateTime.fromMillisecondsSinceEpoch(order.orderTimestamp)),
                                style: MyFont.semiBold(14, color: MyColors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                order.orderType == 'sell'
                                    ? "Customer: "
                                    : "Supplier: ",
                                style: MyFont.semiBold(14, color: MyColors.grey),
                              ),
                              Expanded(
                                child: Text(
                                  order.name,
                                  style: MyFont.semiBold(14, color: MyColors.black),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                  ),
                  Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 40,
                            child: UiHelper.myButton(
                              callback: () async {
                                Order oldOrder = (await getOrderById(
                                  currentDB!,
                                  order.id ?? 0,
                                ))!;
                                oldOrder.editable = false;
                                oldOrder.totalAmount = oldOrder.totalAmount.abs();
                                viewOrder(oldOrder);
                              },
                              title: 'View Details',
                              color: MyColors.info,
                              filled: true,
                              textSize: 15,
                              borderRadius: 15,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Status: ',
                                style: MyFont.semiBold(16, color: MyColors.grey),
                              ),
                              Container(
                                decoration: BoxDecoration(

                                  color: order.orderStatus == 'Completed'
                                      ? MyColors.success.withAlpha(50)
                                      : order.orderStatus == 'Pending'
                                      ? MyColors.primary.withAlpha(50)
                                      : MyColors.error.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  order.orderStatus,
                                  style: MyFont.semiBold(
                                    16,
                                    color: order.orderStatus == 'Completed'
                                        ? MyColors.success
                                        : order.orderStatus == 'Pending'
                                        ? MyColors.primary
                                        : MyColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 0.5,
                  color: MyColors.lightGrey

                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Text(
                        "Total: Rs. ${NumberFormat.decimalPattern().format(payment)}",
                        style: MyFont.semiBold(20, color: MyColors.darkBlue),
                      ),
                      Expanded(child: SizedBox()),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Payment ',
                                style: MyFont.semiBold(16, color: MyColors.grey),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                    color: order.paymentStatus == 'Paid'
                                        ? MyColors.success.withAlpha(50)
                                        : (order.paymentStatus == 'Pending' ||
                                        order.dueDateTimestamp >
                                            DateTime.now().millisecondsSinceEpoch)
                                        ? MyColors.warning.withAlpha(50)
                                        : MyColors.error.withAlpha(50),
                                    borderRadius: BorderRadius.circular(10)
                                ),

                                child: Text(
                                  order.paymentStatus,
                                  style: MyFont.semiBold(
                                    16,
                                    color: order.paymentStatus == 'Paid'
                                        ? MyColors.success
                                        : (order.paymentStatus == 'Pending' ||
                                        order.dueDateTimestamp >
                                            DateTime.now().millisecondsSinceEpoch)
                                        ? MyColors.warning
                                        : MyColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (order.dueDateTimestamp != 0 && order.paymentStatus == 'Overdue')
                            Text(
                              "DueDate ${DateFormat('dd-MMM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(order.dueDateTimestamp))}",
                              style: MyFont.semiBold(
                                13,
                                color: DateTime.fromMillisecondsSinceEpoch(
                                  order.dueDateTimestamp,
                                ).isBefore(DateTime.now())
                                    ? MyColors.error
                                    : MyColors.warning,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
