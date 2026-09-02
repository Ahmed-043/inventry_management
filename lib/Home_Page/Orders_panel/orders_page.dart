import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Database/person.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/dialogs/choose_person.dart';
import 'package:inventry_management/Home_Page/Orders_panel/new_order_button.dart';
import 'package:inventry_management/Home_Page/Orders_panel/order_card.dart';
import 'package:inventry_management/Shared_Widgets/date_time.dart';
import 'package:inventry_management/Shared_Widgets/filter_button.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';

import '../../Shared_Widgets/app_cursor_overlay.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../Shared_Widgets/pagination_bar.dart';

class OrdersPage extends StatefulWidget {
  final Person? initialPerson;
  const OrdersPage({super.key, this.initialPerson});

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
  DateTime? startDate, endDate;
  Person? selectedPerson;
  List<Order> sellingOrders = [];
  List<Order> buyingOrders = [];
  bool compress = false;
  int selected = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedPerson = widget.initialPerson;
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
          startDate: startDate,
          endDate: endDate,
          personId: selectedPerson?.id,
        );
        buyingOrders = await fetchFilteredOrders(
          currentDB!,
          searchValue: searchController.text,
          selectedIndex: selectedIndex,
          pageNo: pageNo,
          pageSize: pageSize,
          orderType: 2,
          startDate: startDate,
          endDate: endDate,
          personId: selectedPerson?.id,
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
    double spacing = compress ? 6 : 12;
    return Padding(
      padding: EdgeInsets.only(top:12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Orders",
                style: MyFont.bold(24, color: MyColors.textMain),
              ),
              Row(
                children: [
                  actionButtons(),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_none_rounded, color: MyColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if(compress)
            ...[
              SizedBox(height: spacing),
              Container(
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
            ],
          SizedBox(height: spacing),
          Row(
            children: [
             if(!compress)
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
              SizedBox(width: spacing),

              /// Person Selector Button
              if (selectedPerson != null)
                ScaledContainer(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedPerson = null;
                        _loadOrders();
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: MyColors.sidebarSelected.withAlpha(125)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedPerson!.image != null)
                            ClipOval(
                              child: Image.memory(
                                selectedPerson!.image!,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Icon(Icons.person, size: 28, color: MyColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            selectedPerson!.name,
                            style: MyFont.medium(14, color: MyColors.textMain),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.close, size: 16, color: MyColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ScaledContainer(
                  child: InkWell(
                    onTap: _choosePerson,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_add_alt_1, size: 20, color: MyColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            "Select Person",
                            style: MyFont.medium(14, color: MyColors.textMain),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
               SizedBox(width: spacing),

              ///Filter Buttons
              FilterButton(
                title: 'Status: ${['All', 'Completed', 'Pending', 'Overdue', 'Cancelled'][selectedIndex]}',
                options: const ['All', 'Completed', 'Pending', 'Overdue', 'Cancelled'],
                onSelected: (index) async {
                  setState(() {
                    selectedIndex = index;
                    _loadOrders();
                  });
                },
              ),
               SizedBox(width: spacing),
              FilterButton(
                title: 'Type: ${['All', 'Sell', 'Buy'][selected]}',
                options: const ['All', 'Selling', 'Buying'],
                onSelected: (index) async {
                  setState(() {
                    selected = index;
                    _loadOrders();
                  });
                },
              ),
               SizedBox(width: spacing),
              FilterButton(
                title: 'Date',
                width: 180,
                options: [
                  "Start: ${startDate == null ? 'Not set' : DateFormat('dd MMM yyyy').format(startDate!)}",
                  "End: ${endDate == null ? 'Not set' : DateFormat('dd MMM yyyy').format(endDate!)}",
                ],
                onSelected: (index) async {
                  await _pickDate(index);
                  _loadOrders();
                },
              ),
               SizedBox(width: spacing),
              ScaledContainer(
                scale: 1.2,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      selectedIndex = 0;
                      startDate = null;
                      endDate = null;
                      selectedPerson = null;
                      searchController.clear();
                      _loadOrders();
                    });
                  },
                  child: Text(
                    "Reset Filters",
                    style: MyFont.bold(14, color: MyColors.sidebarSelected),
                  ),
                ),
              ),

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

  Future<void> _choosePerson() async {
    final person = await UiHelper.pushPage<Person?>(
      context: context,
      opaque: false,
      barrierDismissible: true,
      page: Center(
        child: Material(
          color: Colors.transparent,
          child: Hero(
            tag: "person_card",
            child: Container(
              width: 400,
              height: 600,
              decoration: UiHelper.myDecoration(),
              child: ChoosePerson(
                filter: selected == 1 ? 1 : (selected == 2 ? 2 : 0),
                person: selectedPerson,
              ),
            ),
          ),
        ),
      ),
    );

    if (person != null) {
      setState(() {
        selectedPerson = person;
        _loadOrders();
      });
    }
  }

  Future<void> _pickDate(int index) async {
    DateTime initial = (index == 0 ? startDate : endDate) ?? DateTime.now();
    DateTime first = index == 1 && startDate != null ? startDate! : DateTime(1900);
    DateTime last = index == 0 && endDate != null ? endDate! : DateTime(2100);

    DateTime? picked = await pickDate(
      context,
      initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (index == 0) {
          startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        } else {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
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

  Widget actionButtons() {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
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
