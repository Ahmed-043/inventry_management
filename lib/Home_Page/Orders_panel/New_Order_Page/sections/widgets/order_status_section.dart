import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:inventry_management/Database/order_items.dart';
import '../../../../../Database/orders.dart';
import '../../../../../Shared_Widgets/date_time.dart';
import '../../../../../Shared_Widgets/fonts.dart';
import '../../../../../Shared_Widgets/sliding_segment_control.dart';
import '../../../../../colors.dart';

class OrderStatusSection extends StatefulWidget {
  final Order order;
  final VoidCallback onChanged;
  final List<OrderItem> selectedProducts;

  const OrderStatusSection({
    super.key,
    required this.order,
    required this.onChanged,
    required this.selectedProducts,
  });

  @override
  State<OrderStatusSection> createState() => _OrderStatusSectionState();
}

class _OrderStatusSectionState extends State<OrderStatusSection> {
  late DateTime dueDate;

  @override
  void initState() {
    super.initState();
    dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.dueDateTimestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MyColors.lightGrey.withAlpha(60),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              "Order Status",
              textAlign: TextAlign.start,
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: StatusSegmentedControl(
              selected: widget.order.orderStatus,
              key: const ValueKey('order_status'),
              options: const [
                TwoValue(first: "Canceled", second: MyColors.error),
                TwoValue(first: "Pending", second: MyColors.primary),
                TwoValue(first: "Completed", second: MyColors.success),
              ],
              onChanged: (String value) {
                if (!(widget.order.editable)) {
                  if (value == 'Canceled') {
                    widget.order.orderStatus = value;
                    widget.order.cancel = true;
                    widget.onChanged.call();
                    return;
                  } else {
                    if (widget.order.paymentStatus == 'Paid') {
                      widget.order.orderStatus = 'Completed';
                      widget.order.cancel = true;
                    } else {
                      widget.order.orderStatus = 'Pending';
                      widget.order.cancel = true;
                    }
                  }
                }
               // widget.order.orderStatus = value;
                widget.onChanged.call();
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Text(
              "Payment Status",
              textAlign: TextAlign.start,
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: StatusSegmentedControl(
              selected: widget.order.paymentStatus,
              key: const ValueKey('payment_status'),
              options: const [
                TwoValue(first: "Overdue", second: MyColors.error),
                TwoValue(first: "Pending", second: MyColors.primary),
                TwoValue(first: "Paid", second: MyColors.success),
              ],
              onChanged: (String value) {
                if (!(widget.order.editable)) {
                  if (widget.order.paymentStatus != 'Paid' || widget.order.update) {
                    widget.order.paymentStatus = value;
                    if (value == 'Paid') {
                      widget.order.orderStatus = 'Completed';
                      widget.order.paymentTimestamp = widget.order.orderTimestamp;
                    } else {
                      widget.order.orderStatus = 'Pending';
                      if (value == 'Overdue') {
                        dueDate =
                            DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp)
                                .add(const Duration(days: 7));
                        widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                        widget.onChanged.call();
                        pickDateTime(
                          context,
                          dueDate,
                          firstDate: DateTime.fromMillisecondsSinceEpoch(
                            widget.order.orderTimestamp,
                          ),
                        ).then((newDate) {
                          if (newDate != null && mounted) {
                            setState(() {
                              dueDate = newDate;
                              widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                            });
                          }
                        });
                      }
                    }
                    widget.order.update = true;
                    widget.onChanged.call();
                    return;
                  } else {
                    widget.onChanged.call();
                    return;
                  }
                } else {
                  widget.order.paymentStatus = value;
                  if (value == 'Overdue') {
                    dueDate =
                        DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp)
                            .add(const Duration(days: 7));

                    widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                    widget.onChanged.call();
                    pickDateTime(
                      context,
                      dueDate,
                      firstDate: DateTime.fromMillisecondsSinceEpoch(
                        widget.order.orderTimestamp,
                      ),
                    ).then((newDate) {
                      if (newDate != null && mounted) {
                        setState(() {
                          dueDate = newDate;
                          widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                        });
                      }
                    });
                  } else {
                    widget.order.dueDateTimestamp = 0;
                  }
                  if (value == 'Paid' && widget.selectedProducts.isNotEmpty) {
                    widget.order.orderStatus = 'Completed';
                  } else {
                    widget.order.orderStatus = 'Pending';
                  }
                  debugPrint("DueDate values NEW $dueDate");

                  widget.onChanged.call();
                }
              },
            ),
          ),
          const SizedBox(height: 5),
          if (widget.order.paymentStatus == "Paid")
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              child: SizedBox(
                height: 30,
                child: Row(
                  children: [
                    Text(
                      "Paid on",
                      textAlign: TextAlign.start,
                      style: MyFont.semiBold(15, color: MyColors.grey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (widget.order.editable || widget.order.update) {
                            pickDateTime(
                              context,
                              DateTime.fromMillisecondsSinceEpoch(
                                widget.order.paymentTimestamp,
                              ),
                              firstDate: DateTime.fromMillisecondsSinceEpoch(
                                widget.order.orderTimestamp,
                              ),
                            ).then((newDate) {
                              if (newDate != null) {
                                widget.order.paymentTimestamp = newDate.millisecondsSinceEpoch;
                                widget.onChanged.call();
                              }
                            });
                          }
                        },
                        child: dateTimeField(
                          text: DateFormat('dd-MMM-yyyy, hh:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              widget.order.paymentTimestamp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 5),
          if (widget.order.paymentStatus == 'Paid')
            SizedBox(
              width: double.infinity,
              child: Text(
                "Payment Method",
                textAlign: TextAlign.start,
                style: MyFont.semiBold(15, color: MyColors.darkBlue),
              ),
            ),
          if (widget.order.paymentStatus == 'Paid')
            SizedBox(
              width: double.infinity,
              child: StatusSegmentedControl(
                selected: widget.order.paymentMethod,
                key: const ValueKey('payment_method'),
                options: const [
                  TwoValue(first: "Cash", second: MyColors.success),
                  TwoValue(first: "Digital", second: MyColors.info),
                  TwoValue(first: "Bank", second: MyColors.blue),
                  TwoValue(first: "Other", second: MyColors.grey),
                ],
                onChanged: (String value) {
                  if (!(widget.order.editable)) {
                    if (widget.order.paymentStatus != 'Paid' || widget.order.update) {
                      widget.order.paymentMethod = value;
                      widget.order.update = true;
                      widget.onChanged.call();
                      return;
                    } else {
                      widget.onChanged.call();
                      return;
                    }
                  }
                  widget.order.paymentMethod = value;
                  widget.onChanged.call();
                },
              ),
            ),
          const SizedBox(height: 5),
          if (widget.order.paymentStatus == 'Overdue')
            SizedBox(
              width: 225,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      "Due Date & Time",
                      textAlign: TextAlign.start,
                      style: MyFont.semiBold(15, color: MyColors.darkBlue),
                    ),
                  ),
                  SizedBox(
                    child: InkWell(
                      onTap: () {
                        if (widget.order.paymentStatus == 'Overdue') {
                          if (widget.order.dueDateTimestamp < widget.order.orderTimestamp) {
                            widget.order.dueDateTimestamp = widget.order.orderTimestamp;
                            dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp)
                                .add(const Duration(days: 7));
                          }
                          pickDateTime(
                            context,
                            dueDate,
                            firstDate: DateTime.fromMillisecondsSinceEpoch(
                              widget.order.orderTimestamp,
                            ),
                          ).then((newDate) {
                            if (newDate != null && mounted) {
                              setState(() {
                                dueDate = newDate;
                                widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                              });
                              if (!widget.order.editable) {
                                widget.order.update = true;
                              }
                              widget.onChanged.call();
                            }
                          });
                        }
                      },
                      child: dateTimeField(
                        text: DateFormat(
                          'dd-MMM-yyyy, hh:mm a',
                        ).format(dueDate),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

