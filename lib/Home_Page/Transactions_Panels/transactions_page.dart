import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/payment_transactions.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/dialogs/choose_person.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/new_transaction_button.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/transactions_cards.dart';
import 'package:inventry_management/Shared_Widgets/date_time.dart';
import 'package:inventry_management/Shared_Widgets/filter_button.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/pagination_bar.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';

import '../../Database/database.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/app_cursor_overlay.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';
import 'new_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
  final Person? initialPerson;
  const TransactionsPage({super.key, this.initialPerson});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  TextEditingController searchController = TextEditingController();
  List<PaymentTransaction> transactions = [];
  List<Map<String, dynamic>> persons = [];
  Person? selectedPerson;

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
    selectedPerson = widget.initialPerson;
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
          personId: selectedPerson?.id,
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
          personId: selectedPerson?.id,
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
    padding = 12.0;

    return Padding(
      padding: EdgeInsets.only(top:padding,right: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transactions",
                style: MyFont.bold(24, color: MyColors.textMain),
              ),
              Row(
                children: [
                  Hero(
                    tag: 'newTransaction',
                    child: UiHelper.myButton(
                      callback: () {
                        UiHelper.pushPage(
                          context: context,
                          opaque: false,
                          barrierColor: Colors.black54,
                          page: AddNewTransactionDialog(
                            action: NewTransactionDialog(
                              onSave: () => _loadTransactions(),
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                      title: "Add Transaction",
                      textSize: 14,
                      filled: true,
                      color: MyColors.sidebarSelected,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_none_rounded, color: MyColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          searchBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Expanded(
                      child: TransactionsCards(
                        transactions: transactions,
                        persons: persons,
                        onSave: () => _loadTransactions(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Page: ${pageNo+1} Transactions: $transactionCount  Total: Rs. ${NumberFormat.decimalPattern().format(transactions.fold(0.0, (sum, item) => sum + item.amount.abs()))}',
                          style: MyFont.bold(14, color: MyColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                )
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
      ),
    );
  }

  int isHover = -1;

  Future<void> _choosePerson() async {
    final person = await UiHelper.pushPage<Person?>(
      context: context,
      opaque: false,
      barrierDismissible: true,
      page: Center(
        child: Material(
          color: Colors.transparent,
          child: Hero(
            tag: "person_card",
            child: Container(
              width: 400,
              height: 600,
              decoration: UiHelper.myDecoration(),
              child: const ChoosePerson(
                filter: 0,
              ),
            ),
          ),
        ),
      ),
    );

    if (person != null) {
      setState(() {
        selectedPerson = person;
        _loadTransactions();
      });
    }
  }

  Widget searchBar() {
    String formatEpoch(int ms) {
      if (ms == 0) return "Not set";
      return DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));
    }

    final List<List<String>> filters = [
      ['All', 'Paid', 'Pending', 'Overdue'],
      ['All', 'Cash', 'Digital', 'Bank', 'Other'],
      ["Start: ${formatEpoch(startDate)}", "End: ${formatEpoch(endDate)}"],
    ];

    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: MouseRegion(

              onEnter: (_){
                isTextCursor = true;
              },
              onExit: (_){
                isTextCursor = false;
              },
              child: TextField(
                controller: searchController,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    if (!mounted) return;
                    _loadTransactions();
                  });
                },
                style: MyFont.medium(14, color: MyColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: MyFont.medium(14, color: MyColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: MyColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Person Selector Button
        if (selectedPerson != null)
          ScaledContainer(
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedPerson = null;
                  _loadTransactions();
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MyColors.sidebarSelected.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedPerson!.image != null)
                      ClipOval(
                        child: Image.memory(
                          selectedPerson!.image!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(Icons.person, size: 28, color: MyColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      selectedPerson!.name,
                      style: MyFont.medium(14, color: MyColors.textMain),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.close, size: 16, color: MyColors.textSecondary),
                  ],
                ),
              ),
            ),
          )
        else
          ScaledContainer(
            child: InkWell(
              onTap: _choosePerson,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 20, color: MyColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      "Select Person",
                      style: MyFont.medium(14, color: MyColors.textMain),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(width: 12),

        // Filters
        FilterButton(
          title: 'Status: ${filters[0][status]}',
          options: filters[0],
          onSelected: (idx) async {
            status = idx;
            _loadTransactions();
          },
        ),
        const SizedBox(width: 12),
        FilterButton(
          title: 'Type: ${filters[1][type]}',
          options: filters[1],
          onSelected: (idx) async {
            type = idx;
            _loadTransactions();
          },
        ),
        const SizedBox(width: 12),
        FilterButton(
          title: 'Date',
          options: filters[2],
          width: 180,
          onSelected: (idx) async {
            await date(i: idx);
            _loadTransactions();
          },
        ),
        const SizedBox(width: 12),
        ScaledContainer(
          scale: 1.2,
          child: TextButton(
            onPressed: () {
              setState(() {
                status = type = startDate = endDate = dueStart = dueEnd = 0;
                selectedPerson = null;
                searchController.clear();
                _loadTransactions();
              });
            },
            child: Text(
              "Reset Filters",
              style: MyFont.bold(14, color: MyColors.sidebarSelected),
            ),
          ),
        ),
      ],
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
