import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense_category.dart';
import 'package:inventry_management/Home_Page/Expense_Tracking/add_expense_dialog.dart';
import 'package:inventry_management/Home_Page/Expense_Tracking/Expense_Report/expense_report.dart';
import 'package:inventry_management/Home_Page/Expense_Tracking/expense_cards.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/dialogs/choose_person.dart';
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

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  TextEditingController searchController = TextEditingController();
  List<Expense> expenses = [];
  List<ExpenseCategory> categories = [];
  Person? selectedPerson;

  int selectedCategoryId = 0;
  String selectedPaymentMethod = 'All';
  int selectedType = 0; // 0: All, 1: Incoming (+), 2: Outgoing (-)
  int pageNo = 0, pageSize = transactionsPerPage ?? 20;
  int startDate = 0, endDate = 0;
  int expenseCount = 0;

  bool isLoading = false, compress = false;
  Timer? _debounce;
  double padding = 10, spacing = 12;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    setState(() => isLoading = true);
    if (currentDB != null) {
      categories = await ExpenseCategory.getAll(currentDB!);
      final defaults = [
        'Beverage',
        'Transport',
        'Software',
        'Groceries',
        'Food',
        'Rent',
        'Salary',
        'Bills'
      ];

      bool added = false;
      for (var name in defaults) {
        if (!categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
          await ExpenseCategory.insert(currentDB!, ExpenseCategory(name: name));
          added = true;
        }
      }

      if (added) {
        categories = await ExpenseCategory.getAll(currentDB!);
      }
      await _fetchExpenses();
    }
    setState(() => isLoading = false);
  }

  _fetchExpenses() async {
    final newExpenses = await Expense.getExpenses(
      db: currentDB!,
      search: searchController.text,
      categoryId: selectedCategoryId,
      paymentMethod: selectedPaymentMethod,
      type: selectedType,
      startDate: startDate,
      endDate: endDate,
      personId: selectedPerson?.id,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    final newCount = await Expense.getExpensesCount(
      db: currentDB!,
      search: searchController.text,
      categoryId: selectedCategoryId,
      paymentMethod: selectedPaymentMethod,
      type: selectedType,
      startDate: startDate,
      endDate: endDate,
      personId: selectedPerson?.id,
    );

    if (!mounted) return;
    setState(() {
      expenses = newExpenses;
      expenseCount = newCount;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    compress = MediaQuery.of(context).size.width < 1100;
    padding = 12.0;
    spacing = compress ? 6 : 12;

    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Expenses",
                style: MyFont.bold(24, color: MyColors.textMain),
              ),
              Row(
                children: [
                  Hero(
                    tag: 'addExpense',
                    child: UiHelper.myButton(
                      callback: () {
                        UiHelper.pushPage(
                          context: context,
                          opaque: false,
                          barrierColor: Colors.black54,
                          page: Center(
                            child: Hero(
                              tag: 'addExpense',
                              child: Material(
                                color: Colors.transparent,
                                child: AddExpenseDialog(
                                  onSave: () =>  _loadData(),
                                ),
                              ),
                            ),
                          ),
                        );

                      },

                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                      title: "Add Expense",
                      textSize: 14,
                      filled: true,
                      color: MyColors.sidebarSelected,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  UiHelper.myButton(
                    callback: () {
                      UiHelper.pushPage(
                        context: context,
                        page: const DailyExpenseTracker(),
                      );
                    },
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                    title: "Expense Report",
                    textSize: 14,
                    filled: true,
                    color: Colors.blueGrey,
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          SizedBox(height: spacing),
          _topBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Expanded(
                        child: ExpenseCards(
                          expenses: expenses,
                          categories: categories,
                          onSave: () => _fetchExpenses(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Page: ${pageNo + 1}, Total Expenses: $expenseCount',
                            style: MyFont.bold(14, color: MyColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                PaginationBar(
                  page: pageNo,
                  pageSize: pageSize,
                  itemCount: expenses.length,
                  onNext: () {
                    setState(() {
                      pageNo++;
                      _fetchExpenses();
                    });
                  },
                  onPrevious: () {
                    setState(() {
                      pageNo--;
                      _fetchExpenses();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    String formatEpoch(int ms) {
      if (ms == 0) return "Not set";
      return DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));
    }

    final categoryOptions = ['All', ...categories.map((c) => c.name)];
    final paymentOptions = ['All', 'Cash', 'Digital', 'Bank', 'Other'];
    final typeOptions = ['All', 'Income', 'Expense'];
    final dateOptions = ["From: ${formatEpoch(startDate)}", "To: ${formatEpoch(endDate)}"];

    Widget searchBar(){
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: MouseRegion(
          onEnter: (_) => isTextCursor = true,
          onExit: (_) => isTextCursor = false,
          child: TextField(
            controller: searchController,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                if (!mounted) return;
                setState(() {
                  pageNo = 0;
                  _fetchExpenses();
                });
              });
            },
            style: MyFont.medium(14, color: MyColors.textMain),
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              hintStyle: MyFont.medium(14, color: MyColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: MyColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if(compress)
          ...[
            searchBar(),
            SizedBox(height: spacing),
          ],
        Row(
          children: [
            if (!compress)
            Expanded(
              child: searchBar(),
            ),
            SizedBox(width: spacing),

            // Person Selector
            if (selectedPerson != null)
              ScaledContainer(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedPerson = null;
                      pageNo = 0;
                      _fetchExpenses();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MyColors.sidebarSelected.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedPerson!.image != null)
                          ClipOval(child: Image.memory(selectedPerson!.image!, width: 24, height: 24, fit: BoxFit.cover))
                        else
                          const Icon(Icons.person, size: 24, color: MyColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(selectedPerson!.name, style: MyFont.medium(14, color: MyColors.textMain)),
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
                        Text("Select Person", style: MyFont.medium(14, color: MyColors.textMain)),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(width: spacing),

            FilterButton(
              title: 'Category: ${selectedCategoryId == 0 ? "All" : categories.firstWhere((c) => c.id == selectedCategoryId).name}',
              options: categoryOptions,
              onSelected: (idx) async {
                selectedCategoryId = idx == 0 ? 0 : categories[idx - 1].id!;
                pageNo = 0;
                await _fetchExpenses();
              },
            ),
            SizedBox(width: spacing),
            FilterButton(
              title: 'Method: $selectedPaymentMethod',
              options: paymentOptions,
              onSelected: (idx) async {
                selectedPaymentMethod = paymentOptions[idx];
                pageNo = 0;
                await _fetchExpenses();
              },
            ),
            SizedBox(width: spacing),
            FilterButton(
              title: 'Type: ${typeOptions[selectedType]}',
              options: typeOptions,
              onSelected: (idx) async {
                selectedType = idx;
                pageNo = 0;
                await _fetchExpenses();
              },
            ),
            SizedBox(width: spacing),
            FilterButton(
              title: 'Date',
              options: dateOptions,
              width: 180,
              onSelected: (idx) async {
                await _pickDate(idx);
                pageNo = 0;
                await _fetchExpenses();
              },
            ),
            SizedBox(width: spacing),
            ScaledContainer(
              scale: 1.2,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    selectedCategoryId = 0;
                    selectedPaymentMethod = 'All';
                    selectedType = 0;
                    startDate = endDate = 0;
                    selectedPerson = null;
                    searchController.clear();
                    pageNo = 0;
                    _fetchExpenses();
                  });
                },
                child: Text("Reset Filters", style: MyFont.bold(14, color: MyColors.sidebarSelected)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _choosePerson() async {
    final person = await UiHelper.pushPage<Person?>(
      context: context,
      opaque: false,
      barrierDismissible: true,
      page: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            height: 600,
            decoration: UiHelper.myDecoration(),
            child: const ChoosePerson(filter: 0),
          ),
        ),
      ),
    );

    if (person != null) {
      setState(() {
        selectedPerson = person;
        pageNo = 0;
        _fetchExpenses();
      });
    }
  }

  _pickDate(int i) async {
    final initial = DateTime.now();
    DateTime? picked = await pickDate(context, initial);
    if (picked == null) return;

    if (i == 0) {
      startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0).millisecondsSinceEpoch;
    } else {
      endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59).millisecondsSinceEpoch;
    }
    setState(() {});
  }
}
