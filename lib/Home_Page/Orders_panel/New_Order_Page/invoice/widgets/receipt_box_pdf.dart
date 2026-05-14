import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../../Database/db_info.dart';
import '../../../../../Database/order_items.dart';
import '../../../../../Database/orders.dart';
import '../../../../../Shared_Widgets/main_ui_helper.dart';

pw.Widget buildReceiptBoxPdf({
  required Order order,
  required List<OrderItem> selectedProducts,
  required DBInfo info,
  required bool sell,
}) {
  final formatter = NumberFormat.decimalPattern();

  return pw.Stack(children: [
    pw.Container(
      width: 227, // ~80 mm roll width
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: info.image == null
                ? pw.Icon(pw.IconData(0xe59c), color: PdfColors.blue, size: 28)
                : pw.ClipOval(
                    child: pw.Image(
                      pw.MemoryImage(info.image!),
                      width: 28,
                      height: 28,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              info.dbName,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              "Order Invoice #${order.id}",
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(child: pw.Text(info.location, style: const pw.TextStyle(fontSize: 7))),
          pw.Center(child: pw.Text("Phone: ${info.phone}", style: const pw.TextStyle(fontSize: 7))),
          pw.Divider(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Order ID: #${order.id}\nDate: ${DateFormat('dd-MMM-yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(order.orderTimestamp))}",
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.RichText(
                textAlign: pw.TextAlign.right,
                text: pw.TextSpan(
                  text: '${order.name}\n',
                  style: const pw.TextStyle(fontSize: 7),
                  children: [
                    pw.TextSpan(
                      text: sell ? 'Customer' : 'Supplier',
                      style: const pw.TextStyle(fontSize: 5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            color: PdfColors.grey200,
            child: pw.Row(children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text("Item", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text("Qty", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text("Unit", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
              ),
            ]),
          ),
          pw.SizedBox(height: 4),
          ...List.generate(selectedProducts.length, (i) {
            final e = selectedProducts[i];
            final lineTotal = e.quantity * e.price;

            return pw.Column(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(children: [
                  pw.Expanded(flex: 5, child: pw.Text(e.name.toString(), style: const pw.TextStyle(fontSize: 7))),
                  pw.Expanded(flex: 1, child: pw.Text("${e.quantity}", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7))),
                  pw.Expanded(flex: 2, child: pw.Text(formatter.format(e.price), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7))),
                  pw.Expanded(flex: 2, child: pw.Text(formatter.format(lineTotal), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7))),
                ]),
              ),
              if (i != selectedProducts.length - 1)
                pw.Divider(thickness: 0.3, height: 1),
            ]);
          }),
          pw.Divider(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                "Items: ${selectedProducts.length}, Qty: ${selectedProducts.fold<num>(0, (sum, p) => sum + p.quantity)},  ",
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                "Wt: ${formatter.format(order.totalWeight)} Kg",
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
          pw.Divider(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
               pw.Text("Total:", style: pw.TextStyle(fontSize: 8)),
              pw.Text(
                "Rs. ${formatter.format(order.totalAmount)}",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Tax (${order.tax.first}):", style: const pw.TextStyle(fontSize: 7)),
              pw.Text(
                "+${formatter.format(order.tax.second)}",
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.red),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Discount (${order.discount.first}):", style: const pw.TextStyle(fontSize: 7)),
              pw.Text(
                "-${formatter.format(order.discount.second)}",
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.green),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              "TOTAL Rs. ${formatter.format(order.totalAmount - order.adjustment)}",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Center(
            child: pw.Text(
              "Payment: ${order.paymentMethod}, (${order.orderType == 'sell' ? 'Payable' : 'Receivable'}, ${order.paymentStatus})${order.paymentStatus == 'Overdue' ? "\nDueDate: ${DateFormat('dd-MMM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(order.dueDateTimestamp))}" : ""}",
              style: const pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text("Thank you for shopping!", style: const pw.TextStyle(fontSize: 7)),
          ),
        ],
      ),
    ),
    pw.Positioned.fill(
      child: UiHelper.pdfWaterMark(text: info.dbName),
    ),
  ]);
}

