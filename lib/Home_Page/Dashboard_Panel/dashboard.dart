import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool dailySales = true;
  
  PageController pageController = PageController();
  PageController dashboardController = PageController();

  final int _totalPages = 2;
  late double pendingPayment;
  bool compress = false, isLoading = false ;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });

    _loadSettings().then((_) {
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
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dashboard_current', current.map((e) => e.toString()).toList());
    await prefs.setInt('dashboard_back', back);
    await prefs.setBool('dashboard_dailySales', dailySales);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrent = prefs.getStringList('dashboard_current');
    if (savedCurrent != null && savedCurrent.length == current.length) {
      current = savedCurrent.map((e) => e == 'true').toList();
    }
    back = prefs.getInt('dashboard_back') ?? 14;
    dailySales = prefs.getBool('dashboard_dailySales') ?? true;
    if (mounted) setState(() {});
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
        isLowStock: !current[3],
        globalLowStockLimit: lowStockLimit,
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
          isLowStock: !current[3],
          globalLowStockLimit: lowStockLimit,
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
                      padding: EdgeInsets.only(left: 10, right: 6,),
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
                                      _saveSettings();
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
                                      _saveSettings();
                                    },
                                    onChange2: () {
                                      _saveSettings();
                                      setState(() {});
                                    },
                                    onChange3: () {
                                      _saveSettings();
                                      loadStockData();
                                      loadDashboard();
                                    },
                                  ),
                                ),
                                if (lowStockProducts.isNotEmpty)
                                  SizedBox(
                                    height: 80,
                                    child: StockAlerts(
                                        lowStockProducts: lowStockProducts,
                                        onSave: (){
                                          loadAllDashboardData();
                                        },
                                    ),
                                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            "Dashboard",
            style: MyFont.bold(24, color: MyColors.textMain),
          ),
          const Spacer(),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              UiHelper.myButton(
                callback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NewOrderPage(sell: true, callback: () {}),
                    ),
                  );
                },
                child: Icon(Icons.add, color: Colors.white, size: 18),
                title: "Create new order",
                textSize: 14,
                filled: true,
                color: MyColors.sidebarSelected,
                borderRadius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              Hero(
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
                  child: Icon(Icons.swap_horiz_rounded, color: MyColors.textMain, size: 18),
                  title: "Record Transaction",
                  textSize: 14,
                  filled: false,
                  color: MyColors.textMain,
                  borderRadius: 10,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_none_rounded, color: MyColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _welcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: MyFont.bold(24, color: MyColors.textMain),
                  children: [
                    const TextSpan(text: "Welcome back, "),
                    TextSpan(
                      text: "${widget.info?.dbName}!",
                      style: MyFont.bold(24, color: MyColors.sidebarSelected),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening with your inventory today.",
                style: MyFont.medium(14, color: MyColors.textSecondary),
              ),
            ],
          ),
          if (pendingPayment != 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Outstanding Balance",
                  style: MyFont.medium(12, color: MyColors.textSecondary),
                ),
                Text(
                  "${pendingPayment < 0 ? '-' : ''}Rs. ${NumberFormat.decimalPattern().format(pendingPayment.abs())}",
                  style: MyFont.bold(20, color: pendingPayment > 0 ? MyColors.success : MyColors.error),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _graphWidget() {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          pageController.position.moveTo(
            pageController.position.pixels +
                pointerSignal.scrollDelta.dy * 10,
          );
        }
      },
      child: PageView(
        clipBehavior: Clip.none,
        controller: pageController,
        scrollDirection: Axis.horizontal,
        children: [lineChart(), pieBarCharts()],
      ),
    );
  }

  Widget lineChart() {
    return Container(
      margin: const EdgeInsets.only(top: 8,right: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "KEY PERFORMANCE VISUALS",
                    style: MyFont.bold(12, color: MyColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${dailySales ? "Daily" : "Monthly"} ${!current[0] ? 'Income' : 'Purchase'} Trend",
                    style: MyFont.bold(20, color: MyColors.textMain),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (back < 30) {
                        back++;
                        _saveSettings();
                        loadDashboard();
                      } else if (dailySales) {
                        dailySales = false;
                        back = 5;
                        _saveSettings();
                        loadDashboard();
                      }
                    },
                    icon: Icon(Icons.chevron_left_rounded, color: MyColors.textSecondary),
                  ),
                  Text(
                    "Last $back ${dailySales ? "Days" : "Months"}",
                    style: MyFont.medium(14, color: MyColors.textSecondary),
                  ),
                  IconButton(
                    onPressed: () {
                      if (back > 5) {
                        back--;
                        _saveSettings();
                        loadDashboard();
                      } else if (!dailySales) {
                        dailySales = true;
                        back = 30;
                        _saveSettings();
                        loadDashboard();
                      }
                    },
                    icon: Icon(Icons.chevron_right_rounded, color: MyColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SalesTrendChart(data: salesData),
          ),
        ],
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
                      "${current[1] ? "Buying" : "Selling"} Orders",
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
