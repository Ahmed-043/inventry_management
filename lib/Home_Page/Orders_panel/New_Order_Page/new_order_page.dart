import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/order_sidebar.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/reciept_card.dart';
import 'package:inventry_management/colors.dart';
import 'package:sqflite/sqflite.dart';

import '../../../Database/database.dart';
import '../../../Database/db_info.dart';
import '../../../Database/order_items.dart';
import '../../../Database/orders.dart';
import '../../../Database/person.dart';
import '../../../Shared_Widgets/fonts.dart';
import 'choose_person.dart';

import 'order_products_card.dart';

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
  }
  @override
  Widget build(BuildContext context) {
    debugPrint(selectedPerson?.name);

    bool compress = (MediaQuery.of(context).size.width < 1300);
    return Scaffold(
      backgroundColor: MyColors.lightGrey,
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
          if (MediaQuery.of(context).size.width > 800 || selectedPerson == null)
            SizedBox(
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
                    backCard(),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: OrderSidebar(
                          sell: widget.sell,
                          selectedProducts: selectedProducts,
                          callback: () => setState(() {}),
                          order: order,
                          info: info,
                          selectedPerson: selectedPerson,
                          onPersonSelected: (person) {
                            setState(() {
                              selectedPerson = person;
                              order.personId = person.id ?? 0;
                              order.name = person.name;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (selectedPerson != null)
            Expanded(
              child: OrderProductsCard(
                selectedProducts: selectedProducts,
                order: order,
                selectedPerson: selectedPerson,
                info: info,
                sell: widget.sell,
                showContent: showContent,
                callback: () {
                  setState(() {});
                },
                onPersonSelected: (person) {
                  setState(() {
                    selectedPerson = person;
                    order.personId = person.id ?? 0;
                    order.name = person.name;
                  });
                },
              ),
            ),
          if (!compress && selectedPerson != null)
            SizedBox(
              width: (MediaQuery.of(context).size.width < 1400) ? 350 : 400,
              child: InvoiceScreen(
                order: order,
                selectedProducts: selectedProducts,
                sell: widget.sell,
                info: info,
                callback: () {
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget backCard() {
    return Hero(
      tag: widget.sell ? 'sellOrderHero' : 'buyOrderHero',
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 50,
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          decoration: BoxDecoration(
            color: widget.sell ? MyColors.primary : MyColors.darkBlue,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(125),
                spreadRadius: 0.5,
                blurRadius: 3,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Tooltip(
                message: order.editable
                    ? "Back"
                    : "Order is Confirmed\nYou can safely go Back",
                child: IconButton(
                  hoverColor: Colors.white.withAlpha(50),
                  onPressed: () async {
                    Navigator.pop(context);
                    await Future.delayed(Duration(milliseconds: 500));

                    widget.callback.call();
                  },
                  icon: Icon((order.editable && selectedPerson != null) ? Icons.delete_outline_rounded :Icons.arrow_back, color: MyColors.translucent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${widget.sell ? "Selling Order" : "Receive Order"}${order.editable ? "" : " (Confirmed)"}",
                    overflow: TextOverflow.ellipsis,
                    style: MyFont.semiBold(22, color: MyColors.translucent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void choosePerson() async {
    final result = await showDialog<Person>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 400,
            height: 600,
            decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ChoosePerson(filter: widget.sell ? 1 :2),
          ),
        );
      },
    );

    if (result != null) {
      setState(() => selectedPerson = result);
    }
  }
}
