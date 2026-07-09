import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/db_info.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/invoice/widgets/receipt_placeholder.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../../../Database/database.dart';
import '../../../../Database/order_items.dart';
import '../../../../Database/pdf.dart';
import '../../../../Database/product_stock.dart';
import '../../../../Shared_Widgets/product_selector_panel.dart';
import '../../../../colors.dart';
import 'widgets/invoice_action_bar.dart';
import 'widgets/receipt_box.dart';
import 'widgets/receipt_box_pdf.dart';

// First Render Causes Jank due to shader compilation,
// so we delay it by 500ms to allow smooth loading of other components.
// This is a temporary fix and should be optimized in the future.

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
  bool render = performanceMode;

  final formatter = NumberFormat("#,##0.0#", "en_US");
  ScrollController scrollController = ScrollController();
  bool isLoading = false, isSharing = false;

  final GlobalKey receiptKey = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollToBottom();
    if(!render && !widget.order.editable) {
      Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          render = true;
        });
      }
    });
    }else{
      if (mounted) {
        setState(() {
          render = true;
        });
      }
    }
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
                  child: Center(
                    child: render ? RepaintBoundary(
                      key: receiptKey,
                      child: ReceiptBox(
                        order: widget.order,
                        selectedProducts: widget.selectedProducts,
                        info: widget.info,
                        sell: widget.sell,
                        formatter: formatter,
                      ),
                    ) : ReceiptPlaceholder(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 50, child: _buildActionButtons()),
          Text(
            widget.order.editable
                ? "Order is in Progress"
                : "Order is Confirmed You can safely go back",
            style: MyFiraFont.regular(
              12,
              color: widget.order.editable ? MyColors.error : MyColors.blue,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButtons() {
    final showConfirm =
        widget.order.editable || widget.order.update || widget.order.cancel;
    return InvoiceActionBar(
      showConfirm: showConfirm,
      isLoading: isLoading,
      isSharing: isSharing,
      confirmTitle: "Confirm & ${(widget.order.update || widget.order.cancel) ? 'Update' : 'Save'}",
      onConfirm: _handleConfirm,
      onShare: _handleShare,
      onSavePdf: _handleSavePdf,
      onSaveImage: _handleSaveImage,
    );
  }

  Future<void> _handleConfirm() async {
    setState(() {
      isLoading = true;
    });
    if(widget.order.paymentStatus == 'Paid') {
      widget.order.paidAmount = widget.order.totalAmount + widget.order.adjustment;
      print(widget.order.paidAmount);
    }
    if (widget.order.update || widget.order.cancel) {
      await updatePendingOrderFromObject(currentDB!, order: widget.order);
      widget.order.update = false;
      widget.order.cancel = false;
      if(widget.order.orderStatus == 'Canceled'){
        widget.order.paymentStatus = 'Canceled';
      }
      else if(widget.order.paidAmount >= (widget.order.totalAmount + widget.order.adjustment) || widget.order.paymentStatus == 'Paid'){
        widget.order.orderStatus = 'Completed';
        widget.order.paymentStatus = 'Paid';
        widget.callback.call();
      }else{
        widget.order.orderStatus = 'Pending';
        widget.order.paymentStatus = 'Pending';
        widget.callback.call();
      }

      setState(() {
        isLoading = false;
      });
      if (mounted) {
        UiHelper.showToast(context, 'Order Updated Successfully',type: 1);
      }
      return;
    }

    final Map<int, int> idMap = {
      for (final item in widget.selectedProducts) item.productId: item.quantity,
    };
    final stock = await getRequiredStockOnlyProducts(idMap, currentDB!);
    stock.forEach((key, value) => debugPrint('$key: $value'));
    if (widget.order.orderType == 'sell' && stock.isNotEmpty) {
      updateStockDialog(idMap);
      setState(() {
        isLoading = false;
      });
      return;
    }
    confirmOrder();
  }

  Future<void> _handleShare() async {
    setState(() {
      isSharing = true;
    });

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await captureAndShareReceipt(receiptKey, 'file');
      if (mounted) {
        UiHelper.showToast(context, 'Image copied to clipboard!',type: 1);
      }
    } else {
      await captureAndShareReceipt(receiptKey, 'file');
    }
    if (mounted) {
      setState(() {
        isSharing = false;
      });
    }
  }

  Future<void> _handleSavePdf() async {
    saveAsPdf(
      widget: buildReceiptBoxPdf(
        order: widget.order,
        selectedProducts: widget.selectedProducts,
        info: widget.info,
        sell: widget.sell,
      ),
      name: 'Receipt_${widget.order.id}',
    );
  }

  Future<void> _handleSaveImage() async {
    await captureAndSaveReceipt(receiptKey, name: 'Receipt_${widget.order.id}');
  }

  updateStockDialog(Map<int, int> idMap) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(10),
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
        UiHelper.showToast(context, 'Please select at least one product.',type: 2);
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
