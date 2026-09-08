import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';

class ExpenseReportBody extends StatelessWidget {
  final List<Expense> expenses;
  final Map<int, String> categoryNames;
  final DateTime fromDate;
  final DateTime toDate;
  final double totalIn;
  final double totalOut;
  final double netTotal;

  const ExpenseReportBody({
    super.key,
    required this.expenses,
    required this.categoryNames,
    required this.fromDate,
    required this.toDate,
    required this.totalIn,
    required this.totalOut,
    required this.netTotal,
  });

  @override
  Widget build(BuildContext context) {
    bool isMultiDay = fromDate.year != toDate.year || fromDate.month != toDate.month || fromDate.day != toDate.day;
    return Container(
      width: 800,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text(
              "Expense Tracker",
              style: MyFont.bold(28, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoLine("Date:", !isMultiDay
              ? DateFormat('dd MMMM yyyy').format(fromDate)
              : "${DateFormat('dd MMM').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}"),
          _buildInfoLine(
            "Total:",
            "Rs. ${netTotal.abs().toStringAsFixed(2)} ${netTotal >= 0 ? '(IN)' : '(OUT)'}",
          ),
          const SizedBox(height: 30),
          _buildTable(totalIn, totalOut, netTotal, isMultiDay),
          const SizedBox(height: 30),
          Text("Notes:", style: MyFont.medium(16)),
          const SizedBox(height: 8),
          Container(
            height: 30,
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 30,
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("powered by", style: MyFont.medium(12, color: Colors.grey)),
                  Text("ODVENTORY", style: MyFont.bold(16, color: Colors.black)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: MyFont.medium(16)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black)),
              ),
              child: Text(value, style: MyFont.medium(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(double totalIn, double totalOut, double netTotal, bool isMultiDay) {
    return Column(
      children: [
        // Table Header
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Row(
            children: [
              if (isMultiDay) _tableCell("Date", flex: 2, isHeader: true),
              _tableCell("Type", flex: 1, isHeader: true),
              _tableCell("Category", flex: 2, isHeader: true),
              _tableCell("Description", flex: 3, isHeader: true),
              _tableCell("Person", flex: 2, isHeader: true),
              _tableCell("Method", flex: 2, isHeader: true),
              _tableCell("Amount", flex: 2, isHeader: true, isLast: true),
            ],
          ),
        ),
        // Table Rows
        ...List.generate(expenses.length > 15 ? expenses.length : 15, (index) {
          if (index < expenses.length) {
            final e = expenses[index];
            final isIn = e.amount > 0;
            return Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black),
                  right: BorderSide(color: Colors.black),
                  bottom: BorderSide(color: Colors.black),
                ),
              ),
              child: Row(
                children: [
                  if (isMultiDay)
                    _tableCell(
                      DateFormat('dd MMM yy').format(DateTime.fromMillisecondsSinceEpoch(e.expenseDate)),
                      flex: 2,
                    ),
                  _tableCell(isIn ? "IN" : "OUT", flex: 1, color: isIn ? Colors.green : Colors.red),
                  _tableCell(categoryNames[e.categoryId] ?? 'N/A', flex: 2),
                  _tableCell(e.title, flex: 3),
                  _tableCell(e.personName.isEmpty ? '-' : e.personName, flex: 2),
                  _tableCell(e.paymentMethod, flex: 2),
                  _tableCell(e.amount.abs().toStringAsFixed(2), flex: 2, isLast: true),
                ],
              ),
            );
          } else {
            // Empty rows to fill the space
            return Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black),
                  right: BorderSide(color: Colors.black),
                  bottom: BorderSide(color: Colors.black),
                ),
              ),
              child: Row(
                children: [
                  if (isMultiDay) _tableCell("", flex: 2),
                  _tableCell("", flex: 1),
                  _tableCell("", flex: 2),
                  _tableCell("", flex: 3),
                  _tableCell("", flex: 2),
                  _tableCell("", flex: 2),
                  _tableCell("", flex: 2, isLast: true),
                ],
              ),
            );
          }
        }),
        // Totals at the bottom
        const SizedBox(height: 10),
        _buildTotalRow("Total Income (IN):", totalIn, color: Colors.green),
        _buildTotalRow("Total Expense (OUT):", totalOut, color: Colors.red),
        const Divider(color: Colors.black, thickness: 1),
        _buildTotalRow(
          "Total:",
          netTotal.abs(),
          isBold: true,
          suffix: netTotal >= 0 ? '(IN)' : '(OUT)',
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {Color? color, bool isBold = false, String suffix = ''}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: isBold ? MyFont.bold(16) : MyFont.medium(16)),
        const SizedBox(width: 10),
        Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black)),
          ),
          child: Text(
            "Rs. ${amount.toStringAsFixed(2)} $suffix",
            style: isBold ? MyFont.bold(16, color: color) : MyFont.medium(16, color: color),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _tableCell(String text, {int flex = 1, bool isHeader = false, bool isLast = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: isLast ? BorderSide.none : const BorderSide(color: Colors.black),
          ),
        ),
        child: Text(
          text,
          style: isHeader ? MyFont.bold(14) : MyFont.medium(14, color: color),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
