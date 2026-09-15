import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/person.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';

import '../Expense_Tracking/Expense_Report/expense_report_widgets.dart';

class LedgerSidePanel extends StatelessWidget {
  final Person? selectedPerson;
  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback? onBack;
  final TextEditingController payController;
  final TextEditingController receiveController;
  final VoidCallback onChoosePerson;
  final VoidCallback onSelectFromDate;
  final VoidCallback onSelectToDate;
  final Function(int) onDateScrollFrom;
  final Function(int) onDateScrollTo;
  final Function(double pay, double receive) onSavePayment;
  final VoidCallback onAutoFill;

  const LedgerSidePanel({
    super.key,
    required this.selectedPerson,
    required this.fromDate,
    required this.toDate,
    required this.payController,
    required this.receiveController,
    required this.onChoosePerson,
    required this.onSelectFromDate,
    required this.onSelectToDate,
    required this.onDateScrollFrom,
    required this.onDateScrollTo,
    required this.onSavePayment,
    required this.onAutoFill,
    this.onBack
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  onBack?.call();
                },
                hoverColor: MyColors.translucent.withAlpha(50),
                icon: const Icon(Icons.arrow_back, color: MyColors.translucent),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "Account Ledger     ",
                    style: MyFont.bold(18, color: MyColors.translucent),

                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          if (selectedPerson != null)
            ScaledContainer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color:  MyColors.mainBg,
                ),
                child: InkWell(
                  onTap: onChoosePerson,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: MyColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: selectedPerson!.image != null
                              ? ClipOval(
                                  child: Image.memory(
                                    selectedPerson!.image!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _getInitials(selectedPerson!.name),
                                    style: MyFont.bold(22, color: MyColors.sidebarSelected),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPerson!.name,
                                style: MyFont.bold(20, color: MyColors.darkBlue),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                selectedPerson!.phone ?? "No phone",
                                style: MyFont.normal(14, color: MyColors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            InkWell(
              onTap: onChoosePerson,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MyColors.mainBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: MyColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_outlined, color: MyColors.primary, size: 30),
                    const SizedBox(width: 15),
                    Text(
                      "Select a Person",
                      style: MyFont.medium(16, color: MyColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 25),
          if (selectedPerson != null) ...[
            Row(
              children: [
                Expanded(
                  child: DateButton(
                    label: 'From: ${DateFormat('dd MMM yyyy').format(fromDate)}',
                    onTap: onSelectFromDate,
                    onScroll: onDateScrollFrom,
                    color: MyColors.mainBg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DateButton(
                    label: 'To: ${DateFormat('dd MMM yyyy').format(toDate)}',
                    onTap: onSelectToDate,
                    onScroll: onDateScrollTo,
                    color: MyColors.mainBg,

                  ),

                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: MyColors.mainBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Receivable', style: MyFont.medium(14, color: MyColors.blue)),
                      Text(
                        "Rs. ${NumberFormat().format(selectedPerson!.incoming)}",
                        style: MyFont.bold(16, color: MyColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Payable', style: MyFont.medium(14, color: MyColors.blue)),
                      Text(
                        "Rs. ${NumberFormat().format(selectedPerson!.outgoing)}",
                        style: MyFont.bold(16, color: MyColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            if(selectedPerson!.incoming > 0 || selectedPerson!.outgoing > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              decoration: UiHelper.myDecoration(
              ),
              child: Column(
                children: [
                  Text("Make Payment", style: MyFont.bold(18, color: MyColors.darkBlue)),
                  const SizedBox(height: 15),
                  UiHelper.myTextField(
                    label: "Receive Amount",
                    controller: receiveController,
                    onChange: () {
                      final double receiveAmount = double.tryParse(receiveController.text) ?? 0.0;
                      if (receiveAmount > selectedPerson!.incoming) {
                        receiveController.text = selectedPerson!.incoming.toString();
                      }
                    },
                    textType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*')),
                    ],
                  ),
                  const SizedBox(height: 15),
                  UiHelper.myTextField(
                    label: "Pay Amount",
                    controller: payController,
                    onChange: () {
                      final double payAmount = double.tryParse(payController.text) ?? 0.0;
                      if (payAmount > selectedPerson!.outgoing) {
                        payController.text = selectedPerson!.outgoing.toString();
                      }
                    },
                    textType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*')),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      if (selectedPerson!.incoming > 0 && selectedPerson!.outgoing > 0) ...[
                        Expanded(
                          child: UiHelper.myButton(
                            title: "Auto Fill",
                            filled: false,
                            textSize: 16,
                            color: MyColors.primary,
                            callback: onAutoFill,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: UiHelper.myButton(
                          title: "Save Payment",
                          filled: true,
                          textSize: 16,
                          color: MyColors.primary,
                          callback: () {
                            final double payAmount = double.tryParse(payController.text) ?? 0.0;
                            final double receiveAmount = double.tryParse(receiveController.text) ?? 0.0;
                            if (payAmount > 0 || receiveAmount > 0) {
                              onSavePayment(payAmount, receiveAmount);
                            } else {
                              UiHelper.showToast(context, "Please enter an amount", type: 2);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
