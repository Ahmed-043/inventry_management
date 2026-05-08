import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/payment_transactions.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/new_transaction_button.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/transactions_cards.dart';
import 'package:inventry_management/Shared_Widgets/date_time.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/pagination_bar.dart';

import '../../Database/database.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';
import 'new_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  TextEditingController searchController = TextEditingController();
  List<PaymentTransaction> transactions = [];
  List<Map<String, dynamic>> persons = [];

  int status = 0; // ( 0: All, 1: Paid, 2: Pending, 3: Overdue)
  int type = 0; // ( 0: All, 1: Cash, 2: Digital, 3: Bank, 4: Other)
  int
  pageNo = 0,
  pageSize =
      transactionsPerPage ??
      0; // (pageNo >> current page, pageSize >> records per page, 0: no limit)
  int startDate = 0, endDate = 0, dueStart = 0, dueEnd = 0;

  bool isLoading = false, compress = false;
  Timer? _debounce;
  double padding = 10;
  int transactionCount = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadPersons();
    _loadTransactions();
  }

  _loadPersons() async {
    try {
      persons = await getPersonIdsAndNames(currentDB!);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _loadTransactions() async {
    setState(() {
      isLoading = true;
    });
    if (currentDB == null) {
      debugPrint("Null DataBase");
      isLoading = false;
      return;
    } else {
      try {
        transactions = await getTransactions(
          db: currentDB!,
          search: searchController.text,
          pageNo: pageNo,
          pageSize: pageSize,
          status: status,
          type: type,
          startDate: startDate,
          endDate: endDate,
          dueStart: dueStart,
          dueEnd: dueEnd,
        );
        updateTransactionNames();
        transactionCount = await getTransactionsCount(
          db: currentDB!,
          search: searchController.text,
          status: status,
          type: type,
          startDate: startDate,
          endDate: endDate,
          dueStart: dueStart,
          dueEnd: dueEnd,
        );
        print(transactionCount);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void updateTransactionNames() {
    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];

      final person = persons.firstWhere(
        (p) => p["id"] == t.personId,
        orElse: () => {},
      );

      if (person.isNotEmpty) {
        transactions[i].name = person["name"]; // 🔥 directly updates list item
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    compress = MediaQuery.of(context).size.width < 1000;
    padding = MediaQuery.of(context).size.width / 50;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 50,
          width: 420,
          child: Row(
            mainAxisAlignment: .start,
            children: [
              Text(
                "Transactions",
                style: MyFont.bold(30, color: MyColors.blue),
              ),
              const SizedBox(width: 15),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 5),
                child: AddNewTransaction.addNew(
                  context: context,
                  action: NewTransactionDialog(
                    onSave: () => _loadTransactions(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 10),
        searchBar(),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: padding,
                          right: padding,
                          top: 5,
                        ),
                        child: TransactionsCards(
                          transactions: transactions,
                          persons: persons,
                          onSave: () => _loadTransactions(),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Total Transactions: $transactionCount, Page: ${pageNo + 1}, Page Sze: $pageSize',
                            style: MyFont.semiBold(12, color: MyColors.grey)),
                          SizedBox(width: 30,),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PaginationBar(
                page: pageNo,
                pageSize: pageSize,
                itemCount: transactions.length,
                onNext: () {
                  pageNo++;
                  _loadTransactions();
                },
                onPrevious: () {
                  pageNo--;
                  _loadTransactions();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  int isHover = -1;

  Widget searchBar() {
    String formatEpoch(int ms) {
      if (ms == 0) return "Not set";
      return DateFormat(
        'dd-MMM-yyy',
      ).format(DateTime.fromMillisecondsSinceEpoch(ms));
    }

    final List<List<String>> filters = [
      ['All', 'Paid', 'Pending', 'Overdue'],
      ['All', 'Cash', 'Digital', 'Bank', 'Other'],
      ["Start: ${formatEpoch(startDate)}", "End: ${formatEpoch(endDate)}"],
    ];

    final List<String> buttonNames = [
      'Status: ',
      'Type: ',
      'Date: ',
      'Reset Filters',
    ];

    final double filterButtonWidth = compress ? 90 : 150;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 5),
      child: SizedBox(
        height: 35,
        child: Row(
          children: [
            // Search field
            Expanded(
              flex: 1,
              child: SizedBox(
                child: UiHelper.myTextField(
                  controller: searchController,
                  hint: 'Search transactions...',
                  onChange: () {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      if (!mounted) return;
                      _loadTransactions();
                      _debounce = null;
                    });
                  },
                  borderRadius: 10,
                  fontSize: 18,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Icon(Icons.search, color: MyColors.darkBlue),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                ),
              ),
            ),
            SizedBox(width: compress ? 6 : 10),
            // Filter buttons
            Expanded(
              flex: compress ? 1 : 2,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(buttonNames.length, (i) {
                    String title = i == 0
                        ? '${buttonNames[i]}${filters[0][status]}'
                        : i == 1
                        ? '${buttonNames[i]}${filters[1][type]}'
                        : buttonNames[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          splashColor: MyColors.blue.withAlpha(50),
                          onHover: (a) {
                            if (a && i < 3) {
                              isHover = i;
                            } else {
                              isHover = -1;
                            }
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(10),
                          onTapDown: (TapDownDetails details) async {
                            if (i == 3) {
                              // Reset button
                              status = type = startDate = endDate = dueStart =
                                  dueEnd = 0;
                              searchController.clear();
                              _loadTransactions();
                              return;
                            }

                            // Status / Type menu
                            final tapPosition = details.globalPosition;
                            List<String> options = filters[i];

                            showDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (_) => Stack(
                                children: [
                                  // Tap outside to close
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      behavior: HitTestBehavior.translucent,
                                    ),
                                  ),
                                  Positioned(
                                    left: tapPosition.dx - 10,
                                    top: tapPosition.dy + 5,
                                    child: Material(
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: i == 2 ? 170 : 150,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: options.length,
                                          itemBuilder: (context, idx) {
                                            final e = options[idx];
                                            return ListTile(
                                              title: Text(e),
                                              contentPadding: EdgeInsets.only(
                                                left: 10,
                                              ),
                                              onTap: () async {
                                                if (i == 0) {
                                                  status = idx;
                                                }
                                                if (i == 1) {
                                                  type = idx;
                                                }
                                                if (i == 2) {
                                                  final sel = e[0] == 'S' ? 0 : 1;
                                                  await date(i: sel);
                                                }
                                                _loadTransactions();
                                                Navigator.of(context).pop();
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: filterButtonWidth,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              // color: MyColors.grey.withAlpha(30),
                              border: Border.all(
                                width: 2,
                                color: MyColors.lightGrey,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: MyFont.semiBold(
                                      compress ? 12 : 15,
                                      color: MyColors.darkBlue,
                                    ),
                                  ),
                                ),
                                if (i == 2)
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 20,
                                    color: (startDate > 0 || endDate > 0)
                                        ? MyColors.success
                                        : MyColors.darkBlue,
                                  ),

                                if (isHover == i)
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: MyColors.darkBlue,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  date({int i = 1}) async {
    // i = 0 = start date, i = 1 = end date
    final initial = DateTime.fromMillisecondsSinceEpoch(
      i == 1
          ? (endDate == 0 ? DateTime.now().millisecondsSinceEpoch : endDate)
          : (startDate == 0
                ? DateTime.now().millisecondsSinceEpoch
                : startDate),
    );
    final first = i == 1
        ? (startDate == 0
              ? DateTime(1900)
              : DateTime.fromMillisecondsSinceEpoch(startDate))
        : DateTime(1900);
    final last = i == 0
        ? (endDate == 0
              ? DateTime(2100)
              : DateTime.fromMillisecondsSinceEpoch(endDate))
        : DateTime(2100);

    // Clamp initialDate to valid range
    final safeInitial = initial.isBefore(first)
        ? first
        : initial.isAfter(last)
        ? last
        : initial;

    DateTime? picked = await pickDate(
      context,
      safeInitial,
      firstDate: first,
      lastDate: last,
    );

    if (picked == null) return; // cancel protection

    if (i == 0) {
      // start day at 00:00:00
      picked = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
      startDate = picked.millisecondsSinceEpoch;
    } else {
      // end day at 23:59:59
      picked = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      endDate = picked.millisecondsSinceEpoch;
    }

    setState(() {});
  }
}
