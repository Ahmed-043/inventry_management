import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense_category.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
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
    final isPhone = context.isPhone;

    if (isPhone) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: expenses.length,
        itemBuilder: (context, i) {
          final expense = expenses[i];
          return mobileExpenseCard(context, expense);
        },
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
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
                        Divider(height: 1, color: MyColors.textSecondary.withValues(alpha: 0.2)),
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

  Widget mobileExpenseCard(BuildContext context, Expense expense) {
    final date = DateTime.fromMillisecondsSinceEpoch(expense.expenseDate);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final isIn = expense.amount > 0;

    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => ExpenseCategory(name: 'Uncategorized', icon: ''),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColors.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isIn ? MyColors.success : MyColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.name,
                  style: MyFont.bold(11, color: isIn ? MyColors.success : MyColors.primary),
                ),
              ),
              Text(
                '${isIn ? '+' : '-'} Rs. ${NumberFormat('#,##0.00').format(expense.amount.abs())}',
                style: MyFont.bold(14, color: isIn ? MyColors.success : MyColors.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            expense.title.isEmpty ? 'Expense #${expense.id}' : expense.title,
            style: MyFont.bold(14, color: MyColors.darkBlue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (expense.personName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Person: ${expense.personName}',
              style: MyFont.medium(12, color: MyColors.textSecondary),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: MyFont.normal(11, color: MyColors.grey),
              ),
              Text(
                expense.paymentMethod ?? 'Other',
                style: MyFont.semiBold(11, color: MyColors.darkBlue),
              ),
            ],
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
          bottom: BorderSide(color: MyColors.textSecondary.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: List.generate(titles.length, (i) {
          return Expanded(
            flex: flexValues[i],
            child: Text(
              titles[i],
              textAlign: i == 0 || i == 2 || i == 3 || i == 4 ? TextAlign.start : TextAlign.center,
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
        onTap: () {},
        hoverColor: MyColors.mainBg,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '#${expense.id}',
                  style: MyFont.semiBold(textSize, color: MyColors.textSecondary),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isIn ? 'Income' : 'Expense',
                      style: MyFont.bold(12, color: statusColor),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  category.name,
                  style: MyFont.medium(textSize, color: MyColors.textMain),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  expense.title,
                  style: MyFont.bold(textSize, color: MyColors.textMain),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  expense.personName.isEmpty ? '-' : expense.personName,
                  style: MyFont.medium(textSize, color: MyColors.textMain),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Rs. ${NumberFormat('#,##0').format(expense.amount.abs())}',
                  textAlign: TextAlign.center,
                  style: MyFont.bold(textSize, color: statusColor),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  formattedDate,
                  textAlign: TextAlign.center,
                  style: MyFont.medium(textSize, color: MyColors.textSecondary),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  expense.paymentMethod ?? 'Other',
                  textAlign: TextAlign.center,
                  style: MyFont.medium(textSize, color: MyColors.textMain),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  expense.remark.isEmpty ? '-' : expense.remark,
                  textAlign: TextAlign.center,
                  style: MyFont.medium(textSize, color: MyColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
