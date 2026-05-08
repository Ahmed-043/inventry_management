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

// First Render Causes Jank due to shader compilation,
// so we delay it by 500ms to allow smooth loading of other components.
// This is a temporary fix and should be optimized in the future.
bool render = false;

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
    initData();
   }

   initData() async {
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

     if(!render && !widget.order.editable){
       Future.delayed(const Duration(milliseconds: 500), () {
         if (mounted) {
           setState(() {
             render = true;
           });
         }
       });
     }else{
       if (mounted) {
         setState(() {
           render = true;
         });
       }
     }
     // dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.dueTimestamp ?? widget.order.orderTimestamp);

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
      child: render ? Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: double.infinity,
            child: Text(
              "Order Details",
              textAlign: TextAlign.start,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: MyColors.darkBlue,
              ),
            ),
          ),
          // SizedBox(height: 20),
          SizedBox(width: double.infinity, child: paymentCard()),
          _OrderStatusSection(
            key: ValueKey('order_status_section_${widget.order.id}'),
            order: widget.order,
            onChanged: widget.onOrderChanged,
            selectedProducts: widget.selectedProducts,
          ),
          SizedBox(width: double.infinity, child: dateTimeCard()),
        ],
      )
      : const SizedBox(
        height: 466,
      ),
    );
  }

  Widget paymentCard() {
    final double total = widget.order.totalAmount;
    // Only call applyTaxAndDiscount if order is editable to avoid rebuilds
    if (widget.order.editable) {
      applyTaxAndDiscount(total);
    }
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MyColors.lightGrey.withAlpha(60),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
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



  double applyTaxAndDiscount(double main) {
    if(!(widget.order.editable)){
      return main;
    }
    double tax = double.tryParse(taxController.text) ?? 0.0;
    double discount = double.tryParse(discountController.text) ?? 0.0;
    // Create new TwoValue instances instead of mutating
    widget.order.tax = TwoValue(first: tUnit, second: tax);
    widget.order.discount = TwoValue(first: dUnit, second: discount);

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

// Separate widget to prevent excessive rebuilds of segmented controls
class _OrderStatusSection extends StatefulWidget {
  final Order order;
  final VoidCallback onChanged;
  final List<OrderItem> selectedProducts;

  const _OrderStatusSection({
    super.key,
    required this.order,
    required this.onChanged,
    required this.selectedProducts,
  });

  @override
  State<_OrderStatusSection> createState() => _OrderStatusSectionState();
}

class _OrderStatusSectionState extends State<_OrderStatusSection> {
  late DateTime dueDate;

  @override
  void initState() {
    super.initState();
    dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.dueDateTimestamp);
  }

  @override
  Widget build(BuildContext context) {
  //  return SizedBox();
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
                if(!(widget.order.editable)){
                  if(value == 'Canceled'){
                    widget.order.orderStatus = value;
                    widget.order.cancel = true;
                    widget.onChanged.call();
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
                widget.order.orderStatus = value;
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
                        widget.onChanged.call();
                        pickDateTime(context,
                          dueDate,
                          firstDate: DateTime.fromMillisecondsSinceEpoch(
                          widget.order.orderTimestamp,
                        ),
                        ).then((newDate) {
                          if (newDate != null && mounted) {
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
                    widget.onChanged.call();
                    return;
                  }else{
                    return;
                  }
                }
                else{
                  widget.order.paymentStatus = value;
                  if (value == 'Overdue') {
                    dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).add(const Duration(days: 7));

                    widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                    widget.onChanged.call();
                    pickDateTime(context, dueDate,
                      firstDate: DateTime.fromMillisecondsSinceEpoch(
                        widget.order.orderTimestamp,
                      ),
                    ).then((newDate) {
                      if (newDate != null && mounted) {
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
                  if(!(widget.order.editable)){
                    if(widget.order.paymentStatus != 'Paid' || widget.order.update){
                      widget.order.paymentMethod = value;
                      widget.order.update = true;
                      widget.onChanged.call();
                      return;
                    }else{
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
                          if(widget.order.dueDateTimestamp < widget.order.orderTimestamp){
                            widget.order.dueDateTimestamp = widget.order.orderTimestamp;
                            dueDate = DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp).add(const Duration(days: 7));
                          }
                          pickDateTime(context, dueDate,
                            firstDate: DateTime.fromMillisecondsSinceEpoch(
                              widget.order.orderTimestamp,
                            ),
                          ).then((newDate) {
                            if (newDate != null && mounted) {
                                setState(() {
                                  dueDate = newDate;
                                  widget.order.dueDateTimestamp = dueDate.millisecondsSinceEpoch;
                                });
                                if(!widget.order.editable) widget.order.update = true;
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

