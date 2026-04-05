import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Database/order_items.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import '../../../Database/orders.dart';
import '../../../Shared_Widgets/date_time.dart';
import '../../../Shared_Widgets/fonts.dart';
import '../../../Shared_Widgets/sliding_segment_control.dart';
import '../../../colors.dart';

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
  late DateTime dueDate;
  late String date;
  late String time;
  String dUnit = 'Rs';
  String tUnit = '%';
  final formatter = NumberFormat("#,##0.##", "en_US");

  TextEditingController taxController = TextEditingController();
  TextEditingController discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    super.initState();

    // --- Load stored tax & discount ---
    tUnit = widget.order.tax.first;
    dUnit = widget.order.discount.first;
    taxController.text = widget.order.tax.second.toString();
    discountController.text = widget.order.discount.second.toString();

    date =
        "${DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).day}-${DateFormat.MMM().format(DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp))}-${DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).year}";
    time = DateFormat(
      'hh:mm a',
    ).format(DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp));
    if(widget.order.editable){
      widget.order.paymentTimestamp = widget.order.orderTimestamp;
    }
    dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.dueDateTimestamp);

    // dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.dueTimestamp ?? widget.order.orderTimestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(125),
            spreadRadius: 0.5,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              "Order Details",
              textAlign: TextAlign.start,
              style: MyFont.semiBold(20, color: MyColors.darkBlue),
            ),
          ),
          // SizedBox(height: 20),
          SizedBox(width: double.infinity, child: paymentCard()),
          SizedBox(width: double.infinity, child: statusCard()),
          SizedBox(width: double.infinity, child: dateTimeCard()),
        ],
      ),
    );
  }

  Widget paymentCard() {
    final double total = widget.order.totalAmount;
    applyTaxAndDiscount(total);
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MyColors.lightGrey.withAlpha(60),
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Details",
            style: MyFont.semiBold(15, color: MyColors.darkBlue),
          ),
          const SizedBox(height: 10),
          Text(
            "Total: Rs. ${formatter.format(widget.order.totalAmount + widget.order.adjustment)}",
            style: MyFont.bold(20, color: MyColors.darkBlue),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: rowItem(
                  "Tax",
                  "00",
                  taxController,
                  tUnit,
                  () {
                    if(!(widget.order.editable)){
                      return;
                    }
                    applyTaxAndDiscount(total);
                    widget.onOrderChanged.call();
                  },
                  (val) {
                    if(!(widget.order.editable)){
                      return;
                    }
                    tUnit = val;
                    applyTaxAndDiscount(total);

                    widget.onOrderChanged.call();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: rowItem(
                  "Discount",
                  "0",
                  discountController,
                  dUnit,
                  () {
                    if(!(widget.order.editable)){
                      return;
                    }
                    widget.onOrderChanged.call();

                    applyTaxAndDiscount(total);
                  },
                  (val) {
                    if(!(widget.order.editable)){
                      return;
                    }
                    widget.onOrderChanged.call();

                    dUnit = val;
                    applyTaxAndDiscount(total);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget rowItem(
    String label,
    String value,
    TextEditingController controller,
    String unit,
    VoidCallback onChanged,
    ValueChanged<String> onUnitChanged,
  ) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 5),
      child: UiHelper.myTextField(
        label: label,
        hint: value,
        onChange: onChanged,
        textType: TextInputType.number,
        readOnly: !(widget.order.editable),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*')),
        ],
        padding: const EdgeInsets.only(left: 5),
        controller: controller,
        prefix: IconButton(
          onPressed: () {
            final newUnit = (unit == "Rs") ? "%" : "Rs";
            onUnitChanged(newUnit); // 🔥 update parent variable
          },
          icon: Text(
            unit,
            style: MyFont.bold(unit == '%' ? 20 : 15, color: MyColors.darkBlue),
          ),
        ),
      ),
    );
  }

  Widget dateTimeCard() {
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MyColors.lightGrey.withAlpha(60),
        borderRadius: BorderRadius.all(Radius.circular(15)),
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
              SizedBox(width: 5),
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

  Widget statusCard() {
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MyColors.lightGrey.withAlpha(60),
        borderRadius: BorderRadius.all(Radius.circular(15)),
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
              options: [
                TwoValue(first: "Canceled", second: MyColors.error),
                TwoValue(first: "Pending", second: MyColors.primary),
                TwoValue(first: "Completed", second: MyColors.success),
              ],
              onChanged: (String value) {
                if(!(widget.order.editable)){
                  if(value == 'Canceled'){
                    widget.order.orderStatus = value;
                    widget.order.cancel = true;
                    widget.onOrderChanged.call();
                    return;
                  }else{
                    if(widget.order.paymentStatus == 'Paid'){
                      widget.order.orderStatus = 'Completed';
                      widget.order.cancel = true;
                    }else{
                      widget.order.orderStatus = 'Pending';
                      widget.order.cancel = true;
                    }
                  }
                }
                // widget.order.orderStatus = value;
                widget.onOrderChanged.call();

              },
            ),
          ),
          SizedBox(height: 20),
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
              options: [
                TwoValue(first: "Overdue", second: MyColors.error),
                TwoValue(first: "Pending", second: MyColors.primary),
                TwoValue(first: "Paid", second: MyColors.success),
              ],
              onChanged: (String value) {
                if(!(widget.order.editable)){
                  if(widget.order.paymentStatus != 'Paid' || widget.order.update){
                    widget.order.paymentStatus = value;
                    if(value == 'Paid'){
                      widget.order.orderStatus = 'Completed';
                      widget.order.paymentTimestamp = widget.order.orderTimestamp;
                    }else{
                      widget.order.orderStatus = 'Pending';
                      if(value == 'Overdue'){
                        dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).add(const Duration(days: 7));
                        widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                        widget.onOrderChanged.call();
                        pickDateTime(context,
                          dueDate,
                          firstDate: DateTime.fromMillisecondsSinceEpoch(
                          widget.order.orderTimestamp,
                        ),
                        ).then((newDate) {
                          if (newDate != null) {
                            setState(() {
                              dueDate = newDate;
                              widget.order.dueDateTimestamp =
                                  dueDate.millisecondsSinceEpoch;
                            });
                          }
                        });
                      }
                    }
                    widget.order.update = true;
                    widget.onOrderChanged.call();
                    return;
                  }else{
                    setState(() {});
                    return;
                  }
                }
                else{
                  widget.order.paymentStatus = value;
                  if (value == 'Overdue') {
                    dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).add(const Duration(days: 7));

                    widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                    widget.onOrderChanged.call();
                    pickDateTime(context, dueDate,
                      firstDate: DateTime.fromMillisecondsSinceEpoch(
                        widget.order.orderTimestamp,
                      ),
                    ).then((newDate) {
                      if (newDate != null) {
                        setState(() {
                          dueDate = newDate;
                          widget.order.dueDateTimestamp =
                              dueDate.millisecondsSinceEpoch;
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

                  widget.onOrderChanged.call();
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
                                widget.onOrderChanged.call();
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
                options: [
                  TwoValue(first: "Cash", second: MyColors.success),
                  TwoValue(first: "Digital", second: MyColors.info),
                  TwoValue(first: "Bank", second: MyColors.blue),
                  TwoValue(first: "Other", second: MyColors.grey),

                ],
                onChanged: (String value) {
                  if(!(widget.order.editable)){
                    if(widget.order.paymentStatus != 'Paid' || widget.order.update){
                      widget.order.paymentMethod = value;
                      widget.order.update = true;
                      widget.onOrderChanged.call();
                      return;
                    }else{
                      widget.onOrderChanged.call();
                      return;
                    }
                  }
                  widget.order.paymentMethod = value;
                  widget.onOrderChanged.call();
                  widget.onOrderChanged.call();
                },
              ),
            ),

          const SizedBox(height: 5),

          if (widget.order.paymentStatus == 'Overdue')

            SizedBox(
              // height: 50,
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
                          if(widget.order.dueDateTimestamp < widget.order.orderTimestamp){
                            widget.order.dueDateTimestamp = widget.order.orderTimestamp;
                            dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).add(const Duration(days: 7));
                          }
                          pickDateTime(context, dueDate,
                            firstDate: DateTime.fromMillisecondsSinceEpoch(
                              widget.order.orderTimestamp,
                            ),
                          ).then((newDate) {
                            if (newDate != null) {
                                dueDate = newDate;
                                widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                                if(!widget.order.editable) widget.order.update = true;
                                widget.onOrderChanged.call();
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

  double applyTaxAndDiscount(double main) {
    if(!(widget.order.editable)){
      return main;
    }
    double tax = double.tryParse(taxController.text) ?? 0.0;
    double discount = double.tryParse(discountController.text) ?? 0.0;
    widget.order.tax.first = tUnit;
    widget.order.tax.second = tax;
    widget.order.discount.first = dUnit;
    widget.order.discount.second = discount;

    double result = main;

    // Apply tax
    if (tUnit == '%') {
      result += (main * tax / 100);
    } else if (tUnit == 'Rs') {
      result += tax;
    }

    // Apply discount
    if (dUnit == '%') {
      result -= (main * discount / 100);
    } else if (dUnit == 'Rs') {
      result -= discount;
    }
    widget.order.adjustment = result - widget.order.totalAmount ;

    return result;
  }
}
