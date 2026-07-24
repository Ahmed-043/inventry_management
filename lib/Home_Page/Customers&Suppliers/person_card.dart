import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/payment_transactions.dart';
import 'package:inventry_management/Home_Page/home_page.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';

import '../../Database/person.dart';
import '../../Shared_Widgets/fonts.dart';

class PersonCard extends StatefulWidget {
  final Person person;
  final int num;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onPaymentSaved;
  final Color? splashColor;
  final Color? hoverColor;

  const PersonCard({
    super.key,
    required this.person,
    this.num = 0,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.onPaymentSaved,
    this.splashColor,
    this.hoverColor,
  });

  @override
  State<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<PersonCard> {
  final TextEditingController payController = TextEditingController();
  final TextEditingController receiveController = TextEditingController();
  bool _isHovered = false;

  @override
  void dispose() {
    payController.dispose();
    receiveController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      double val = amount / 1000000;
      return 'Rs. ${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      double val = amount / 1000;
      return 'Rs. ${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}K';
    }
    return 'Rs. ${NumberFormat.decimalPattern().format(amount.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = MyColors.palette[widget.num % MyColors.palette.length];
    
    // Determine Outstanding amount based on person type
    // final double outstanding = widget.person.personType == 'customer'
    //     ? widget.person.incoming
    //     : widget.person.outgoing;

    return ScaledContainer(
      child: Container(
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
            onTap: widget.onTap,
            onSecondaryTap: widget.onSecondaryTap,
            onTapDown: (TapDownDetails details) async {
                final tapPosition = details.globalPosition;
                final screenSize = MediaQuery.of(context).size;
                const double dialogWidth = 350;
                const double dialogHeight = 180;
      
                double left = (tapPosition.dx - 100).clamp(10.0, screenSize.width - dialogWidth - 10.0);
                double top = tapPosition.dy;
      
                if (top + dialogHeight > screenSize.height) {
                  top = tapPosition.dy - dialogHeight + 50;
                }
                top = top.clamp(10.0, screenSize.height - dialogHeight - 10.0);
      
                await showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (_) => Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: top,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(25),
                          child: paymentOptions(),
                        ),
                      ),
                    ],
                  ),
                );
                payController.clear();
                receiveController.clear();
              },
              splashColor: widget.splashColor ?? MyColors.primary.withOpacity(0.1),
              hoverColor: widget.hoverColor ?? MyColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final factor = (h / 167.0).clamp(0.6, 2.0);
      
                  return Padding(
                    padding: EdgeInsets.all(15.0 * factor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Avatar, Name, Phone
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50 * factor,
                              height: 50 * factor,
                              decoration: BoxDecoration(
                                color: avatarColor.withOpacity(0.1),
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
                                        style: MyFont.bold(18 * factor, color: avatarColor),
                                      ),
                                    ),
                            ),
                            SizedBox(width: 12 * factor),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.person.name,
                                    style: MyFont.bold(16 * factor, color: MyColors.darkBlue),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.person.phone != null && widget.person.phone!.isNotEmpty)
                                    Text(
                                      widget.person.phone!,
                                      style: MyFont.normal(13 * factor, color: MyColors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8 * factor),
                        // Email
                        if (widget.person.email != null && widget.person.email!.isNotEmpty)
                          Text(
                            widget.person.email!,
                            style: MyFont.normal(13 * factor, color: MyColors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const Spacer(),
                        // Bottom Info: Total Purchase & Outstanding
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PENDING RECEIVABLE',
                                    style: MyFont.bold(10 * factor, color: MyColors.textSecondary),
                                  ),
                                  SizedBox(height: 4 * factor),
                                  Text(
                                    NumberFormat.simpleCurrency(name: 'Rs. ', decimalDigits: 0).format(widget.person.incoming),
                                    style: MyFont.bold(15 * factor,
                                        color: MyColors.success),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PENDING PAYMENT',
                                    style: MyFont.bold(10 * factor, color: MyColors.textSecondary),
                                  ),
                                  SizedBox(height: 4 * factor),
                                  Text(
                                    NumberFormat.simpleCurrency(name: 'Rs. ', decimalDigits: 0).format(widget.person.outgoing),
                                    style: MyFont.bold(15 * factor,
                                      color:  MyColors.error),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
    );
  }

  Widget paymentOptions() {
    return Container(
      width: 350,
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
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: UiHelper.myTextField(
                    label: "Receive",
                    controller: receiveController,
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
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: UiHelper.myTextField(
                    label: "Pay",
                    controller: payController,
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
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              if (widget.person.incoming > 0 && widget.person.outgoing > 0) ...[
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
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
                  width: double.infinity,
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
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: UiHelper.myButton(
                    title: "Order History",
                    filled: false,
                    textSize: 14,
                    color: MyColors.darkBlue,
                    callback: () {
                      Navigator.pop(context);
                      HomePage.of(context)?.navigateTo(4, person: widget.person);
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
                    textSize: 14,
                    color: MyColors.darkBlue,
                    callback: () {
                      Navigator.pop(context);
                      HomePage.of(context)?.navigateTo(5, person: widget.person);
                    },
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
