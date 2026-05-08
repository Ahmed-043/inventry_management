import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Home_Page/Dashboard_Panel/stock_alerts.dart';
import 'package:inventry_management/Shared_Widgets/horizontal_scroll.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../Database/dashboard_info.dart';
import '../../Database/database.dart';
import '../../Database/db_info.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';
import '../Orders_panel/New_Order_Page/new_order_page.dart';

import '../Transactions_Panels/new_transaction_button.dart';
import '../Transactions_Panels/new_transaction_page.dart';
import '../profile.dart';
import 'bar_chart.dart';
import 'donut_chart.dart';
import 'info_chip.dart';
import 'line_chart.dart';

class Dashboard extends StatefulWidget {
  final DBInfo? info;

  const Dashboard({super.key, this.info});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  TextEditingController searchController = TextEditingController();
  List<ChipData> chipData = [];
  List<bool> current = [false, false, false, false];
  List<Product> lowStockProducts = [];
  List<SalesData> salesData = [], paymentInfo = [], mostSolds = [];
  int back = 14;
  PageController pageController = PageController();
  PageController dashboardController = PageController();

  final int _totalPages = 2;
  late double pendingPayment;
  bool compress = false, isLoading = false, dailySales = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });

    // Defer heavy database work until after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.endOfFrame.then((_) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          loadAllDashboardData();
        });
      });
    });
  }

  Future<void> loadAllDashboardData() async {
    if (currentDB == null) return;

    try {
      final now = DateTime.now();

      // -------- Dashboard chips + sales --------
      final start = DateTime(now.year, now.month - 1, now.day);
      chipData = await loadDashboardChipData(
        currentDB!,
        start.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
        msg: 'from last month',
      );

      if(dailySales){
        final past = DateTime(
          now.year,
          now.month,
          now.day - back,
          now.hour,
          now.minute,
          now.second,
        );
        salesData = await getDailyPayments(
          db: currentDB!,
          startTimestamp: past.millisecondsSinceEpoch,
          endTimestamp: now.millisecondsSinceEpoch,
          positiveOnly: !current[0],
        );
      }
      else{
        final past = DateTime(
          now.year,
          now.month - back,
          now.day,
          now.hour,
          now.minute,
          now.second,
        );
        salesData = await getMonthlyPayments(
          db: currentDB!,
          positiveOnly: !current[0],
          startTimestamp: past.millisecondsSinceEpoch,
          endTimestamp: now.millisecondsSinceEpoch,
        );
      }

      mostSolds = await getTop10MostSold(currentDB!);

      // -------- Stock data --------
      lowStockProducts = await getProductsPage(
        currentDB!,
        0,
        productsPerPage ?? 20,
        performanceMode,
        upperLimit: current[3] ? 0 : lowStockLimit-1,
        lowerLimit: current[3] ? 0 : 1,
        sortMode: 4,
      );

      // -------- Order / payment data --------
      paymentInfo = await getOrderStatusSalesData(
        currentDB!,
        sale: !current[1],
      );

      pendingPayment = await getTotalUnpaidAmount(currentDB!);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error Dashboard ${e.toString()}');
    }
  }


  void loadDashboard() async {
    try {
      if (currentDB != null) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month - 1, now.day);
        final end = now;
        chipData = await loadDashboardChipData(
          currentDB!,
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
          msg: 'from last month',
        );


        if(dailySales){
          final past = DateTime(
            now.year,
            now.month,
            now.day - back,
            now.hour,
            now.minute,
            now.second,
          );
          salesData = await getDailyPayments(
            db: currentDB!,
            startTimestamp: past.millisecondsSinceEpoch,
            endTimestamp: now.millisecondsSinceEpoch,
            positiveOnly: !current[0],
          );
        }
        else{
          final past = DateTime(
            now.year,
            now.month - back,
            now.day,
            now.hour,
            now.minute,
            now.second,
          );
          salesData = await getMonthlyPayments(
            db: currentDB!,
            positiveOnly: !current[0],
            startTimestamp: past.millisecondsSinceEpoch,
            endTimestamp: now.millisecondsSinceEpoch,
          );
        }
        mostSolds = await getTop10MostSold(currentDB!);
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error DashBoard ${e.toString()}");
    }
  }

  void loadStockData() async {
    try {
      if (currentDB != null) {
        lowStockProducts = await getProductsPage(
          currentDB!,
          0,
          productsPerPage ?? 20,
          performanceMode,
          upperLimit: current[3] ? 0 : lowStockLimit-1,
          lowerLimit: current[3] ? 0 : 1,
          sortMode: 4,
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error DashBoard ${e.toString()}");
    }
  }

  void loadOrderData() async {
    try {
      if (currentDB != null) {
        paymentInfo = await getOrderStatusSalesData(
          currentDB!,
          sale: !current[1],
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error DashBoard ${e.toString()}");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    searchController.dispose();
    pageController.dispose();
    dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    compress =
        (MediaQuery.of(context).size.height <
        (lowStockProducts.isNotEmpty ? 650 : 550));
    return isLoading
        ? Center(
          child: SizedBox(
            width: 300,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(MyColors.primary),
                );
              },
            ),
          ),
    )
        : SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: 50, child: _topbar()),
                //Divider(thickness: 2, height: 5, color: MyColors.lightGrey),
                if (!isLoading)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            dashboardController.position.moveTo(
                              dashboardController.position.pixels +
                                  pointerSignal.scrollDelta.dy * 10,
                            );
                          }
                        },
                        child: PageView(
                          controller: dashboardController,
                          scrollDirection: Axis.horizontal,
                          children: [
                            Column(
                              children: [
                                _welcome(),
                                HorizontalScroll(
                                  speed: 1.5,
                                  child: DashboardChipsWidget(
                                    chips: chipData,
                                    current: current,
                                    onChange: () {
                                      if (!compress) {
                                        final prevPage =
                                            (pageController.page ?? 0).toInt() -
                                            1;
                                        if (prevPage >= 0 && !compress) {
                                          pageController.animateToPage(
                                            prevPage,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      }
                                      loadDashboard();
                                    },
                                    onChange1: () {
                                      if (!compress) {
                                        final nextPage =
                                            (pageController.page ?? 0).toInt() +
                                            1;
                                        if (nextPage < _totalPages && !compress) {
                                          pageController.animateToPage(
                                            nextPage,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      }
                                      loadOrderData();
                                    },
                                    onChange2: () {

                                      setState(() {});
                                    },
                                    onChange3: () {
                                      loadStockData();
                                      loadDashboard();
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
                                if (lowStockProducts.isNotEmpty)
                                  StockAlerts(
                                      lowStockProducts: lowStockProducts,
                                      onSave: (){
                                        loadAllDashboardData();
                                      },
                                  ),
                                if (lowStockProducts.isNotEmpty)
                                  SizedBox(height: 20),
                                if (!compress) Expanded(child: _graphWidget()),
                                if (compress)
                                  Expanded(
                                    child: Center(
                                      child: IconButton(
                                        iconSize: 50,
                                        icon: Icon(Icons.chevron_right_rounded),
                                        onPressed: () {
                                          dashboardController.animateToPage(
                                            1,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (compress) lineChart(),
                            if (compress) pieBarCharts(),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
  }

  Widget _topbar() {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Dashboard",
            style: MyFont.bold(30, color: MyColors.blue),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.only(top: 5, right: 10),
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_none_rounded),
                  ),
                  SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(

                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ProfileSettings(
                            info: widget.info!, // Pass your DBInfo object here
                            onSave: () {
                              // Add your database update logic here
                              Navigator.pop(context); // Close dialog after saving
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipOval(
                        child: widget.info!.image != null
                            ? Image.memory(widget.info!.image!, fit: BoxFit.cover)
                            : const Icon(Icons.person),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _welcome() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth > 800; // adjust breakpoint as needed

          if (isWide) {
            // Wide: Row layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Welcome back, ${widget.info?.dbName}!",
                  style: MyFont.bold(24, color: MyColors.blue),
                ),
                if(pendingPayment != 0)
                Tooltip(
                  waitDuration: const Duration(milliseconds: 500),
                  message: pendingPayment > 0 ? 'Pending Receivable' : 'Pending Payable',
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Text( "Rs. ${NumberFormat.decimalPattern().format(pendingPayment)}",
                        textAlign: TextAlign.center,
                        style: MyFont.bold(
                          20,
                          color: pendingPayment > 0 ? MyColors.success :  MyColors.error,
                        ),
                      ),
                      Icon(
                        pendingPayment > 0 ? Icons.keyboard_double_arrow_up_rounded : Icons.keyboard_double_arrow_down_rounded,
                        size: 20,
                        color: pendingPayment > 0 ? MyColors.success : MyColors.error,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      height: 40,
                      child: UiHelper.myButton(
                        callback: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NewOrderPage(sell: true, callback: () {}),
                            ),
                          );
                        },
                        rightClick: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NewOrderPage(sell: false, callback: () {}),
                            ),
                          );
                        },
                        child: Icon(Icons.add, color: MyColors.translucent),
                        title: "Create new order",
                        textSize: 17,
                        filled: true,
                        borderRadius: 10,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 200,
                      height: 40,
                      child: Hero(
                        tag: 'newTransaction',
                        child: UiHelper.myButton(
                          callback: () {
                            UiHelper.pushPage(
                              context: context,
                              opaque: false,
                              barrierColor: Colors.black54,
                              page: AddNewTransactionDialog(
                                action: NewTransactionDialog(
                                  onSave: () {
                                    loadDashboard();
                                  },
                                ),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.attach_money_rounded,
                            color: MyColors.primary,
                          ),
                          title: "Record Transaction",
                          textSize: 17,
                          filled: false,
                          borderRadius: 10,
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Narrow: Column layout
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: .center,
                  children: [
                    Text(
                      "Welcome back, ${widget.info?.dbName}!",
                      style: MyFont.bold(24, color: MyColors.blue),
                    ),
                    if(pendingPayment != 0)
                      Tooltip(
                        waitDuration: const Duration(milliseconds: 500),
                        message: pendingPayment > 0 ? 'Pending Receivable' : 'Pending Payable',
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            Text( "Rs. ${NumberFormat.decimalPattern().format(pendingPayment)}",
                              textAlign: TextAlign.center,
                              style: MyFont.bold(
                                20,
                                color: pendingPayment > 0 ? MyColors.success :  MyColors.error,
                              ),
                            ),
                            Icon(
                              pendingPayment > 0 ? Icons.keyboard_double_arrow_up_rounded : Icons.keyboard_double_arrow_down_rounded,
                              size: 20,
                              color: pendingPayment > 0 ? MyColors.success : MyColors.error,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 40,
                      child: UiHelper.myButton(
                        callback: () {},
                        child: Icon(Icons.add, color: MyColors.translucent),
                        title: "Create new order",
                        textSize: 17,
                        filled: true,
                        borderRadius: 10,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 40,
                      child: Hero(
                        tag: 'newTransaction',
                        child: UiHelper.myButton(
                          callback: () {
                            UiHelper.pushPage(
                              context: context,
                              opaque: false,
                              barrierColor: Colors.black54,
                              page: AddNewTransactionDialog(
                                action: NewTransactionDialog(
                                  onSave: () {
                                    loadDashboard();
                                  },
                                ),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.attach_money_rounded,
                            color: MyColors.primary,
                          ),
                          title: "Record Transaction",
                          textSize: 17,
                          filled: false,
                          borderRadius: 10,
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _graphWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            pageController.position.moveTo(
              pageController.position.pixels +
                  pointerSignal.scrollDelta.dy * 10,
            );
          }
        },
        child: PageView(
          controller: pageController,
          scrollDirection: Axis.horizontal,
          children: [lineChart(), pieBarCharts()],
        ),
      ),
    );
  }

  Widget lineChart() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        boxShadow: UiHelper.myBoxShadow(),
        border: UiHelper.myBorder(),
        color: MyColors.translucent,
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      // height: 400,
      child: SizedBox(
        child: Column(
          crossAxisAlignment: .start,
          mainAxisAlignment: .center,
          children: [
            Row(
              children: [
                Text(
                  "Key Performance Visuals",
                  style: MyFont.bold(24, color: MyColors.blue),
                ),
                SizedBox(
                  height: 35,
                  child: IconButton(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                      onPressed: (){
                    setState(() {
                      dailySales = !dailySales;
                      loadDashboard();
                    });
                  }, icon: Text("${dailySales ? "Daily" : "Monthly "} ${!current[0] ? 'Income' : 'Purchase'}",
                    style: MyFont.bold(24, color: MyColors.blue),)),
                )
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: .start,
              children: [
                Text(
                  "${!current[0] ? 'Income' : 'Purchase'} Trend Last $back ${dailySales ? "Days" : "Months "}",
                  style: MyFont.bold(16, color: MyColors.blue),
                ),
                SizedBox(
                  height: 25,
                  child: IconButton(
                    onPressed: () {
                      if (back < 30) {
                        back++;
                        loadDashboard();
                      }else{
                        if(dailySales){
                          dailySales = !dailySales;
                          back = 5;
                          loadDashboard();
                        }
                      }
                    },
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: MyColors.blue,
                    ),
                  ),
                ),
                SizedBox(
                  height: 25,
                  child: IconButton(
                    onPressed: () {
                      if (back > 5) {
                        back--;
                        loadDashboard();
                      }else{
                        if(!dailySales){
                          dailySales = !dailySales;
                          back = 30;
                          loadDashboard();
                        }
                      }
                    },
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: MyColors.blue,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SalesTrendChart(data: salesData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget pieBarCharts() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              boxShadow: UiHelper.myBoxShadow(),
              border: UiHelper.myBorder(),
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  "Order Status Overview",
                  overflow: TextOverflow.ellipsis,
                  style: MyFont.bold(24, color: MyColors.blue),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: .start,
                  children: [
                    Text(
                      "${current[1] ? "Selling" : "Buying"} Orders",
                      style: MyFont.bold(16, color: MyColors.blue),
                    ),
                  ],
                ),
                Expanded(child: DonutChart(data: paymentInfo)),
              ],
            ),
          ),
        ),

        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              boxShadow: UiHelper.myBoxShadow(),
              border: UiHelper.myBorder(),
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  "Most Selling Items",
                  overflow: TextOverflow.ellipsis,
                  style: MyFont.bold(24, color: MyColors.blue),
                ),

                Expanded(child: BarChartWidget(data: mostSolds)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
