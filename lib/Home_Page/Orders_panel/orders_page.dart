import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Home_Page/Orders_panel/new_order_button.dart';
import 'package:inventry_management/Home_Page/Orders_panel/order_card.dart';
import 'package:inventry_management/Shared_Widgets/horizontal_scroll.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/Shared_Widgets/topbar.dart';
import 'package:inventry_management/colors.dart';

import '../../Shared_Widgets/app_cursor_overlay.dart';
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
    if (mounted) {
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
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint(e.toString());
        if (mounted) {
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
    return Padding(
      padding: EdgeInsets.only(top:12 ,right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Orders",
                    style: MyFont.bold(24, color: MyColors.textMain),
                  ),
                  const SizedBox(width: 24),
                  actionButtons(),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: HorizontalScroll(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: .end,
                      children: [
                        _filterChip(' All ', 0),
                        const SizedBox(width: 8),
                        _filterChip('Completed', 1),
                        const SizedBox(width: 8),
                        _filterChip('Pending', 2),
                        const SizedBox(width: 8),
                        _filterChip('Cancelled', 3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: MouseRegion(

                    onEnter: (_){
                      isTextCursor = true;
                    },
                    onExit: (_){
                      isTextCursor = false;
                    },
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) {
                        _searchTimer?.cancel();
                        _searchTimer = Timer(const Duration(milliseconds: 500), () {
                          _loadOrders();
                        });
                      },
                      style: MyFont.medium(14, color: MyColors.textMain),
                      decoration: InputDecoration(
                        hintText: 'Search (Order ID, Person, Remarks)',
                        hintStyle: MyFont.medium(14, color: MyColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, color: MyColors.textSecondary, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _typeFilterChip('All', 0),
              const SizedBox(width: 8),
              _typeFilterChip('Sell', 1),
              const SizedBox(width: 8),
              _typeFilterChip('Buy', 2),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selected == 0 || selected == 1)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  "Selling Orders (${sellingOrders.length})",
                                  style: MyFont.bold(18, color: MyColors.textMain),
                                ),
                              ),
                              Expanded(child: viewOrders(sell: true)),
                            ],
                          ),
                        ),
                      if (selected == 0) const SizedBox(width: 24),
                      if (selected == 0 || selected == 2)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  "Buying Orders (${buyingOrders.length})",
                                  style: MyFont.bold(18, color: MyColors.textMain),
                                ),
                              ),
                              Expanded(child: viewOrders(sell: false)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,

                  child: PaginationBar(
                    page: pageNo - 1,
                    pageSize: pageSize,
                    itemCount: sellingOrders.length > buyingOrders.length
                        ? sellingOrders.length
                        : buyingOrders.length,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int index) {
    bool isSelected = selectedIndex == index;
    return ScaledContainer(
      scale: 0.9,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            selectedIndex = index;
            _loadOrders();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? MyColors.sidebarSelected.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: MyColors.sidebarSelected) : Border.all(color: MyColors.textSecondary.withOpacity(0.2)),
          ),
          child: Text(
            label,
            style: MyFont.bold(14, color: isSelected ? MyColors.sidebarSelected : MyColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _typeFilterChip(String label, int index) {
    bool isSelected = selected == index;
    return ScaledContainer(
      scale: 0.9,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            selected = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),

          decoration: BoxDecoration(
            color: isSelected ? MyColors.sidebarSelected : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: MyColors.textSecondary.withOpacity(0.2)),
          ),
          child: Text(
            label,
            style: MyFont.bold(14, color: isSelected ? Colors.white : MyColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget viewOrders({bool sell = true}) {
    return sell
        ? sellingOrders.isEmpty
            ? const Center(child: Text("No Selling Orders"))
            : ListView.builder(
                itemCount: sellingOrders.length,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return OrderCard(
                    order: sellingOrders[index],
                    callBack: () =>
                        _updateOrderById(sellingOrders[index].id ?? 0),
                  );
                },
              )
        : buyingOrders.isEmpty
            ? const Center(child: Text("No Buying Orders"))
            : ListView.builder(
                itemCount: buyingOrders.length,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return OrderCard(
                    order: buyingOrders[index],
                    callBack: () =>
                        _updateOrderById(buyingOrders[index].id ?? 0),
                  );
                },
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
