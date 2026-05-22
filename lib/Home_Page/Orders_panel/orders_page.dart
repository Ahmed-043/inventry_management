import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Home_Page/Orders_panel/new_order_button.dart';
import 'package:inventry_management/Home_Page/Orders_panel/order_card.dart';
import 'package:inventry_management/Shared_Widgets/topbar.dart';
import 'package:inventry_management/colors.dart';

import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/pagination_bar.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Timer? _searchTimer;
  Map<String, List<Map<String, int>>> type = {};
  TextEditingController searchController = TextEditingController();
  int selectedIndex = 0;
  bool isLoading = false;
  int pageNo = 1;
  int pageSize = ordersPerPage ?? 50;
  List<Order> sellingOrders = [];
  List<Order> buyingOrders = [];
  bool compress = false;
  int selected = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadOrders();
  }

  _loadOrders() async {
    if(mounted) {
      setState(() {
      isLoading = true;
    });
    }
    if (currentDB == null) {
      debugPrint("Null DataBase");
      isLoading = false;
      return;
    } else {
      try {
        type = await getOrderCounts(currentDB!);
        sellingOrders.clear();
        buyingOrders.clear();
        sellingOrders = await fetchFilteredOrders(
          currentDB!,
          searchValue: searchController.text,
          selectedIndex: selectedIndex,
          pageNo: pageNo,
          pageSize: pageSize,
          orderType: 1,
        );
        buyingOrders = await fetchFilteredOrders(
          currentDB!,
          searchValue: searchController.text,
          selectedIndex: selectedIndex,
          pageNo: pageNo,
          pageSize: pageSize,
          orderType: 2,
        );
        if(mounted) {
          setState(() {
          isLoading = false;
        });
        }
      } catch (e) {
        debugPrint(e.toString());
        if(mounted) {
          setState(() {
          isLoading = false;
        });
        }
      }
    }
  }
  _updateOrderById(int orderId) async {
    if (currentDB == null) return;

    try {
      // Fetch the updated order from the database
      final updatedOrder = await getOrderById(currentDB!, orderId);
      if (updatedOrder == null) return;

      setState(() {
        // Update in sellingOrders if exists
        final sellIndex = sellingOrders.indexWhere((o) => o.id == orderId);
        if (sellIndex != -1) {
          sellingOrders[sellIndex] = updatedOrder;
          return;
        }

        // Update in buyingOrders if exists
        final buyIndex = buyingOrders.indexWhere((o) => o.id == orderId);
        if (buyIndex != -1) {
          buyingOrders[buyIndex] = updatedOrder;
          return;
        }

        // Optional: if order not in list, you can add it
        // sellingOrders.add(updatedOrder);
      });
    } catch (e) {
      debugPrint("Failed to update order $orderId: $e");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _searchTimer?.cancel();
    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    compress = MediaQuery.of(context).size.width < 1000;
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              topBar(),
              Expanded(
                child: ClipRRect(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.only(top: 5, bottom: 10),
                      width: 1200,
                      // color: MyColors.black,
                      child: compress
                          ? Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: SizedBox(
                                      width: 250,
                                      child: StatefulBuilder(
                                        builder: (context, state) {
                                          return InkWell(
                                            onTap: () {
                                              if (selected == 0) {
                                                selected = 1;
                                              } else {
                                                selected = 0;
                                              }
                                              setState(() {
                                                _loadOrders();
                                              });
                                              debugPrint(selected.toString());
                                            },
                                            hoverColor: MyColors.blue.withAlpha(20),
                                            child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Row(
                                                children: [
                                                  Text(
                                                    (compress && (selected == 1))
                                                        ? "Buying Orders"
                                                        : "Selling Orders",
                                                    style: MyFont.bold(
                                                      30,
                                                      color: MyColors.blue,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_drop_down,
                                                    color: MyColors.blue,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                viewOrders(sell: selected==0),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Selling Orders",
                                        style: MyFont.bold(30, color: MyColors.blue),
                                      ),
                                      viewOrders(sell: true),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        "Buying Orders",
                                        style: MyFont.bold(30, color: MyColors.blue),
                                      ),
                                      viewOrders(sell: false),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,

          child: PaginationBar(
            page: pageNo-1,
            pageSize: pageSize,
            itemCount: sellingOrders.length > buyingOrders.length ? sellingOrders.length : buyingOrders.length,
            onPrevious: () {
              setState(() {
                pageNo--;
                _loadOrders();
              });
            },
            onNext: () {
              setState(() {
                pageNo++;
                _loadOrders();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget viewOrders({bool sell = true}) {
    return Expanded(
      child: sell
          ? sellingOrders.isEmpty
              ? Center(child: Text("No Selling Orders"))
              : ListView.builder(
                  itemCount: sellingOrders.length,
                  clipBehavior: .none,
                  itemBuilder: (context, index) {
                    return OrderCard(
                      order: sellingOrders[index],
                      callBack: () => _updateOrderById(sellingOrders[index].id ?? 0),
                    );
                  },
                )
          : buyingOrders.isEmpty
              ? Center(child: Text("No Buying Orders"))
              : ListView.builder(
                  itemCount: buyingOrders.length,
                  clipBehavior: .none,
                  itemBuilder: (context, index) {
                    return OrderCard(
                      order: buyingOrders[index],
                      callBack: () => _updateOrderById(buyingOrders[index].id ?? 0),
                    );
                  },
                ),
    );
  }

  Widget topBar() {
    return ReusableTopBar(
      title: MediaQuery.of(context).size.width < 1100 ? "" : "Orders",

      searchHint: "Search (Person, OrderID, Remarks)",
      applyBlur: false,
      actionButton: actionButtons(),
      searchController: searchController,
      onSearch: () {
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 500), () {
          _loadOrders();
        });
      },
      onClear: () {
        searchController.clear();
        selectedIndex = 0;
        _loadOrders();
      },
      stockButtons: [
        {'title': 'All', 'count': type['All'] ?? 0},
        {'title': 'Completed', 'count': type['Completed'] ?? 0},
        {'title': 'Pending', 'count': type['Pending'] ?? 0},
        {'title': 'Canceled', 'count': type['Canceled'] ?? 0},
      ],
      selectedIndex: selectedIndex,
      onButtonSelect: (i) {
        setState(() {
          selectedIndex = i;
          _loadOrders();
        });
      },
    );
  }

  Widget actionButtons() {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: SizedBox(
          width: 300,
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: NewOrder.button(
                  context: context,
                  sell: true,
                  callBack: _loadOrders,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: NewOrder.button(
                  context: context,
                  sell: false,
                  callBack: _loadOrders,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
