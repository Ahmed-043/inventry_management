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
      child: Column(
        children: [
          titleBar(),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
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
                          if (context.mounted) {
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
                          }
                        },
                      ),
                      if (i + 1 < widget.transactions.length)
                        Divider(height: 1, color: MyColors.textSecondary.withOpacity(0.2)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget titleBar() {
    List<String> titles = [
      'ORDER ID',
      'PERSON',
      'AMOUNT',
      'DATE & TIME',
      'PROGRESS',
      'STATUS',
      'TYPE',
      'ACTIONS',
    ];
    double textSize = 12;
    const List<int> flexValues = [1, 2, 1, 1, 1, 1, 1, 1];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MyColors.textSecondary.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: List.generate(titles.length, (i) {
          return Expanded(
            flex: flexValues[i],
            child: Text(
              titles[i],
              textAlign: i <= 1  ? TextAlign.start : (i == titles.length - 1 ? TextAlign.end : TextAlign.center),
              style: MyFont.bold(textSize, color: MyColors.textSecondary),
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
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    double textSize = 14;

    Color statusColor;
    String statusText = transaction.paymentStatus;

    switch (statusText) {
      case 'Paid':
        statusColor = MyColors.success;
        break;
      case 'Overdue':
        statusColor = MyColors.error;
        break;
      case 'Pending':
      default:
        statusColor = MyColors.warning;
        break;
    }

    Color paymentColor;
    String paymentText = transaction.paymentMethod;

    switch (paymentText) {
      case 'Cash':
        paymentColor = MyColors.success;
        break;
      case 'Digital':
        paymentColor = MyColors.info;
        break;
      case 'Bank':
        paymentColor = MyColors.blue;
        break;
      case 'Other':
        paymentColor = MyColors.grey;
        break;
      default:
        paymentColor = MyColors.textSecondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewDetails,
        hoverColor: MyColors.mainBg,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Order ID
              Expanded(
                flex: 1,
                child: Text(
                  transaction.orderId > 0 ? '#${transaction.orderId}' : '-',
                  style: MyFont.bold(textSize, color: MyColors.textSecondary),
                ),
              ),
              // Person
              Expanded(
                flex: 2,
                child: Text(
                  transaction.name.split('\n').first,
                  style: MyFont.bold(textSize, color: MyColors.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Amount
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Rs. ${NumberFormat.decimalPattern().format(transaction.amount.abs())}',
                    style: MyFont.bold(textSize, color: MyColors.textMain),
                  ),
                ),
              ),
              // Date
              Expanded(
                flex: 1,
                child: Text(
                  formattedDate,
                  textAlign: TextAlign.center,
                  style: MyFont.medium(textSize, color: MyColors.textSecondary),
                ),
              ),
              // Progress
              if(MediaQuery.of(context).size.width > 1000)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (transaction.amount != 0
                              ? (transaction.paidAmount.abs() / transaction.amount.abs())
                              : 0.0)
                          .clamp(0.0, 1.0),
                      backgroundColor: MyColors.lightestGrey,
                      color: statusColor.withAlpha(175),
                      minHeight: 3,
                    ),
                  ),
                ),
              ),
              // Status
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: MyFont.bold(12, color: statusColor),
                    ),
                  ),
                ),
              ),
              // Type
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.paymentMethod,
                      style: MyFont.bold(12, color: paymentColor),
                    ),
                  ),
                ),
              ),
              // Actions
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Hero(
                    tag: 'transaction${transaction.id}',
                    child: TextButton(
                      onPressed: onViewDetails,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: MyColors.sidebarSelected.withOpacity(0.5)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: MyColors.sidebarSelected),
                          const SizedBox(width: 4),
                          Text(
                            "Details",
                            style: MyFont.bold(12, color: MyColors.sidebarSelected),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
