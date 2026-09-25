import 'package:flutter/material.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense_category.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/person.dart';
import 'package:inventry_management/Database/payment_transactions.dart';

class AddExpenseController extends ChangeNotifier {
  final title = TextEditingController();
  final amount = TextEditingController();
  final remark = TextEditingController();
  final categoryController = TextEditingController();
  final personController = TextEditingController();

  bool isLoading = false;
  bool isIncome = false;
  bool recordAsTransaction = true;
  String paymentMethod = 'Cash';
  int expenseDate = DateTime.now().millisecondsSinceEpoch;
  Person? selectedPerson;
  int? selectedCategoryId;
  List<ExpenseCategory> categories = [];
  bool showAddCategoryIcon = false;

  AddExpenseController() {
    categoryController.addListener(_onCategoryTextChanged);
  }

  @override
  void dispose() {
    [title, amount, remark, categoryController, personController].forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> loadCategories() async {
    categories = await ExpenseCategory.getAll(currentDB!);
    notifyListeners();
  }

  void _onCategoryTextChanged() {
    final text = categoryController.text.trim();
    final index = categories.indexWhere((c) => c.name.toLowerCase() == text.toLowerCase());

    if (index != -1) {
      selectedCategoryId = categories[index].id;
      showAddCategoryIcon = false;
    } else {
      selectedCategoryId = null;
      showAddCategoryIcon = text.isNotEmpty;
    }
    notifyListeners();
  }

  Future<String?> addNewCategory(String name) async {
    try {
      final id = await ExpenseCategory.insert(currentDB!, ExpenseCategory(name: name));
      await loadCategories();
      selectedCategoryId = id;
      showAddCategoryIcon = false;
      notifyListeners();
      return 'Category "$name" created!';
    } catch (e) {
      return 'Failed to create category: $e';
    }
  }

  void selectCategory(int? id) {
    selectedCategoryId = id;
    if (id != null) {
      final cat = categories.firstWhere((c) => c.id == id);
      categoryController.text = cat.name;
      showAddCategoryIcon = false;
    }
    notifyListeners();
  }

  void updateType(bool income) {
    isIncome = income;
    notifyListeners();
  }

  void updatePaymentMethod(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  void updateRecordAsTransaction(bool value) {
    recordAsTransaction = value;
    notifyListeners();
  }

  void updateDate(int date) {
    expenseDate = date;
    notifyListeners();
  }

  void updatePerson(Person? person) {
    selectedPerson = person;
    personController.text = person?.name ?? '';
    notifyListeners();
  }

  Future<String?> saveExpense() async {
    if (title.text.trim().isEmpty) return "Title is required";
    final amt = double.tryParse(amount.text);
    if (amt == null || amt <= 0) return "Valid amount is required";

    isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expense = Expense(
        title: title.text.trim(),
        amount: isIncome ? amt : -amt,
        categoryId: selectedCategoryId ?? 0,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        personId: selectedPerson?.id ?? 0,
        personName: selectedPerson?.name ?? '',
        remark: remark.text.trim(),
        createdAt: now,
      );

      final id = await Expense.insert(currentDB!, expense);

      if (id != -1 && recordAsTransaction) {
        await insertTransaction(
          currentDB!,
          PaymentTransaction(
            personId: selectedPerson?.id ?? 0,
            name: selectedPerson?.name ?? title.text.trim(),
            orderId: 0,
            amount: isIncome ? amt : -amt,
            paidAmount: isIncome ? amt : -amt,
            paymentStatus: 'Paid',
            dueDate: expenseDate,
            paymentMethod: paymentMethod,
            timestamp: now,
            paymentTimestamp: expenseDate,
            remark: remark.text.trim(),
          ),
        );
      }

      isLoading = false;
      notifyListeners();

      if (id == -1) return "Failed to save expense";
      return null;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return "Error: $e";
    }
  }
}
