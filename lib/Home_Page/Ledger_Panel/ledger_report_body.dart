import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/db_info.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/new_order_page.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

class LedgerReportBody extends StatelessWidget {
  final List<Map<String, dynamic>> ledgerEntries;
  final String personName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final DBInfo? companyInfo;

  const LedgerReportBody({
    super.key,
    required this.ledgerEntries,
    required this.personName,
    this.fromDate,
    this.toDate,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    this.companyInfo,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat('#,##0.00');
    bool isMultiDay = fromDate != null && toDate != null && (fromDate!.year != toDate!.year || fromDate!.month != toDate!.month || fromDate!.day != toDate!.day);
    String periodText = "All Time";
    if (fromDate != null && toDate != null) {
      periodText = !isMultiDay
          ? DateFormat('dd MMMM yyyy').format(fromDate!)
          : "${DateFormat('dd MMM yyyy').format(fromDate!)} - ${DateFormat('dd MMM yyyy').format(toDate!)}";
    } else if (fromDate != null) {
      periodText = "From ${DateFormat('dd MMM yyyy').format(fromDate!)}";
    } else if (toDate != null) {
      periodText = "Until ${DateFormat('dd MMM yyyy').format(toDate!)}";
    }
    return Container(
      width: 900, // Slightly wider for Order ID column
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
          _buildInfoLine("Person:", personName, isBold: true),
          _buildInfoLine("Period:", periodText, isBold: true),
          _buildInfoLine(
            "Closing Balance:",
            "Rs. ${priceFormat.format(closingBalance.abs())} ${closingBalance >= 0 ? '(REC)' : '(PAY)'}",
            isBold: true,
          ),
          const SizedBox(height: 30),
          _buildTable(context, isMultiDay, priceFormat),
          // const SizedBox(height: 30),
          // Text("Notes:", style: MyFont.medium(16)),
          // const SizedBox(height: 8),
          // Container(
          //   height: 30,
          //   width: double.infinity,
          //   decoration: const BoxDecoration(
          //     border: Border(bottom: BorderSide(color: Colors.black)),
          //   ),
          // ),
          // const SizedBox(height: 10),
          // Container(
          //   height: 30,
          //   width: double.infinity,
          //   decoration: const BoxDecoration(
          //     border: Border(bottom: BorderSide(color: Colors.black)),
          //   ),
          // ),
          // const SizedBox(height: 40),
          // const Divider(color: Colors.black),
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
                companyInfo?.dbName.toUpperCase() ?? "ACCOUNT LEDGER",
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
            "LEDGER",
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

  Widget _buildTable(BuildContext context, bool isMultiDay, NumberFormat priceFormat) {
    return Column(
      children: [
        // Table Header
        Container(
          decoration: BoxDecoration(
            color: MyColors.primary.withAlpha(80),
            border: Border.all(color: Colors.black),
          ),
          child: Row(
            children: [
              _tableCell("Date", flex: 2, isHeader: true),
              _tableCell("Order", flex: 1, isHeader: true),
              _tableCell("Description", flex: 3, isHeader: true),
              _tableCell("Debit (+)", flex: 2, isHeader: true),
              _tableCell("Credit (-)", flex: 2, isHeader: true),
              _tableCell("Balance", flex: 2, isHeader: true, isLast: true),
            ],
          ),
        ),
        // Table Rows
        ...List.generate(ledgerEntries.length > 20 ? ledgerEntries.length : 20, (index) {
          if (index < ledgerEntries.length) {
            final entry = ledgerEntries[index];
            final isDebit = entry['entry_type'] == 'debit';
            final amount = (entry['amount'] as num).toDouble();
            final date = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
            final orderId = entry['order_id'] ?? 0;
            final transactionId = entry['transaction_id'] ?? 0;
            final source = entry['source'] ?? '';
            final balance = (entry['calculated_balance'] as num?)?.toDouble() ?? 0.0;

            String idText = "-";
            VoidCallback? onCellTap;
            if (source == 'order' && orderId > 0) {
              idText = "#$orderId";
              onCellTap = () async {
                Order? order = await getOrderById(currentDB!, orderId);
                if (order != null) {
                  order.editable = false;
                  order.totalAmount = order.totalAmount.abs();
                  order.paidAmount = order.paidAmount.abs();

                  double payment =
                      order.totalAmount +
                          (order.tax.first == '%'
                              ? order.totalAmount * order.tax.second / 100
                              : order.tax.second) -
                          (order.discount.first == '%'
                              ? order.totalAmount * order.discount.second / 100
                              : order.discount.second);
                  order.adjustment = payment - order.totalAmount;

                  if (context.mounted) {
                    UiHelper.pushPage(
                      context: context,
                      blurBackground: false,
                      page: NewOrderPage(
                        sell: order.orderType == 'sell',
                        order: order,
                        callback: () {},
                      ),
                    );
                  }
                }
              };
            } else if (source == 'transaction' && transactionId > 0) {
              idText = "-";
            } else if (source == 'person') {
              idText = "-";
            }

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
                  _tableCell(DateFormat('dd MMM yy\nhh:mm a').format(date), flex: 2, isMedium: true, onTap: onCellTap),
                  _tableCell(idText, flex: 1, onTap: onCellTap),
                  _tableCell(entry['remark'] ?? '', flex: 3, onTap: onCellTap),
                  _tableCell(isDebit ? priceFormat.format(amount) : "-", flex: 2, color: Colors.green, onTap: onCellTap),
                  _tableCell(!isDebit ? "-${priceFormat.format(amount)}" : "-", flex: 2, color: Colors.red, onTap: onCellTap),
                  _tableCell(priceFormat.format(balance), flex: 2, isLast: true, isBold: true, onTap: onCellTap),
                ],
              ),
            );
          } else {
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
                  _tableCell("", flex: 2),
                  _tableCell("", flex: 1),
                  _tableCell("", flex: 3),
                  _tableCell("", flex: 2),
                  _tableCell("", flex: 2),
                  _tableCell("", flex: 2, isLast: true),
                ],
              ),
            );
          }
        }),
        // Totals
        const SizedBox(height: 10),
        _buildTotalRow("Total Debit (+):", totalDebit, priceFormat, color: Colors.green),
        _buildTotalRow("Total Credit (-):", totalCredit, priceFormat, color: Colors.red),
        const Divider(color: Colors.black, thickness: 1),
        _buildTotalRow(
          "Closing Balance:",
          closingBalance.abs(),
          priceFormat,
          isBold: true,
          suffix: closingBalance >= 0 ? '(DR)' : '(CR)',
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
          width: 200,
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

  Widget _tableCell(String text, {
    int flex = 1,
    bool isHeader = false,
    bool isLast = false,
    Color? color,
    bool isBold = false,
    bool isMedium = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                  : (isBold
                      ? MyFont.bold(14, color: color)
                      : (isMedium ? MyFont.medium(14, color: color, height: 1.2) : MyFont.semiBold(14, color: color, height: 1.2))),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}
