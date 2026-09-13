import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/payment_transactions.dart';
import 'package:inventry_management/Database/person.dart';
import 'package:inventry_management/Home_Page/home_page.dart';
import 'package:inventry_management/Home_Page/Ledger_Panel/ledger_page.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

class PersonPaymentDialog extends StatefulWidget {
  final Person person;
  final double left;
  final double top;
  final HomePageState? homePage;
  final VoidCallback? onPaymentSaved;

  const PersonPaymentDialog({
    super.key,
    required this.person,
    required this.left,
    required this.top,
    this.homePage,
    this.onPaymentSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required Person person,
    required double left,
    required double top,
    VoidCallback? onPaymentSaved,
  }) {
    final homePage = HomePage.of(context);
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (_) => PersonPaymentDialog(
        person: person,
        left: left,
        top: top,
        homePage: homePage,
        onPaymentSaved: onPaymentSaved,
      ),
    );
  }

  @override
  State<PersonPaymentDialog> createState() => _PersonPaymentDialogState();
}

class _PersonPaymentDialogState extends State<PersonPaymentDialog> {
  final TextEditingController payController = TextEditingController();
  final TextEditingController receiveController = TextEditingController();

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  void dispose() {
    payController.dispose();
    receiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Stack(
        children: [
          Positioned(
            left: widget.left,
            top: widget.top,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(25),
              child: _buildPaymentOptions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Container(
      width: 570,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: MyColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: widget.person.image != null
                    ? ClipOval(
                        child: Image.memory(
                          widget.person.image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          _getInitials(widget.person.name),
                          style: MyFont.bold(18, color: MyColors.primary),
                        ),
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.person.name,
                      style: MyFont.bold(18, color: MyColors.darkBlue),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.person.phone ?? "No phone",
                      style: MyFont.normal(14, color: MyColors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pending Receivable: ',
                        style: MyFont.bold(14, color: MyColors.textSecondary),
                      ),
                      Text(
                        NumberFormat.simpleCurrency(name: 'Rs. ', decimalDigits: 0).format(widget.person.incoming),
                        style: MyFont.bold(16, color: MyColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pending Payable: ',
                        style: MyFont.bold(14, color: MyColors.textSecondary),
                      ),
                      Text(
                        NumberFormat.simpleCurrency(name: 'Rs. ', decimalDigits: 0).format(widget.person.outgoing),
                        style: MyFont.bold(16, color: MyColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: UiHelper.myButton(
                              title: "Order History",
                              filled: false,
                              textSize: 12,
                              color: MyColors.darkBlue,
                              callback: () {
                                Navigator.pop(context);
                                widget.homePage?.navigateTo(4, person: widget.person);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: UiHelper.myButton(
                              title: "Transaction History",
                              filled: false,
                              textSize: 12,
                              color: MyColors.darkBlue,
                              callback: () {
                                Navigator.pop(context);
                                widget.homePage?.navigateTo(5, person: widget.person);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: UiHelper.myButton(
                        title: "View Ledger",
                        filled: true,
                        textSize: 14,
                        color: MyColors.primary,
                        callback: () {
                          Navigator.pop(context);
                          UiHelper.pushPage(
                            context: context,
                            blurBackground: false,
                            page: LedgerPage(initialPerson: widget.person),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Container(
                width: 1,
                height: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: UiHelper.myTextField(
                              label: "Receive",
                              controller: receiveController,
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),

                              onChange: () {
                                final double receiveAmount = double.tryParse(receiveController.text) ?? 0.0;
                                if (receiveAmount > widget.person.incoming) {
                                  receiveController.text = widget.person.incoming.toString();
                                }
                              },
                              textType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*')),
                              ],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: UiHelper.myTextField(
                              label: "Pay",
                              controller: payController,
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              onChange: () {
                                final double payAmount = double.tryParse(payController.text) ?? 0.0;
                                if (payAmount > widget.person.outgoing) {
                                  payController.text = widget.person.outgoing.toString();
                                }
                              },
                              textType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*')),
                              ],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (widget.person.incoming > 0 && widget.person.outgoing > 0) ...[
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: UiHelper.myButton(
                                title: "Auto Fill",
                                filled: false,
                                textSize: 16,
                                color: MyColors.primary,
                                callback: () {
                                  payController.text = widget.person.outgoing.clamp(0, widget.person.incoming).toString();
                                  receiveController.text = payController.text;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: UiHelper.myButton(
                              title: "Save",
                              filled: true,
                              textSize: 16,
                              color: MyColors.primary,
                              callback: () async {
                                final double payAmount = double.tryParse(payController.text) ?? 0.0;
                                final double receiveAmount = double.tryParse(receiveController.text) ?? 0.0;

                                if (payAmount > 0 || receiveAmount > 0) {
                                  await distributePayments(
                                    currentDB!,
                                    personId: widget.person.id!,
                                    pay: payAmount,
                                    receive: receiveAmount,
                                  );

                                  if (mounted) {
                                    UiHelper.showToast(context, "Payment Saved Successfully", type: 1);
                                    payController.clear();
                                    receiveController.clear();
                                    widget.onPaymentSaved?.call();
                                    Navigator.pop(context);
                                  }
                                } else {
                                  if (mounted) {
                                    UiHelper.showToast(context, "Please enter an amount", type: 2);
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),



        ],
      ),
    );
  }
}
