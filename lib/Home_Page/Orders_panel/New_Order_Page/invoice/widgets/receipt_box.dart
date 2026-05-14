import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../Database/db_info.dart';
import '../../../../../Database/order_items.dart';
import '../../../../../Database/orders.dart';
import '../../../../../Shared_Widgets/fonts.dart';
import '../../../../../Shared_Widgets/main_ui_helper.dart';
import '../../../../../colors.dart';

class ReceiptBox extends StatelessWidget {
  final Order order;
  final List<OrderItem> selectedProducts;
  final DBInfo info;
  final bool sell;
  final NumberFormat formatter;

  const ReceiptBox({
    super.key,
    required this.order,
    required this.selectedProducts,
    required this.info,
    required this.sell,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            color: MyColors.translucent,
            width: 385,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                info.image == null
                    ? const Icon(Icons.shopping_bag, color: Colors.blue, size: 50)
                    : SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipOval(
                          child: Image.memory(info.image!, fit: BoxFit.cover),
                        ),
                      ),
                Text(info.dbName, style: MyFont.bold(22, color: MyColors.info)),
                Text("Order Invoice #${order.id}", style: MyFont.normal(16)),
                const SizedBox(height: 8),
                Text(info.location, textAlign: TextAlign.center, style: MyFont.normal(14)),
                Text("Phone: ${info.phone}", style: MyFont.normal(14)),
                const Divider(height: 10),
                _buildMetaRow(),
                const SizedBox(height: 16),
                _buildTableHeader(),
                const SizedBox(height: 6),
                _buildTableRows(),
                const Divider(height: 1, thickness: 0.5),
                _buildItemsRow(),
                const Divider(height: 5),
                _buildSummary(),
                _buildTotals(),
                Text(
                  "Payment: ${order.paymentMethod}, (${order.orderType == 'sell' ? 'Payable' : 'Receivable'}, ${order.paymentStatus})${order.paymentStatus == 'Overdue' ? "\nDueDate: ${DateFormat('dd-MMM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(order.dueDateTimestamp))}" : ""}",
                  textAlign: TextAlign.center,
                  style: MyFont.normal(14),
                ),
                Text("Thank you for your order.", style: MyFont.normal(14)),
              ],
            ),
          ),
          Positioned.fill(
            child: UiHelper.waterMark(text: info.dbName),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Text(
            "Order ID: #${order.id}\nDate: ${DateFormat('dd-MMM-yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(order.orderTimestamp))},",
            style: MyFont.normal(14),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  text: '${order.name}\n',
                  style: MyFont.normal(14, color: MyColors.black),
                  children: [
                    TextSpan(
                      text: sell ? 'Customer' : 'Supplier',
                      style: MyFont.normal(10, color: MyColors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text("Item", style: MyFont.bold(14)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "Qty",
              textAlign: TextAlign.right,
              style: MyFont.bold(14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Unit Price",
              textAlign: TextAlign.right,
              style: MyFont.bold(14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Total",
              textAlign: TextAlign.right,
              style: MyFont.bold(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRows() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: selectedProducts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.6),
      itemBuilder: (context, index) {
        final e = selectedProducts[index];
        final lineTotal = e.quantity * e.price;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  e.name.toString(),
                  style: MyFiraFont.regular(15, color: MyColors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "${e.quantity}",
                  textAlign: TextAlign.center,
                  style: MyFiraFont.regular(15, color: MyColors.black),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatter.format(e.price),
                  textAlign: TextAlign.right,
                  style: MyFiraFont.regular(15, color: MyColors.black),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatter.format(lineTotal),
                  textAlign: TextAlign.right,
                  style: MyFiraFont.regular(15, color: MyColors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "Items: ${selectedProducts.length}, Qty: ${selectedProducts.fold<num>(0, (sum, p) => sum + (p.quantity))},  ",
          style: MyFont.normal(14),
        ),
        Text(
          "Wt: ${NumberFormat.decimalPattern().format(order.totalWeight)} Kg",
          style: MyFont.normal(14),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Total Bill:", style: MyFont.normal(14)),
        Text(
          "Rs. ${formatter.format(order.totalAmount)}",
          style: MyFont.normal(15, color: MyColors.blue),
        ),
      ],
    );
  }

  Widget _buildTotals() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Tax (${order.tax.first}):", style: MyFont.normal(14)),
            Text(
              "+${order.tax.first}. ${NumberFormat.decimalPattern().format(order.tax.second)}",
              style: MyFont.normal(15, color: MyColors.error),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Discount (${order.discount.first}):", style: MyFont.normal(14)),
            Text(
              "-${order.discount.first}. ${NumberFormat.decimalPattern().format(order.discount.second)}",
              style: MyFont.normal(15, color: MyColors.success),
            ),
          ],
        ),
        Text(
          "TOTAL Rs. ${formatter.format(order.totalAmount + order.adjustment)}",
          style: MyFont.bold(22),
        ),
      ],
    );
  }
}

