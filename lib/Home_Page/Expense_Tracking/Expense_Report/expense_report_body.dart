import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/db_info.dart';
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
  final DBInfo? companyInfo;

  const ExpenseReportBody({
    super.key,
    required this.expenses,
    required this.categoryNames,
    required this.fromDate,
    required this.toDate,
    required this.totalIn,
    required this.totalOut,
    required this.netTotal,
    this.companyInfo,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat('#,##0.00');
    bool isMultiDay = fromDate.year != toDate.year || fromDate.month != toDate.month || fromDate.day != toDate.day;
    return Container(
      width: 900,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyHeader(),
          const SizedBox(height: 20),
          _buildInfoLine("Date:", !isMultiDay
              ? DateFormat('dd MMMM yyyy').format(fromDate)
              : "${DateFormat('dd MMM yyyy').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}", isBold: true),
          _buildInfoLine(
            "Total:",
            "Rs. ${priceFormat.format(netTotal.abs())} ${netTotal >= 0 ? '(IN)' : '(OUT)'}",
            isBold: true,
          ),
          const SizedBox(height: 30),
          _buildTable(totalIn, totalOut, netTotal, isMultiDay, priceFormat),
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

  Widget _buildCompanyHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyInfo?.image != null)
          Container(
            margin: const EdgeInsets.only(right: 20),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 2),
              image: DecorationImage(
                image: MemoryImage(companyInfo!.image!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyInfo?.dbName.toUpperCase() ?? "EXPENSE TRACKER",
                style: MyFont.bold(28, color: Colors.black),
              ),
              if (companyInfo?.location.isNotEmpty ?? false)
                Text(
                  companyInfo!.location,
                  style: MyFont.medium(14, color: Colors.black87),
                ),
              if (companyInfo?.phone.isNotEmpty ?? false)
                Text(
                  "Phone: ${companyInfo!.phone}",
                  style: MyFont.medium(14, color: Colors.black87),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "EXPENSES",
            style: MyFont.bold(18, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLine(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: isBold ? MyFont.bold(16) : MyFont.medium(16)),
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

  Widget _buildTable(double totalIn, double totalOut, double netTotal, bool isMultiDay, NumberFormat priceFormat) {
    return Column(
      children: [
        // Table Header
        Container(
          decoration: BoxDecoration(
            color:MyColors.primary.withAlpha(80),
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
              decoration: BoxDecoration(
                color: index % 2 != 0 ? MyColors.mainBg.withAlpha(100) : Colors.transparent,
                border: const Border(
                  left: BorderSide(color: Colors.black),
                  right: BorderSide(color: Colors.black),
                  bottom: BorderSide(color: Colors.black),
                ),
              ),
              child: Row(
                children: [
                  if (isMultiDay)
                    _tableCell(
                      DateFormat('dd MMM yy\nhh:mm a').format(DateTime.fromMillisecondsSinceEpoch(e.expenseDate)),
                      flex: 2,
                      isMedium: true,
                    ),
                  _tableCell(isIn ? "IN" : "OUT", flex: 1, color: isIn ? Colors.green : Colors.red),
                  _tableCell(categoryNames[e.categoryId] ?? 'N/A', flex: 2),
                  _tableCell(e.title, flex: 3),
                  _tableCell(e.personName.isEmpty ? '-' : e.personName, flex: 2),
                  _tableCell(e.paymentMethod, flex: 2),
                  _tableCell(priceFormat.format(e.amount.abs()), flex: 2, isLast: true, color: isIn ? Colors.green : Colors.red),
                ],
              ),
            );
          } else {
            // Empty rows to fill the space
            return Container(
              decoration: BoxDecoration(
                color: index % 2 != 0 ? MyColors.mainBg.withAlpha(100) : Colors.transparent,
                border: const Border(
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
        _buildTotalRow("Total Income (IN):", totalIn, priceFormat, color: Colors.green),
        _buildTotalRow("Total Expense (OUT):", totalOut, priceFormat, color: Colors.red),
        const Divider(color: Colors.black, thickness: 1),
        _buildTotalRow(
          "Total:",
          netTotal.abs(),
          priceFormat,
          isBold: true,
          suffix: netTotal >= 0 ? '(IN)' : '(OUT)',
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, NumberFormat priceFormat, {Color? color, bool isBold = false, String suffix = ''}) {
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
            "Rs. ${priceFormat.format(amount)} $suffix",
            style: isBold ? MyFont.bold(16, color: color) : MyFont.medium(16, color: color),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _tableCell(String text, {int flex = 1, bool isHeader = false, bool isLast = false, Color? color, bool isMedium = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: isLast ? BorderSide.none : const BorderSide(color: Colors.black),
          ),
        ),
        child: Text(
          text,
          style: isHeader
              ? MyFont.bold(16)
              : (isMedium ? MyFont.medium(14, color: color) : MyFont.semiBold(14, color: color)),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
  }
}
