import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/invoice/reciept_card.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../../../Database/db_info.dart';
import '../../../../Database/order_items.dart';
import '../../../../Database/orders.dart';
import '../../../../Database/person.dart';
import '../../../../Shared_Widgets/adder_remover_value.dart';
import '../../../../Shared_Widgets/blinker.dart';
import '../../../../Shared_Widgets/fonts.dart';
import '../../../../Shared_Widgets/product_selector_panel.dart';
import '../../../../colors.dart';

import '../sections/order_back_card.dart';
import '../sections/order_sidebar.dart';
import 'order_table_header.dart';

class OrderProductsCard extends StatefulWidget {
  final VoidCallback callback;
  final Order order;
  final List<OrderItem> selectedProducts;
  final DBInfo info;
  final bool sell; //doesn't need to be a referenced one
  final Person? selectedPerson;
  final Function(Person) onPersonSelected;
  final bool showContent;
  const OrderProductsCard({
    super.key,
    required this.selectedProducts,
    required this.callback,
    required this.order,
    required this.info,
    this.sell = true,
    required this.selectedPerson,
    required this.onPersonSelected,
    required this.showContent,
  });

  @override
  State<OrderProductsCard> createState() => _OrderProductsCardState();
}

class _OrderProductsCardState extends State<OrderProductsCard> {
  final Map<int, bool> blinkMap = {}; // 👈 store per-item blink states
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  List<int> visibleIndices = [];
  final ScrollController _scrollController = ScrollController();
  bool compress = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    visibleIndices = List.generate(widget.selectedProducts.length, (i) => i);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _debounce?.cancel();
    searchController.dispose();
  }

  void _updateTotal() {
    double total = 0;
    for (var item in widget.selectedProducts) {
      total += item.price * item.quantity;
    }
    widget.order.totalAmount = total;
    widget.order.totalWeight = widget.selectedProducts.fold(
      0.0,
      (sum, item) => sum + item.weight * item.quantity,
    );

    widget.callback.call(); // 🔥 updates live
  }

  @override
  Widget build(BuildContext context) {
    compress = (MediaQuery.of(context).size.width < 800);

    return Hero(
      tag: '${widget.order.id}',
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MyColors.translucent,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(125),
              spreadRadius: 0.5,
              blurRadius: 3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 50, child: _buildSearchBar(MediaQuery.of(context).size.width)),
            if (widget.selectedProducts.isNotEmpty) OrderTableHeader(showDelete: widget.order.editable,),
            Expanded(child: _buildOrderList(compress)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(bool isCompact) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: widget.selectedProducts.length,
      itemBuilder: (context, index) =>
          orderItemTile(widget.selectedProducts[index], index),
      separatorBuilder: (context, index) => Divider(
        thickness: 0.5,
        height: 1,
        indent: 20,
        endIndent: 20,
        color: MyColors.darkBlue.withAlpha(100),
      ),
    );
  }

  Widget orderItemTile(OrderItem item, int index) {
    double height = 60.0;
    bool qtHovering = false, pHovering = false;
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      // padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((255 * 0.15).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: MyFont.bold(15, color: MyColors.blue),
              ),
            ),
          ),
          if(!compress)
            image(height: height, image: item.image),

          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.name ?? 'Product',
                style: MyFont.semiBold(20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Container(color: MyColors.grey, width: 1, height: 25),
          Expanded(
            flex: 1,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: height,
                padding: EdgeInsets.all(5),
                child: StatefulBuilder(
                  builder: (context, qtState) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(height / 2),
                      onTapDown: (TapDownDetails details) async {
                        if (!(widget.order.editable)) {
                          return;
                        }
                        final tapPosition = details.globalPosition;
                        final screenSize = MediaQuery.of(context).size;
                        qtState(
                          () => blinkMap[index] = true,
                        ); // start blinking before dialog
                        const dialogWidth = 400.0;
                        const dialogHeight = 200.0;

                        double left = tapPosition.dx - (dialogWidth / 2);
                        double top = tapPosition.dy + 20;

                        // 🔽 If it would go out of screen bottom, show above the tap
                        if (top + dialogHeight > screenSize.height) {
                          top = tapPosition.dy - dialogHeight - 20;
                        }

                        // 🔽 Prevent it from going off left/right edges
                        left = left.clamp(
                          10,
                          screenSize.width - dialogWidth - 10,
                        );
                        await showDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (_) => Stack(
                            children: [
                              Positioned(
                                left: left,
                                top: top,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: dialogWidth,
                                    height: dialogHeight,
                                    child: AdderRemoverValue(
                                      value: item.quantity,
                                      //isLarge: true,
                                      callBack: (newValue) {
                                        setState(() {
                                          widget
                                                  .selectedProducts[index]
                                                  .quantity =
                                              newValue;
                                          _updateTotal();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        qtState(
                          () => blinkMap[index] = false,
                        ); // start blinking before dialog
                      },

                      hoverColor: MyColors.blue.withAlpha(20),
                      onHover: (value) {
                        qtState(() {
                          pHovering = false;
                          qtHovering = value;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              NumberFormat.decimalPattern().format(
                                item.quantity,
                              ),
                              overflow: TextOverflow.ellipsis,

                              style: MyFont.semiBold(
                                20,
                                color: MyColors.darkBlue,
                              ),
                            ),
                          ),
                          if (blinkMap[index] ?? false) BlinkingCursor(),
                          if (qtHovering && widget.order.editable)
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: MyColors.info.withAlpha(200),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: height,
                padding: EdgeInsets.all(5),
                child: StatefulBuilder(
                  builder: (context, qtState) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(height / 2),
                      onTapDown: (TapDownDetails details) async {
                        if (!(widget.order.editable)) {
                          return;
                        }
                        final tapPosition = details.globalPosition;
                        showDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (_) => Stack(
                            children: [
                              Positioned(
                                left:
                                    tapPosition.dx -
                                    100, // exact x position of tap
                                top: tapPosition.dy + 20, // adjust y
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 300,
                                    height: 60,
                                    child: Container(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      hoverColor: MyColors.blue.withAlpha(20),
                      onHover: (value) {
                        qtState(() {
                          qtHovering = false;
                          pHovering = value;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              NumberFormat('#,##0.00').format(item.price),
                              overflow: TextOverflow.ellipsis,
                              style: MyFont.semiBold(
                                20,
                                color: MyColors.darkBlue,
                              ),
                            ),
                          ),
                          if (pHovering && widget.order.editable)
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: MyColors.info.withAlpha(200),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.order.editable)
          Container(
            padding: EdgeInsets.all(5),
            width: 70,
            height: height,
            child: IconButton(
              onPressed: () {
                setState(() {
                  if (!(widget.order.editable)) {
                    return;
                  }
                  widget.selectedProducts.removeAt(index);
                  _updateTotal();
                });
                if (widget.selectedProducts.isEmpty) {
                  widget.order.orderStatus = 'Pending';
                  widget.order.paymentStatus = 'Pending';
                }
              },
              icon: Icon(Icons.delete_outline_rounded, color: MyColors.error),
            ),
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
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: image == null
              ? Icon(Icons.shopping_bag_outlined, color: MyColors.grey)
              : Image.memory(image, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    return Row(
      children: [
        if (screenWidth < 800)
          Row(
            children: [
              SizedBox(
                width: 50,
                child: UiHelper.myButton(
                  callback: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    widget.order.editable
                        ? Icons.delete_outline_rounded
                        : Icons.arrow_back,
                    color:  MyColors.translucent,
                    size: 30,
                  ),
                  filled: true,
                  color: widget.order.editable
                      ? MyColors.error
                      : widget.sell
                      ? MyColors.primary
                      : MyColors.darkBlue,
                ),
              ),
              SizedBox(width: 5),
              SizedBox(
                width: 50,
                child: UiHelper.myButton(
                  callback: () {
                    showSidebar();
                  },
                  child: Icon(
                    Icons.menu,
                    color: MyColors.translucent,
                    size: 20,
                  ),
                  filled: true,
                  color: widget.sell ? MyColors.primary : MyColors.darkBlue,
                ),
              ),
            ],
          ),
        const SizedBox(width: 5),

        if (screenWidth > 800)
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: Material(
                color: Colors.transparent,
                child: UiHelper.mySearchBar(
                    controller: searchController,
                    readOnly: !widget.order.editable,
                    onChange: () async {
                      _debounce?.cancel();
                      final query = searchController.text.trim();
                      if (query.isEmpty) return;
                      _debounce = Timer(const Duration(milliseconds: 1500), () async {
                        await openProductsPanel(search: searchController.text);
                      });
                    }
                    ),
              ),
            ),
          ),
        const SizedBox(width: 5),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: UiHelper.myButton(
              callback: () async {
                await openProductsPanel();
                // print("Selected Products: $selectedProducts");
              },
              title: 'Add Products',
              filled: true,
              color: widget.order.editable ? MyColors.info : MyColors.lightGrey,
              borderRadius: (MediaQuery.of(context).size.width < 1300) ? 20 : 10,
            ),
          ),
        ),
        if (screenWidth < 1300) const SizedBox(width: 5),
        if (screenWidth < 1300)
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: UiHelper.myButton(
                callback: () {
                  showReceipt();
                },
                title: "Receipt",
                filled: true,
                textSize: 15,
                borderRadius: 20,
                color: widget.sell ? MyColors.primary : MyColors.darkBlue,
              ),
            ),
          ),
      ],
    );
  }
  Future<void> openProductsPanel({String? search}) async {
    if (!(widget.order.editable)) {
      return;
    }
    await showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: EdgeInsets.all(10),

      child: SizedBox(
        width: 1200,
        height: 800,
        child: ProductSelectorPanel(
          // products: products,
          orderItems: widget.selectedProducts,
          select: 'O',
          search: search,
        ),
      ),
    ),
    );
    //syncSelectedProducts();

    if (widget.selectedProducts.isNotEmpty &&
        widget.order.paymentStatus == 'Paid') {
      widget.order.orderStatus = 'Completed';
      widget.callback.call();
    } else {
      widget.order.orderStatus = 'Pending';
      widget.order.paymentStatus = 'Pending';
      widget.callback.call();
    }
    _updateTotal();
    setState(() {
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
      );
    });

  }
  void showReceipt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "SideSheet",
      pageBuilder: (_, __, ___) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (MediaQuery.of(context).size.width > 1400) {
              Navigator.pop(context);
            }

            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: MyColors.black.withAlpha(100),
                child: SizedBox(
                  width: 400,
                  height: double.infinity,
                  child: InvoiceScreen(
                    key: ValueKey('invoice_screen_modal_${widget.order.id}'),
                    order: widget.order,
                    selectedProducts: widget.selectedProducts,
                    sell: widget.sell,
                    info: widget.info,
                    callback: widget.callback,
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void showSidebar() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "SideSheet",
      pageBuilder: (_, __, ___) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (MediaQuery.of(context).size.width > 800) {
              Navigator.pop(context);
            }

            return Align(
              alignment: Alignment.centerLeft,
              child: StatefulBuilder(
                builder: (context, state) {
                  return Material(
                    color: MyColors.black.withAlpha(100),
                    child: SizedBox(
                      width: (Platform.isAndroid || Platform.isIOS)
                          ? double.infinity
                          : 350,
                      height: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 10,
                          right: 5,
                        ),
                        child: Column(
                          children: [
                            OrderBackCard(
                              heroTag: widget.sell ? 'sellOrderHero' : 'buyOrderHero',
                              title: "${widget.sell ? "Selling Order" : "Receive Order"}${widget.order.editable ? "" : " (Confirmed)"}",
                              sell: widget.sell,
                              editable: widget.order.editable,
                              showDeleteIcon: false,
                              onPressed: () async {
                                Navigator.pop(context);
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: OrderSidebar(
                                  key: ValueKey('order_sidebar_modal_${widget.order.id}'),
                                  sell: widget.sell,
                                  selectedProducts: widget.selectedProducts,
                                  callback: () => setState(() {}),
                                  order: widget.order,
                                  info: widget.info,
                                  selectedPerson: widget.selectedPerson,
                                  onPersonSelected: (person) {
                                    widget.onPersonSelected(person);
                                    state(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

