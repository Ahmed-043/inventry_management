import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../Database/orders.dart';
import '../../../../../Shared_Widgets/fonts.dart';
import '../../../../../Shared_Widgets/main_ui_helper.dart';
import '../../../../../colors.dart';

class OrderPaymentCard extends StatefulWidget {
  final Order order;
  final VoidCallback onOrderChanged;

  const OrderPaymentCard({
    super.key,
    required this.order,
    required this.onOrderChanged,
  });

  @override
  State<OrderPaymentCard> createState() => _OrderPaymentCardState();
}

class _OrderPaymentCardState extends State<OrderPaymentCard> {
  final formatter = NumberFormat("#,##0.##", "en_US");
  String dUnit = 'Rs';
  String tUnit = '%';

  final TextEditingController taxController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tUnit = widget.order.tax.first;
    dUnit = widget.order.discount.first;
    taxController.text = widget.order.tax.second.toString();
    discountController.text = widget.order.discount.second.toString();
  }

  @override
  Widget build(BuildContext context) {
    final double total = widget.order.totalAmount;
    if (widget.order.editable) {
      _applyTaxAndDiscount(total);
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
                child: _rowItem(
                  label: "Tax",
                  hint: "00",
                  controller: taxController,
                  unit: tUnit,
                  onChanged: () {
                    if (!widget.order.editable) {
                      return;
                    }
                    _applyTaxAndDiscount(total);
                    widget.onOrderChanged.call();
                  },
                  onUnitChanged: (val) {
                    if (!widget.order.editable) {
                      return;
                    }
                    setState(() {
                      tUnit = val;
                    });
                    _applyTaxAndDiscount(total);
                    widget.onOrderChanged.call();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _rowItem(
                  label: "Discount",
                  hint: "0",
                  controller: discountController,
                  unit: dUnit,
                  onChanged: () {
                    if (!widget.order.editable) {
                      return;
                    }
                    _applyTaxAndDiscount(total);
                    widget.onOrderChanged.call();
                  },
                  onUnitChanged: (val) {
                    if (!widget.order.editable) {
                      return;
                    }
                    setState(() {
                      dUnit = val;
                    });
                    _applyTaxAndDiscount(total);
                    widget.onOrderChanged.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowItem({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String unit,
    required VoidCallback onChanged,
    required ValueChanged<String> onUnitChanged,
  }) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 5),
      child: UiHelper.myTextField(
        label: label,
        hint: hint,
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
            onUnitChanged(newUnit);
          },
          icon: Text(
            unit,
            style: MyFont.bold(unit == '%' ? 20 : 15, color: MyColors.darkBlue),
          ),
        ),
      ),
    );
  }

  double _applyTaxAndDiscount(double main) {
    if (!widget.order.editable) {
      return main;
    }
    final double tax = double.tryParse(taxController.text) ?? 0.0;
    final double discount = double.tryParse(discountController.text) ?? 0.0;
    widget.order.tax = TwoValue(first: tUnit, second: tax);
    widget.order.discount = TwoValue(first: dUnit, second: discount);

    double result = main;
    if (tUnit == '%') {
      result += (main * tax / 100);
    } else if (tUnit == 'Rs') {
      result += tax;
    }

    if (dUnit == '%') {
      result -= (main * discount / 100);
    } else if (dUnit == 'Rs') {
      result -= discount;
    }

    widget.order.adjustment = result - widget.order.totalAmount;
    return result;
  }
}

