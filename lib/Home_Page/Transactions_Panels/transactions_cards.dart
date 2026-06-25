import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/person.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../Database/database.dart';
import '../../Database/payment_transactions.dart';
import '../../colors.dart';
import 'new_transaction_page.dart';

class TransactionsCards extends StatefulWidget {
  final List<PaymentTransaction> transactions;
  final List<Map<String, dynamic>> persons;
  final VoidCallback onSave;
  const TransactionsCards({
    super.key,
    this.transactions = const [],
    this.persons = const [],
    required this.onSave,
  });

  @override
  State<TransactionsCards> createState() => _TransactionsCardsState();
}

class _TransactionsCardsState extends State<TransactionsCards> {
  bool compress = false;

  @override
  Widget build(BuildContext context) {
    compress = MediaQuery.of(context).size.width < 1000;

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: MyColors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          titleBar(),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: MyColors.translucent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: widget.transactions.length,
                  itemBuilder: (context, i) {
                    final t = widget.transactions[i];
                    return Column(
                      children: [
                        transactionCard(
                          transaction: t,
                          onViewDetails: () async {
                            final Person? person = await getPersonById(
                              currentDB!,
                              t.personId,
                            );
                            UiHelper.pushPage(
                              context: context,
                              opaque: false,
                              barrierColor: Colors.black54,
                              barrierDismissible: true,
                              page: _TransactionDialog(
                                action: NewTransactionDialog(
                                  transaction: t,
                                  person: person,
                                  onSave: widget.onSave,
                                ),
                                tag: 'transaction${t.id}',
                              ),
                            );
                          },
                        ),
                        if ((i + 1 < widget.transactions.length))
                          Divider(height: 1)
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget titleBar() {
    List<String> titles = [
      'Order ID',
      'Person',
      'Amount',
      'Date & Time',
      'Status',
      'Type',
      'Actions',
    ];
    double textSize = compress ? 15 : 20;
    const List<int> flexValues = [1, 2, 3, 3, 2, 2, 2];

    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(titles.length, (i) {
          if (MediaQuery.of(context).size.width < 700 && i == 3) {
            return SizedBox();
          }
          return Expanded(
            flex: flexValues[i],
            child: Text(
              titles[i],
              textAlign: TextAlign.center,
              style: MyFont.semiBold(textSize, color: MyColors.darkBlue),
            ),
          );
        }),
      ),
    );
  }

  Widget transactionCard({
    required PaymentTransaction transaction,
    required VoidCallback onViewDetails,
  }) {
    final date = DateTime.fromMillisecondsSinceEpoch(transaction.timestamp);
    final formattedDate = DateFormat('dd-MMM-yyyy, h:mm a').format(date);
    double textSize = compress ? 12 : 15;
    Color color = MyColors.black;
    return UiHelper.percentFillBar(
      percent: transaction.paymentStatus == 'Paid' ? 0 :1-(transaction.paidAmount / transaction.amount),
      height: 60,
      fillColor: MyColors.warning,
      child: SizedBox(
        height: 60,
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                transaction.orderId < 1 ? "N/A" : transaction.orderId.toString(),
                style: MyFont.semiBold(textSize, color: color),
                textAlign: TextAlign.center,
              ),
            ),
            //ORDER ID
            Expanded(
              flex: 2,
              child: Text(
                transaction.name.split('\n').first,
                style: MyFont.semiBold(textSize, color: color),
                textAlign: TextAlign.center,
              ),
            ),
            //Amount Rs
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  Text(
                    'Rs ${NumberFormat.decimalPattern().format(transaction.amount)}',
                    style: MyFont.semiBold(textSize, color: color),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  transaction.amount < 0
                      ? Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          size: 25,
                          color: MyColors.error,
                        )
                      : Icon(
                          Icons.keyboard_double_arrow_up_rounded,
                          size: 25,
                          color: MyColors.success,
                        ),
                ],
              ),
            ),
            //Date time
            if (MediaQuery.of(context).size.width > 700)
              Expanded(
                flex: 3,
                child: Text(
                  formattedDate,
                  style: MyFont.semiBold(textSize, color: color),
                  textAlign: TextAlign.center,
                ),
              ),
            // Payment Status
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      height: 30,
                      decoration: BoxDecoration(
                        color: transaction.paymentStatus == 'Paid'
                            ? MyColors.success.withAlpha(30)
                            : (transaction.paymentStatus == 'Pending' ||
                                  transaction.dueDate >
                                      DateTime.now().millisecondsSinceEpoch)
                            ? MyColors.warning.withAlpha(30)
                            : MyColors.error.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.paymentStatus,
                        textAlign: TextAlign.center,
                        style: MyFont.semiBold(
                          textSize,
                          color: transaction.paymentStatus == 'Paid'
                              ? MyColors.success
                              : (transaction.paymentStatus == 'Pending' ||
                                    transaction.dueDate >
                                        DateTime.now().millisecondsSinceEpoch)
                              ? MyColors.warning
                              : MyColors.error,
                        ),
                      ),
                    ),
                  ),
                  if (transaction.dueDate != 0 &&
                      transaction.paymentStatus == 'Overdue')
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        DateFormat('dd-MMM-yyyy').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            transaction.dueDate,
                          ),
                        ),
                        style: MyFont.semiBold(
                          10,
                          color:
                              DateTime.fromMillisecondsSinceEpoch(
                                transaction.dueDate,
                              ).isBefore(DateTime.now())
                              ? MyColors.error
                              : MyColors.warning,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Payment Method
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: transaction.paymentMethod == 'Cash'
                        ? MyColors.success.withAlpha(30)
                        : transaction.paymentMethod == 'Digital'
                        ? MyColors.info.withAlpha(30)
                        : transaction.paymentMethod == 'Bank'
                        ? MyColors.blue.withAlpha(30)
                        : MyColors.grey.withAlpha(50),
                  ),
                  child: Text(
                    transaction.paymentMethod,
                    style: MyFont.semiBold(
                      textSize,
                      color: transaction.paymentMethod == 'Cash'
                          ? MyColors.success
                          : transaction.paymentMethod == 'Digital'
                          ? MyColors.info
                          : transaction.paymentMethod == 'Bank'
                          ? MyColors.blue
                          : MyColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Action
            Expanded(
              flex: 2,
              child: Center(
                child: SizedBox(
                  width: compress ? 80 : 100,
                  height: compress ? 35 : 40,
                  child: Hero(
                    tag: 'transaction${transaction.id}',
                    child: UiHelper.myButton(
                      title: 'View Details',
                      textSize: textSize,
                      callback: onViewDetails,
                      filled: true,
                      color: MyColors.info,
                      borderRadius: 15,
                    ),
                  ),
                ),
              ),
            ),
            //SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}

class _TransactionDialog extends StatefulWidget {
  final Widget action;
  final String tag;
  const _TransactionDialog({Key? key, required this.action, this.tag = ''})
    : super(key: key);

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  bool showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          showContent = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // double height = MediaQuery.of(context).size.height > 850 ? 800.0 : MediaQuery.of(context).size.height-20;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Hero(
          tag: widget.tag,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
              // height: height ,
              constraints: BoxConstraints(maxHeight: 800),
              decoration: BoxDecoration(
                color: MyColors.translucent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: showContent
                  ? widget.action
                  : const SizedBox(width: 450, height: 800),
            ),
          ),
        ),
      ),
    );
  }
}
