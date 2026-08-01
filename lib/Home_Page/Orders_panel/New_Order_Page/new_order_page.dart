import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/sections/order_sidebar.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/invoice/reciept_card.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/sections/order_back_card.dart';
import 'package:inventry_management/colors.dart';
import 'package:sqflite/sqflite.dart';

import '../../../Database/database.dart';
import '../../../Database/db_info.dart';
import '../../../Database/order_items.dart';
import '../../../Database/orders.dart';
import '../../../Database/person.dart';

import 'products/order_products_card.dart';

class NewOrderPage extends StatefulWidget {
  final bool sell;
  final Order? order;
  final VoidCallback callback;
  const NewOrderPage({
    super.key,
    this.sell = true,
    this.order,
    required this.callback,
  });

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  Person? selectedPerson;
  List<OrderItem> selectedProducts = [];
  late Order order;
  late ValueNotifier<double> totalNotifier;
  DBInfo info = DBInfo(dbName: "Default");
  bool showContent = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          showContent = true;
        });
      }
    });
    if (widget.order != null) {
      order = widget.order!;
      //adjustment calculation here
      debugPrint("DueDate in order: ${order.dueDateTimestamp}");
      selectedPerson = Person(name: order.name, id: order.personId);
      _initAsync(); // load info and products safely
    } else {
      order = Order(
        personId: 0,
        name: '',
        orderType: widget.sell ? 'sell' : 'buy',
        orderTimestamp: DateTime.now().millisecondsSinceEpoch,
        // add defaults for other fields
      );
      _loadInfo();
    }
    totalNotifier = ValueNotifier(0);
  }

  Future<void> _initAsync() async {
    await _loadInfo(); // load info first
    await _loadProductItems(); // then load products
    await getPaymentMethod(currentDB!,order.id??0);
    setState(() {}); // refresh UI after data is ready
  }

  Future<void> _loadInfo() async {
    info = await getDBInfo(currentDB!);
  }

  _loadProductItems() async {
    selectedProducts = await getOrderItemsByOrderId(currentDB!, order.id!);
    selectedProducts = selectedProducts.map((item) {
      item.price = item.price.abs();
      return item;
    }).toList();
  }

  Future<String?> getPaymentMethod(Database db, int orderId) async {
      final payment = await db.query('payment_transactions',
        columns: ['payment_method','payment_timestamp'],
        where: 'order_id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      order.paymentTimestamp = payment.isNotEmpty ? payment.first['payment_timestamp'] as int : 0;
      order.paymentMethod = payment.isNotEmpty ? payment.first['payment_method'] as String : 'Other';
      return null;
  }
  @override
  Widget build(BuildContext context) {
    debugPrint(selectedPerson?.name);

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1300;
    final showSidebar = screenWidth > 800 || selectedPerson == null;
    final showInvoice = !isCompact && selectedPerson != null;

    return Scaffold(
      backgroundColor: MyColors.mainBg,
      // appBar: AppBar(
      //   title: Text(
      //     widget.sell ? "Sell Order" : "Receive Order",
      //     style: MyFont.semiBold(22, color: MyColors.translucent),
      //   ),
      //   backgroundColor: widget.sell ? MyColors.darkBlue : MyColors.primary,
      //   foregroundColor: Colors.white,
      // ),
      body: Row(
        children: [
          if (showSidebar) _buildSidebarPanel(),
          if (selectedPerson != null) _buildProductsPanel(),
          if (showInvoice) _buildInvoicePanel(screenWidth),
        ],
      ),
    );
  }

  Widget _buildSidebarPanel() {
    return SizedBox(
      width: 350,
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
            _buildBackCard(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: OrderSidebar(
                  key: ValueKey('order_sidebar_main_${widget.order?.id ?? "new"}'),
                  sell: widget.sell,
                  selectedProducts: selectedProducts,
                  callback: () => setState(() {}),
                  order: order,
                  info: info,
                  selectedPerson: selectedPerson,
                  onPersonSelected: _handlePersonSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsPanel() {
    return Expanded(
      child: OrderProductsCard(
        key: ValueKey('order_products_card_${order.id ?? "new"}'),
        selectedProducts: selectedProducts,
        order: order,
        selectedPerson: selectedPerson,
        info: info,
        sell: widget.sell,
        showContent: showContent,
        callback: () {
          setState(() {});
        },
        onPersonSelected: _handlePersonSelected,
      ),
    );
  }

  Widget _buildInvoicePanel(double screenWidth) {
    return SizedBox(
      width: (screenWidth < 1400) ? 350 : 400,
      child: InvoiceScreen(
        key: ValueKey('invoice_screen_${order.id ?? "new"}'),
        order: order,
        selectedProducts: selectedProducts,
        sell: widget.sell,
        info: info,
        callback: () {
          setState(() {});
        },
      ),
    );
  }

  void _handlePersonSelected(Person person) {
    setState(() {
      selectedPerson = person;
      order.personId = person.id ?? 0;
      order.name = person.name;
    });
  }

  Widget _buildBackCard() {
    return OrderBackCard(
      heroTag: widget.sell ? 'sellOrderHero' : 'buyOrderHero',
      title: "${widget.sell ? "Selling Order" : "Buying Order"}${!order.editable ? "" : " (New)"}",
      sell: widget.sell,
      editable: order.editable,
      showDeleteIcon: order.editable && selectedPerson != null,
      wrapInMaterial: true,
      onPressed: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 500));
        widget.callback.call();
      },
    );
  }
}
