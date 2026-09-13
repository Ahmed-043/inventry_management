import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense_category.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import '../../colors.dart';

class ExpenseCards extends StatelessWidget {
  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final VoidCallback onSave;

  const ExpenseCards({
    super.key,
    required this.expenses,
    required this.categories,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
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
                itemCount: expenses.length,
                itemBuilder: (context, i) {
                  final expense = expenses[i];
                  return Column(
                    children: [
                      expenseCard(context, expense),
                      if (i + 1 < expenses.length)
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
      'ID',
      'TYPE',
      'CATEGORY',
      'TITLE',
      'PERSON',
      'AMOUNT',
      'DATE',
      'METHOD',
      'REMARK',
    ];
    const List<int> flexValues = [1, 1, 2, 2, 1, 1, 1, 1, 2];

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
              textAlign: i == 0 || i == 2 || i == 3 || i == 4 ? .start : TextAlign.center,
              style: MyFont.bold(12, color: MyColors.textSecondary),
            ),
          );
        }),
      ),
    );
  }

  Widget expenseCard(BuildContext context, Expense expense) {
    final date = DateTime.fromMillisecondsSinceEpoch(expense.expenseDate);
    final formattedDate = DateFormat('dd MMM yy').format(date);
    double textSize = 14;
    final isIn = expense.amount > 0;

    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => ExpenseCategory(name: 'Uncategorized', icon: ''),
    );

    Color statusColor = isIn ? MyColors.success : MyColors.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Edit logic if needed
        },
        hoverColor: MyColors.mainBg,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Expense ID
              Expanded(
                flex: 1,
                child: Text(
                  expense.id != null ? '#${expense.id}' : '-',
                  style: MyFont.bold(textSize, color: MyColors.textSecondary),
                ),
              ),
              // Type
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      isIn ? "IN" : "OUT",
                      style: MyFont.bold(10, color: statusColor),
                    ),
                  ),
                ),
              ),
              // Category
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(category.name), size: 18, color: MyColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: MyFont.bold(textSize, color: MyColors.textMain),
                    ),
                  ],
                ),
              ),
              // Title
              Expanded(
                flex: 2,
                child: Text(
                  expense.title,
                  style: MyFont.medium(textSize, color: MyColors.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Person
              Expanded(
                flex: 1,
                child: Text(
                  expense.personName.isEmpty ? '-' : expense.personName,
                  style: MyFont.medium(textSize, color: MyColors.textMain),
                ),
              ),
              // Amount
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Rs. ${NumberFormat.decimalPattern().format(expense.amount.abs())}',
                    style: MyFont.bold(textSize, color: statusColor),
                  ),
                ),
              ),
              // Date
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    formattedDate,
                    style: MyFont.medium(textSize, color: MyColors.textSecondary),
                  ),
                ),
              ),
              // Payment Method
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      expense.paymentMethod,
                      style: MyFont.bold(12, color: MyColors.textSecondary),
                    ),
                  ),
                ),
              ),
              // Remark
              Expanded(
                flex: 2,
                child: Text(
                  expense.remark,
                  style: MyFont.medium(textSize, color: MyColors.textSecondary),
                  maxLines: 2,
                  textAlign: .center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('beverage') || name.contains('coffee') || name.contains('drink')) return Icons.local_cafe_rounded;
    if (name.contains('transport') || name.contains('fuel') || name.contains('travel') || name.contains('car')) return Icons.directions_car_rounded;
    if (name.contains('software') || name.contains('tech') || name.contains('subscription')) return Icons.laptop_rounded;
    if (name.contains('groceries') || name.contains('shopping') || name.contains('market')) return Icons.shopping_cart_rounded;
    if (name.contains('food') || name.contains('restaurant') || name.contains('meal')) return Icons.restaurant_rounded;
    if (name.contains('rent') || name.contains('office') || name.contains('home')) return Icons.home_rounded;
    if (name.contains('salary') || name.contains('wage') || name.contains('pay')) return Icons.payments_rounded;
    if (name.contains('bill') || name.contains('electricity') || name.contains('water')) return Icons.receipt_long_rounded;
    if (name.contains('health') || name.contains('medical')) return Icons.medical_services_rounded;
    return Icons.category_outlined;
  }
}
