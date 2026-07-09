import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/payment_transactions.dart';
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

  @override
  void dispose() {
    payController.dispose();
    receiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: Container(
        decoration: UiHelper.myDecoration(),
        //color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          //onDoubleTap: widget.onDoubleTap,
          onSecondaryTap: widget.onSecondaryTap,
          onTapDown: (TapDownDetails details) async {
            final tapPosition = details.globalPosition;
            final screenSize = MediaQuery.of(context).size;
            const double dialogWidth = 350;
            const double dialogHeight = 180; // Estimated height of paymentOptions()

            double left = (tapPosition.dx - 100).clamp(10.0, screenSize.width - dialogWidth - 10.0);
            double top = tapPosition.dy;

            // If it would overflow the bottom, show it above the tap point instead
            if (top + dialogHeight > screenSize.height) {
              top = tapPosition.dy - dialogHeight+50;
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
              double width = (constraints.maxWidth / (3.5)).floorToDouble();
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: width * 0.1),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Tooltip(
                            waitDuration: const Duration(seconds: 1),
                            message: 'Address: ${widget.person.address}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: MyColors
                                    .palette[widget.num % MyColors.palette.length]
                                    .withAlpha(30),
                              ),
                              child: widget.person.image != null
                                  ? ClipOval(
                                      child: Image.memory(
                                        widget.person.image!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: width,
                                      color: MyColors
                                          .palette[widget.num % MyColors.palette.length]
                                          .withAlpha(150),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(left: width * 0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              widget.person.name,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                              style: MyFont.semiBold(
                                width * 0.20,
                                color: MyColors.darkBlue,
                              ),
                            ),
                          ),
                          if(widget.person.phone!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: width * 0.15,
                                color: MyColors.info,
                              ),
                              SizedBox(width: width * 0.05),
                              Expanded(
                                child: Text(
                                  widget.person.phone != null && widget.person.phone!.length > 4
                                      ? '${widget.person.phone!.substring(0, 4)}-${widget.person.phone!.substring(4)}'
                                      : widget.person.phone ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: MyFont.semiBold(
                                    width * 0.15,
                                    color: MyColors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if(widget.person.email!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: width * 0.15,
                                color: MyColors.info,
                              ),
                              SizedBox(width: width * 0.05),
                              Expanded(
                                child: Tooltip(
                                  waitDuration: const Duration(seconds: 1),
                                  message: widget.person.email.toString(),
                                  child: Text(
                                    widget.person.email.toString(),
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: MyFont.semiBold(
                                      width * 0.12,
                                      color: MyColors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: width * 0.05),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: .spaceEvenly,
                              children: [
                                Tooltip(
                                  waitDuration: const Duration(seconds: 1),
                                  message:'Receivable',
                                  child: Row(
                                    children: [
                                      Text(
                                        "Rs. ${NumberFormat.decimalPattern().format(widget.person.incoming)}",
                                        textAlign: TextAlign.center,
                                        style: MyFont.bold(
                                          width * 0.15,
                                          color: MyColors.success,
                                        ),
                                      ),
                                      Icon(Icons.keyboard_double_arrow_up_rounded,
                                        size: width * 0.15,
                                        color: MyColors.success ,
                                      ),
                                    ],
                                  ),
                                ),

                                Tooltip(
                                  waitDuration: const Duration(seconds: 1),
                                  message: 'Payable',
                                  child: Row(
                                    children: [
                                      Text(
                                        "Rs. ${NumberFormat.decimalPattern().format(widget.person.outgoing)}",
                                        textAlign: TextAlign.center,
                                        style: MyFont.bold(
                                          width * 0.15,
                                          color: MyColors.error,
                                        ),
                                      ),

                                      Icon(Icons.keyboard_double_arrow_down_rounded,
                                        size: width * 0.15,
                                        color: MyColors.error,
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                          Expanded(flex: 1, child: Container()),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
                    onChange: (){
                      final double receiveAmount = double.tryParse(receiveController.text) ?? 0.0;
                      if(receiveAmount > widget.person.incoming){
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
                    onChange: (){
                      final double payAmount = double.tryParse(payController.text) ?? 0.0;
                      if(payAmount > widget.person.outgoing){
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
              if(widget.person.incoming > 0 && widget.person.outgoing > 0)
                ...[
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
        ],
      ),
    );
  }
}
