import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/order_items.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/sections/widgets/order_detail_placeholder.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/sections/widgets/order_status_section.dart';

import '../../../../Database/orders.dart';
import '../../../../Shared_Widgets/date_time.dart';
import '../../../../Shared_Widgets/fonts.dart';
import '../../../../Shared_Widgets/main_ui_helper.dart';
import '../../../../colors.dart';
import 'widgets/order_payment_card.dart';


// First Render Causes Jank due to shader compilation,
// so we delay it by 500ms to allow smooth loading of other components.
// This is a temporary fix and should be optimized in the future.

class OrderDetailsCard extends StatefulWidget {
  final bool sell;
  final Order order;
  final VoidCallback onOrderChanged;
  final List<OrderItem> selectedProducts;
  const OrderDetailsCard({
    super.key,
    this.sell = true,
    required this.order,
    required this.onOrderChanged,
    required this.selectedProducts,
  });

  @override
  State<OrderDetailsCard> createState() => _OrderDetailsCard();
}

class _OrderDetailsCard extends State<OrderDetailsCard> {
  late String date;
  late String time;
  bool render = performanceMode;
  late TextEditingController refPageController;

  @override
  void initState() {
    super.initState();
    refPageController = TextEditingController(
      text: widget.order.refPage?.toString() ?? '',
    );
    initData();
  }

  @override
  void dispose() {
    refPageController.dispose();
    super.dispose();
  }

  initData() async {
    date =
        "${DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).day}-${DateFormat.MMM().format(DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp))}-${DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).year}";
    time = DateFormat(
      'hh:mm a',
    ).format(DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp));
    if (widget.order.editable) {
      widget.order.paymentTimestamp = widget.order.orderTimestamp;
    }

    if (!render && !widget.order.editable) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            render = true;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          render = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(125),
            spreadRadius: 0.5,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: render ? _buildContent() : const OrderDetailPlaceholder(),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _sectionTitle("Order Details"),
        SizedBox(
          width: double.infinity,
          child: OrderPaymentCard(
            key: ValueKey('order_payment_card_${widget.order.id}'),
            order: widget.order,
            onOrderChanged: widget.onOrderChanged,
          ),
        ),
        OrderStatusSection(
          key: ValueKey('order_status_section_${widget.order.id}'),
          order: widget.order,
          onChanged: widget.onOrderChanged,
          selectedProducts: widget.selectedProducts,
        ),

        SizedBox(width: double.infinity, child: _refPageCard()),
        SizedBox(width: double.infinity, child: dateTimeCard()),
      ],
    );
  }

  Widget _refPageCard() {
    // Sync controller if refPage changes externally (e.g. from new order suggestion)
    final refPageStr = widget.order.refPage?.toString() ?? '';
    if (refPageController.text != refPageStr) {
      refPageController.text = refPageStr;
    }

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
              "Page No (optional)",
              textAlign: TextAlign.start,
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
          ),
          SizedBox(height: 10,),
          SizedBox(
            height: 40,
            child: UiHelper.myTextField(
              controller: refPageController,
              hint: "Enter Page No",
              readOnly: !widget.order.editable,
              textType: TextInputType.number,
              fontSize: 15,
              borderRadius: 15,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onChange: () {
                widget.order.refPage = int.tryParse(refPageController.text);
                widget.onOrderChanged.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.start,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: MyColors.darkBlue,
        ),
      ),
    );
  }

  Widget dateTimeCard() {
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
              "Order Date & Time",
              textAlign: TextAlign.start,
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () async {
                    final newDateTime = await pickDate(
                      context,
                      DateTime.fromMillisecondsSinceEpoch(
                        widget.order.orderTimestamp,
                      ),
                    );
                    if (newDateTime != null) {
                      widget.order.orderTimestamp =
                          newDateTime.millisecondsSinceEpoch;
                      date =
                          "${DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).day}-${DateFormat.MMM().format(DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp))}-${DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).year}";

                      widget.onOrderChanged.call();
                    }
                  },
                  child: SizedBox(height: 40, child: dateTimeField(text: date)),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final newDateTime = await pickTime(
                      context,
                      DateTime.fromMillisecondsSinceEpoch(
                        widget.order.orderTimestamp,
                      ),
                    );
                    if (newDateTime != null) {
                      widget.order.orderTimestamp =
                          newDateTime.millisecondsSinceEpoch;
                      time = DateFormat('hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          widget.order.orderTimestamp,
                        ),
                      );

                      widget.onOrderChanged.call();
                    }
                  },
                  child: SizedBox(
                    height: 40,
                    child: dateTimeField(isTime: true, text: time),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
