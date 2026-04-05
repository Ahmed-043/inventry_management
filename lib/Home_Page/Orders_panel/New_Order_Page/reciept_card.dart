import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/db_info.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../../../Database/database.dart';
import '../../../Database/order_items.dart';
import '../../../Database/payment_transactions.dart';
import '../../../Database/pdf.dart';
import '../../../Database/product_stock.dart';
import '../../../Shared_Widgets/product_selector_panel.dart';
import '../../../colors.dart';

class InvoiceScreen extends StatefulWidget {
  final Order order;
  final List<OrderItem> selectedProducts;
  final DBInfo info;
  final VoidCallback callback;
  final bool sell;
  const InvoiceScreen({
    super.key,
    required this.order,
    required this.selectedProducts,
    required this.info,
    required this.callback,
    this.sell = true,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final formatter = NumberFormat("#,##0.0#", "en_US");
  ScrollController scrollController = ScrollController();
  bool isLoading = false, isSharing = false;

  final GlobalKey receiptKey = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 0, left: 5, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Material(
                color: MyColors.translucent,
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Center(child: RepaintBoundary(
                      key: receiptKey,
                      child: receiptBox())),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: (widget.order.editable || widget.order.update || widget.order.cancel)
                ? SizedBox(
                  child: UiHelper.myButton(
                      callback: () async {
                        setState(() {
                          isLoading = true;
                        });
                        if(widget.order.update || widget.order.cancel){
                          await updatePendingOrderFromObject(currentDB!,order: widget.order);
                          widget.order.update = false;
                          widget.order.cancel = false;
                          setState(() {
                            isLoading = false;
                          });
                          UiHelper.showToast(context, 'Order Updated Successfully');
                          return;
                        }
                        else{
                          final Map<int, int> idMap = {
                            for (final item in widget.selectedProducts)
                              item.productId: item.quantity,
                          };
                          final stock = await getRequiredStockOnlyProducts(
                            idMap,
                            currentDB!,
                          );
                          stock.forEach((key, value) =>
                              debugPrint('$key: $value'));
                          if (widget.order.orderType == 'sell') {
                            if (stock.isNotEmpty) {
                              updateStockDialog(idMap);
                              setState(() {
                                isLoading = false;
                              });
                            } else {
                              confirmOrder();
                            }
                          } else {
                            confirmOrder();
                          }
                        }
                      },
                      title: "Confirm & ${(widget.order.update || widget.order.cancel) ? 'Update' :'Save'}",
                      child: (isLoading) ? SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          color: MyColors.translucent,
                        ),
                      ) : null,
                      color: MyColors.info,
                      filled: true,
                    ),
                )
                : Row(
                    children: [
                      Expanded(
                        child: UiHelper.myButton(
                          callback: () async {
                            ///save image
                            setState(() {isSharing = true;});

                            if(Platform.isWindows || Platform.isLinux || Platform.isMacOS){
                              await captureAndShareReceipt(receiptKey,'file');
                              if(mounted) UiHelper.showToast(context, 'Image copied to clipboard!');
                            }else{
                            await captureAndShareReceipt(receiptKey,'file');
                            }
                            if(mounted) setState(() {isSharing = false;});

                          },
                          title: "Share Receipt",
                          child: isSharing
                              ? SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(color: MyColors.info,
                                  strokeWidth: 3, // thickness of the line
                                  strokeCap: StrokeCap.round, // makes the ends of the line rounded
                                  )
                              )
                              : Icon(
                            Icons.share_rounded ,
                            size: 25,
                            color: MyColors.info,
                          ),
                          color: MyColors.info,
                          borderRadius: 15,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: UiHelper.myButton(
                          rightClick: () async {
                            await captureAndSaveReceipt(receiptKey,name: 'Receipt_${widget.order.id}');
                          },
                          callback: () async {
                            saveAsPdf(widget: receiptBoxPdf(),name: 'Receipt_${widget.order.id}');
                          },
                          title: "Save as PDF",
                          child: Icon(
                            Icons.picture_as_pdf,
                            size: 25,
                            color: MyColors.translucent,
                          ),
                          filled: true,
                          color: MyColors.info,
                          borderRadius: 15,
                        ),
                      ),
                    ],
                  ),
          ),
          Text(widget.order.editable ? "Order is in Progress" : "Order is Confirmed You can safely go back",
                style: MyFiraFont.regular(12,color: widget.order.editable ? MyColors.error : MyColors.blue),
          )
        ],
      ),
    );
  }

  updateStockDialog(Map<int, int> idMap) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: 800,
            height: 800,
            child: ProductSelectorPanel(
              // products: products,
              idMap: idMap,
              select: 's',
            ),
          ),
        );
      },
    );
  }

  Widget receiptBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            color: MyColors.translucent,
            width: 385,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

            // color: Colors.white,
            child: Column(
              children: [
                // Header
                widget.info.image == null
                    ? const Icon(Icons.shopping_bag, color: Colors.blue, size: 50)
                    : SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipOval(
                          child: Image.memory(widget.info.image!, fit: BoxFit.cover),
                        ),
                      ),
                Text(
                  widget.info.dbName,
                  style: MyFont.bold(22, color: MyColors.info),
                ),
                //  const SizedBox(height: 8),
                Text("Order Invoice #${widget.order.id}", style: MyFont.normal(16)),
                const SizedBox(height: 8),
                Text(widget.info.location, textAlign: TextAlign.center, style: MyFont.normal(14),),
                Text("Phone: ${widget.info.phone}",style: MyFont.normal(14),
                ),
                const Divider(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Text(
                        "Order ID: #${widget.order.id}\nDate: ${DateFormat('dd-MMM-yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp))},",
                        style: MyFont.normal(14),

                      ),
                      Expanded(
                          child: Align(
                              alignment: Alignment.topRight,
                              child: RichText(
                                textAlign: TextAlign.right,
                                text: TextSpan(
                                  text: '${widget.order.name}\n',
                                  style: MyFont.normal(14,color: MyColors.black),

                                  children: [
                                    TextSpan(
                                      text: widget.sell ? 'Customer' : 'Supplier',
                                      style: MyFont.normal(10,color: MyColors.black),

                                    ),
                                  ],
                                ),
                              )

                          )
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          "Item",
                          style: MyFont.bold(14),
                        ),
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
                ),
                const SizedBox(height: 6),
                // Table Rows

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.selectedProducts.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 0.6,),
                  itemBuilder: (context, index) {
                    final e = widget.selectedProducts[index];
                    final lineTotal = e.quantity * e.price;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          // SizedBox(
                          //   width: 30,
                          //   height: 30,
                          //   child: image(image: e.image, height: 30),
                          // ),
                          // const SizedBox(width: 8),
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
                ),
                const Divider(height: 1,thickness: 0.5,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Items: ${widget.selectedProducts.length}, Qty: ${widget.selectedProducts.fold<num>(0, (sum, p) => sum + (p.quantity))},  ",
                      style: MyFont.normal(14),
                    ),
                    Text(
                      "Wt: ${NumberFormat.decimalPattern().format(widget.order.totalWeight)} Kg",
                      style: MyFont.normal(14),

                    ),
                  ],
                ),

                const Divider(height: 5),

                // Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Bill:",style: MyFont.normal(14),
                    ),
                    Text(
                      "Rs. ${formatter.format(widget.order.totalAmount)}",
                      style: MyFont.normal(15, color: MyColors.blue),
                    ),
                  ],
                ),

                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tax (${widget.order.tax.first}):",
                      style: MyFont.normal(14),
                    ),
                    Text(
                      "+${widget.order.tax.first}. ${NumberFormat.decimalPattern().format(widget.order.tax.second)}",
                      style: MyFont.normal(15, color: MyColors.error),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Discount (${widget.order.discount.first}):",
                      style: MyFont.normal(14),
                    ),
                    Text(
                      "-${widget.order.discount.first}. ${NumberFormat.decimalPattern().format(widget.order.discount.second)}",
                      style: MyFont.normal(15, color: MyColors.success),
                    ),
                  ],
                ),
                // Total
                Text(
                  "TOTAL Rs. ${formatter.format(widget.order.totalAmount + widget.order.adjustment)}",
                  style: MyFont.bold(22),
                ),
                Text(
                  "Payment: ${widget.order.paymentMethod}, (${widget.order.orderType == 'sell' ? 'Payable' : 'Receivable'}, ${widget.order.paymentStatus})${widget.order.paymentStatus == 'Overdue' ? "\nDueDate: ${DateFormat('dd-MMM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(widget.order.dueDateTimestamp))}" : ""}",
                  textAlign: TextAlign.center,
                  style: MyFont.normal(14),
                ),

                Text("Thank you for your order.", style: MyFont.normal(14),
    ),
              ],
            ),
          ),
          Positioned.fill(
            child: UiHelper.waterMark(text: widget.info.dbName),
          ),
        ],
      ),
    );
  }

  Widget image({double height = 100, required Uint8List? image}) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: height,
        height: height,
        decoration: BoxDecoration(
          color: MyColors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(height / 5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 5),
          child: image == null
              ? Icon(Icons.shopping_bag_outlined, color: MyColors.grey)
              : Image.memory(image, fit: BoxFit.cover),
        ),
      ),
    );
  }

  pw.Widget receiptBoxPdf() {
    final formatter = NumberFormat.decimalPattern();

    return pw.Stack(children: [
      pw.Container(
        width: 227, // ~80 mm roll width
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            pw.Center(
              child: widget.info.image == null
                  ? pw.Icon(pw.IconData(0xe59c), color: PdfColors.blue, size: 28)
                  : pw.ClipOval(
                child: pw.Image(
                  pw.MemoryImage(widget.info.image!),
                  width: 28,
                  height: 28,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                widget.info.dbName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                "Order Invoice #${widget.order.id}",
                style: pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text(widget.info.location, style: pw.TextStyle(fontSize: 7))),
            pw.Center(child: pw.Text("Phone: ${widget.info.phone}", style: pw.TextStyle(fontSize: 7))),
            pw.Divider(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children : [
                  pw.Text("Order ID: #${widget.order.id}\nDate: ${DateFormat('dd-MMM-yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(widget.order.orderTimestamp))}",
              style: pw.TextStyle(fontSize: 7),),
                  pw.RichText(
                    textAlign: pw.TextAlign.right,
                    text: pw.TextSpan(
                      text: '${widget.order.name}\n',
                      style: pw.TextStyle(fontSize: 7),
                      children: [
                        pw.TextSpan(
                          text: widget.sell ? 'Customer' : 'Supplier',
                          style: pw.TextStyle(fontSize: 5),
                        ),
                      ],
                    ),
                  )
                ]
            ),
            pw.SizedBox(height: 8),

            // ===== TABLE HEADER =====
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              color: PdfColors.grey200,
              child: pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text("Item", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                pw.Expanded(flex: 1, child: pw.Text("Qty", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                pw.Expanded(flex: 2, child: pw.Text("Unit", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                pw.Expanded(flex: 2, child: pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
              ]),
            ),
            pw.SizedBox(height: 4),

            // ===== ROWS =====
            ...List.generate(widget.selectedProducts.length, (i) {
              final e = widget.selectedProducts[i];
              final lineTotal = e.quantity * e.price;

              return pw.Column(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(children: [
                    pw.Expanded(flex: 5, child: pw.Text(e.name.toString(), style: pw.TextStyle(fontSize: 7))),
                    pw.Expanded(flex: 1, child: pw.Text("${e.quantity}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7))),
                    pw.Expanded(flex: 2, child: pw.Text(formatter.format(e.price), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7))),
                    pw.Expanded(flex: 2, child: pw.Text(formatter.format(lineTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7))),
                  ]),
                ),
                if (i != widget.selectedProducts.length - 1)
                  pw.Divider(thickness: 0.3, height: 1),
              ]);
            }),

            pw.Divider(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  "Items: ${widget.selectedProducts.length}, Qty: ${widget.selectedProducts.fold<num>(0, (sum, p) => sum + p.quantity)},  ",
                  style: pw.TextStyle(fontSize: 7),
                ),
                pw.Text(
                  "Wt: ${formatter.format(widget.order.totalWeight)} Kg",
                  style: pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
            pw.Divider(height: 6),

            // ===== SUMMARY =====
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total:", style: pw.TextStyle(fontSize: 8)),
                pw.Text("Rs. ${formatter.format(widget.order.totalAmount)}",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.blue)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Tax (${widget.order.tax.first}):", style: pw.TextStyle(fontSize: 7)),
                pw.Text("+${formatter.format(widget.order.tax.second)}", style: pw.TextStyle(fontSize: 7, color: PdfColors.red)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Discount (${widget.order.discount.first}):", style: pw.TextStyle(fontSize: 7)),
                pw.Text("-${formatter.format(widget.order.discount.second)}", style: pw.TextStyle(fontSize: 7, color: PdfColors.green)),
              ],
            ),

            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                "TOTAL Rs. ${formatter.format(widget.order.totalAmount - widget.order.adjustment)}",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center
              ),
            ),
            pw.Center(
              child: pw.Text(
              "Payment: ${widget.order.paymentMethod}, (${widget.order.orderType == 'sell' ? 'Payable' : 'Receivable'}, ${widget.order.paymentStatus})${widget.order.paymentStatus == 'Overdue' ? "\nDueDate: ${DateFormat('dd-MMM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(widget.order.dueDateTimestamp))}" : ""}",
                style: pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.center
            ),),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text("Thank you for shopping!", style: pw.TextStyle(fontSize: 7)),
            ),
          ],
        ),
      ),

      // ===== WATERMARK =====
      pw.Positioned.fill(
        child: UiHelper.pdfWaterMark(text: widget.info.dbName),
      ),
    ]);
  }

  confirmOrder() async {

    try {
      if (widget.selectedProducts.isNotEmpty) {
        int orderId = await registerOrder(
          widget.order,
          widget.selectedProducts,
          currentDB!,
        );
        widget.order.id = orderId;
        widget.order.editable = false;
        setState(() {
          isLoading = false;
        });
      } else {
        UiHelper.showToast(context, 'Please select at least one product.');
        setState(() {
          isLoading = false;
        });
      }
      widget.callback.call();
    } catch (e) {
      debugPrint('Transaction failed: $e');
    }

  }

}
