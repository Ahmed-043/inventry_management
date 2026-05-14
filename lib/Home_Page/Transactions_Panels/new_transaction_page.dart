import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/payment_transactions.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/sliding_segment_control.dart';

import '../../Database/orders.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/date_time.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';
import '../Orders_panel/New_Order_Page/dialogs/choose_person.dart';

class NewTransactionDialog extends StatefulWidget {
  final VoidCallback onSave;
  final PaymentTransaction? transaction;
  final Person? person;
  const NewTransactionDialog({
    super.key,
    required this.onSave,
    this.transaction,
    this.person,
  });

  @override
  State<NewTransactionDialog> createState() => _NewTransactionDialogState();
}

class _NewTransactionDialogState extends State<NewTransactionDialog> {
  newTransaction transaction = newTransaction();
  Person? person;

  final TextEditingController amountCtrl = TextEditingController(text: "0.00");
  final TextEditingController remarksCtrl = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    final t = widget.transaction;
    if (t != null) {
      transaction.name = t.name;
      transaction.amount = t.amount.abs();
      transaction.paymentTimestamp = t.paymentTimestamp;
      transaction.paymentMethod = t.paymentMethod;
      transaction.paymentStatus = t.paymentStatus;
      transaction.timestamp = t.timestamp;
      transaction.dueDate = t.dueDate;
      transaction.paymentTimestamp = t.paymentTimestamp;
      transaction.orderId = t.orderId;
      transaction.type = t.amount >= 0 ? 'Incoming' : 'Outgoing';
      transaction.remark = t.remark;
      amountCtrl.text = transaction.amount.toString();
      remarksCtrl.text = t.remark.toString();
      person = widget.person;
      if (widget.person == null) {
        person = Person(name: t.name);
      }
      transaction.editable = false;
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    remarksCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      //width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _titleBar(),
          const SizedBox(height: 10),
          if (person == null)
            SizedBox(
                width:400,
                child: _personDetailCard()),
          if (person != null || !transaction.editable)
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      _personDetailCard(),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          _paymentCard(),
                          const SizedBox(height: 10),
                          _statusCard(),
                          const SizedBox(height: 10),
                          _remarkCard(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _bottomButtons(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _titleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: MyColors.grey.withAlpha(50)),
        ),
      ),
      child: Row(
        children: [
          Text("Transaction Details", style: MyFont.semiBold(18)),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  /* ---------------- Person Card ------------------- */
  Widget _personDetailCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: MyColors.lightGrey.withAlpha(70)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (!transaction.editable) {
                return;
              }
              final result = await showDialog<Person>(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    insetPadding: EdgeInsets.zero,
                    child: Container(
                      width: 400,
                      height: 600,
                      decoration: BoxDecoration(
                        color: MyColors.translucent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ChoosePerson(filter: 0, person: person),
                    ),
                  );
                },
              );
              if (result != null) {
                result.personType == 'customer' ? transaction.type = 'Incoming' : transaction.type = 'Outgoing';
                setState(() => person = result);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: .center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: MyColors.lightGrey.withAlpha(150),
                      ),
                      child: person?.image == null
                          ? Icon(
                              Icons.person,
                              size: 70,
                              color: MyColors.translucent,
                            )
                          : Image.memory(person!.image!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 20),
                  person == null
                      ? Text(
                          "Select Person",
                          style: MyFont.semiBold(16),
                          textAlign: TextAlign.center,
                        )
                      : Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              person?.name ?? '',
                              style: MyFont.semiBold(16),
                            ),
                            (person?.phone?.isEmpty ?? true)
                                ? SizedBox()
                                : Row(
                                    children: [
                                      Icon(
                                        Icons.phone_rounded,
                                        color: MyColors.info,
                                        size: 20,
                                      ),
                                      Text(
                                        person?.phone ?? '',
                                        style: MyFont.semiBold(16),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ---------------- Status Card ------------------- */
  Widget _statusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 5),
        width: double.infinity,
        decoration: BoxDecoration(color: MyColors.lightGrey.withAlpha(70)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Status",
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message:
                        (widget.transaction?.paymentStatus == 'Paid' &&
                            widget.transaction!.dueDate > 0)
                        ? DateFormat('dd-MMM-yyyy, hh:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              transaction.dueDate,
                            ),
                          )
                        : '',
                    child: SizedBox(
                      height: 40,
                      child: UiHelper.myButton(
                        title: "Overdue",
                        color: transaction.paymentStatus == 'Overdue'
                            ? MyColors.error
                            : MyColors.grey,
                        filled: transaction.paymentStatus == 'Overdue',
                        textSize: 15,
                        callback: () async {
                          if (!transaction.editable &&
                              widget.transaction?.paymentStatus == 'Paid') {
                            return;
                          }
                          final newDateTime = await pickDate(
                            context,
                            DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.fromMillisecondsSinceEpoch(
                              transaction.timestamp,
                            ),
                          );
                          if (newDateTime != null) {
                            transaction.dueDate =
                                newDateTime.millisecondsSinceEpoch;
                          }
                          setState(() {
                            transaction.paymentStatus = 'Overdue';
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: UiHelper.myButton(
                      title: "Pending",
                      color: transaction.paymentStatus == 'Pending'
                          ? MyColors.warning
                          : MyColors.grey,
                      filled: transaction.paymentStatus == 'Pending',
                      textSize: 15,
                      callback: () {
                        if (!transaction.editable &&
                            widget.transaction?.paymentStatus == 'Paid') {
                          return;
                        }
                        setState(() {
                          transaction.paymentStatus = 'Pending';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: UiHelper.myButton(
                      title: "Paid",
                      color: transaction.paymentStatus == 'Paid'
                          ? MyColors.info
                          : MyColors.grey,
                      filled: transaction.paymentStatus == 'Paid',
                      textSize: 15,
                      callback: () {
                        if (widget.transaction?.paymentStatus == 'Paid') {
                          return;
                        }
                        setState(() {
                          transaction.paymentTimestamp =
                              DateTime.now().millisecondsSinceEpoch;
                          transaction.paymentStatus = 'Paid';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (transaction.paymentStatus == "Overdue")
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      Text(
                        "Due Date",
                        textAlign: TextAlign.start,
                        style: MyFont.semiBold(15, color: MyColors.grey),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: InkWell(
                          onTap: () {
                            pickDateTime(
                              context,
                              DateTime.fromMillisecondsSinceEpoch(
                                transaction.dueDate,
                              ),
                              firstDate: DateTime.fromMillisecondsSinceEpoch(
                                transaction.timestamp,
                              ),
                            ).then((newDate) {
                              if (newDate != null) {
                                setState(() {
                                  transaction.dueDate =
                                      newDate.millisecondsSinceEpoch;
                                });
                              }
                            });
                          },
                          child: dateTimeField(
                            text: DateFormat('dd-MMM-yyyy, hh:mm a').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                transaction.dueDate,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (transaction.paymentStatus == "Paid")
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
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
                            if (!transaction.editable &&
                                widget.transaction?.paymentStatus == 'Paid') {
                              return;
                            }
                            pickDateTime(
                              context,
                              DateTime.fromMillisecondsSinceEpoch(
                                transaction.paymentTimestamp,
                              ),
                              firstDate: DateTime.fromMillisecondsSinceEpoch(
                                transaction.timestamp,
                              ),
                            ).then((newDate) {
                              if (newDate != null) {
                                setState(() {
                                  transaction.paymentTimestamp =
                                      newDate.millisecondsSinceEpoch;
                                });
                              }
                            });
                          },
                          child: dateTimeField(
                            text: DateFormat('dd-MMM-yyyy, hh:mm a').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                transaction.paymentTimestamp,
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
            Text(
              "Payment Method",
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: StatusSegmentedControl(
                selected: transaction.paymentMethod,
                options: [
                  TwoValue(first: "Cash", second: MyColors.success),
                  TwoValue(first: "Digital", second: MyColors.info),
                  TwoValue(first: "Bank", second: MyColors.blue),
                  TwoValue(first: "Other", second: MyColors.grey),
                ],
                onChanged: (e) {
                  if (!transaction.editable &&
                      widget.transaction?.paymentStatus == 'Paid') {
                    setState(() {});
                    return;
                  }
                  setState(() {
                    transaction.paymentMethod = e;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        width: double.infinity,
        decoration: BoxDecoration(color: MyColors.lightGrey.withAlpha(70)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Amount",
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    height: 40,
                    child: UiHelper.myTextField(
                      controller: amountCtrl,
                      prefixText: 'Rs. ',
                      hint: '0.00',
                      readOnly: !transaction.editable,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      onTap: (){
                        if(double.tryParse(amountCtrl.text) == 0){
                          setState(() {
                            amountCtrl.text = '';
                          });
                          }
                        },
                      onChange: () {
                        transaction.amount = double.tryParse(amountCtrl.text) ?? 0;
                      },
                      textType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 40,
                    child: UiHelper.myButton(
                      title: "Incoming",
                      color: transaction.type == 'Incoming'
                          ? MyColors.info
                          : MyColors.grey,
                      filled: transaction.type == 'Incoming',
                      textSize: 15,
                      callback: () {
                        if (!transaction.editable) {
                          return;
                        }
                        setState(() {
                          transaction.type = 'Incoming';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 40,
                    child: UiHelper.myButton(
                      title: "Outgoing",
                      color: transaction.type == 'Outgoing'
                          ? MyColors.warning
                          : MyColors.grey,
                      filled: transaction.type == 'Outgoing',
                      textSize: 15,
                      callback: () {
                        if (!transaction.editable) {
                          return;
                        }
                        setState(() {
                          transaction.type = 'Outgoing';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "Date & Time",
              style: MyFont.semiBold(15, color: MyColors.darkBlue),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () async {
                      if (!transaction.editable) {
                        return;
                      }
                      final newDateTime = await pickDate(
                        context,
                        DateTime.fromMillisecondsSinceEpoch(
                          transaction.timestamp,
                        ),
                      );
                      if (newDateTime != null) {
                        transaction.timestamp =
                            newDateTime.millisecondsSinceEpoch;
                      }
                      setState(() {});
                    },
                    child: SizedBox(
                      height: 40,
                      child: dateTimeField(
                        text:
                            "${DateTime.fromMillisecondsSinceEpoch(transaction.timestamp).day}-${DateFormat.MMMM().format(DateTime.fromMillisecondsSinceEpoch(transaction.timestamp))}-${DateTime.fromMillisecondsSinceEpoch(transaction.timestamp).year}",
                        borderRadius: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      if (!transaction.editable) {
                        return;
                      }
                      final newDateTime = await pickTime(
                        context,
                        DateTime.fromMillisecondsSinceEpoch(
                          transaction.timestamp,
                        ),
                      );
                      if (newDateTime != null) {
                        transaction.timestamp =
                            newDateTime.millisecondsSinceEpoch;
                      }
                      setState(() {});
                    },
                    child: SizedBox(
                      height: 40,
                      child: dateTimeField(
                        text: DateFormat('hh:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            transaction.timestamp,
                          ),
                        ),
                        borderRadius: 20,
                        isTime: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _remarkCard() {
    int lines = ((transaction.remark.length + 1) / 40).ceil();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        width: double.infinity,
        decoration: BoxDecoration(color: MyColors.lightGrey.withAlpha(70)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: UiHelper.myTextArea(
                controller: remarksCtrl,
                onChanged: () {
                  setState(() {
                    transaction.remark = remarksCtrl.text;
                  });
                },
                label: "Remarks",
                maxLines: lines,
                borderRadius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- BOTTOM BUTTONS ------------------- */
  Widget _bottomButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1, color: MyColors.grey.withAlpha(50)),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 45,
              child: UiHelper.myButton(
                title: "Close",
                color: MyColors.grey,
                textSize: 15,
                callback: () {
                  if(widget.transaction == null) {
                    setState(() {
                    person = null;
                  });
                  }
                  Navigator.pop(context);
                },
              ),
            ),
            if (person != null) const SizedBox(width: 10),
            if (person != null)
              SizedBox(
                width: 120,
                height: 45,
                child: UiHelper.myButton(
                  title: (transaction.editable) ? "Save" : "Update",
                  textSize: 15,
                  color: MyColors.primary,
                  filled: true,
                  callback: () async {
                    if (transaction.amount <= 0) {
                      UiHelper.showToast(context, "Invalid Payment Amount");
                      return;
                    } else if ((transaction.timestamp >
                                transaction.paymentTimestamp &&
                            transaction.paymentStatus == "Paid") ||
                        (!transaction.editable &&
                            transaction.timestamp > transaction.dueDate &&
                            transaction.paymentStatus == "Overdue")) {
                      UiHelper.showToast(
                        context,
                        "Payment cannot happen earlier than the transaction entry.",
                      );
                      return;
                    } else if (!transaction.editable) {
                      bool success = await updatePaymentIfNotPaid(
                        currentDB!,
                        id: widget.transaction!.id!,
                        paymentStatus: transaction.paymentStatus,
                        dueDate: transaction.dueDate,
                        paymentMethod: transaction.paymentMethod,
                        paymentTimestamp: transaction.paymentTimestamp,
                        remark: transaction.remark,
                      );
                      if (success) {
                        UiHelper.showToast(context, "Transaction Updated");
                        Navigator.pop(context);
                        widget.onSave();
                      } else {
                        UiHelper.showToast(
                          context,
                          "Cannot Update Paid Transaction!",
                        );
                      }
                      return;
                    } else {
                      final amount =
                          transaction.amount *
                          ((transaction.type == "Outgoing") ? -1 : 1);
                      String name = person?.name ?? '';
                      if (person?.id == 0) {
                        name = '$name\n${person?.phone}';
                      }
                      final PaymentTransaction newPayment = PaymentTransaction(
                        personId: person?.id ?? 0,
                        name: name,
                        orderId: 0,
                        amount: amount,
                        paymentStatus: transaction.paymentStatus,
                        dueDate: transaction.dueDate,
                        paymentMethod: transaction.paymentMethod,
                        timestamp: transaction.timestamp,
                        paymentTimestamp: transaction.paymentTimestamp,
                        remark: transaction.remark,
                      );
                      int id = await insertTransaction(currentDB!, newPayment);
                      if (id > 0) {
                        UiHelper.showToast(context, "Transaction Successful");
                      }
                      Navigator.pop(context);
                      widget.onSave();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
