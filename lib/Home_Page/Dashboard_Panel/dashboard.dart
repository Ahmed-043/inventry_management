import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Home_Page/Dashboard_Panel/stock_alerts.dart';
import 'package:inventry_management/Shared_Widgets/horizontal_scroll.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';

import '../../Database/dashboard_info.dart';
import '../../Database/database.dart';
import '../../Database/db_info.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';
import '../Orders_panel/New_Order_Page/new_order_page.dart';

import '../Transactions_Panels/new_transaction_button.dart';
import '../Transactions_Panels/new_transaction_page.dart';
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
  late double pendingPayment = 0;
  bool compress = false, isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });

    _loadSettings().then((_) {
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

      final start = DateTime(now.year, now.month - 1, now.day);
      chipData = await loadDashboardChipData(
        currentDB!,
        start.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
        msg: 'from last month',
      );

      if (dailySales) {
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
      } else {
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

      lowStockProducts = await getProductsPage(
        currentDB!,
        0,
        productsPerPage ?? 20,
        performanceMode,
        isLowStock: !current[3],
        globalLowStockLimit: lowStockLimit,
        sortMode: 4,
      );

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

        if (dailySales) {
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
        } else {
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
    searchController.dispose();
    pageController.dispose();
    dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isPhone;
    compress = (MediaQuery.of(context).size.height < (lowStockProducts.isNotEmpty ? 650 : 550)) || isPhone;

    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 250,
          child: LinearProgressIndicator(
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(MyColors.primary),
          ),
        ),
      );
    }

    if (isPhone) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _topbarPhone(),
            const SizedBox(height: 4),
            _welcomePhone(),
            const SizedBox(height: 6),
            HorizontalScroll(
              speed: 1.5,
              child: DashboardChipsWidget(
                chips: chipData,
                current: current,
                onChange: () {
                  _saveSettings();
                  loadDashboard();
                },
                onChange1: () {
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
            if (lowStockProducts.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: StockAlerts(
                  lowStockProducts: lowStockProducts,
                  onSave: () {
                    loadAllDashboardData();
                  },
                ),
              ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              height: 280,
              child: lineChart(),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 230,
              child: DonutChart(data: paymentInfo),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 230,
              child: BarChartWidget(data: mostSolds),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 50, child: _topbar()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
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
                                final prevPage = (pageController.page ?? 0).toInt() - 1;
                                if (prevPage >= 0 && !compress) {
                                  pageController.animateToPage(
                                    prevPage,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              }
                              loadDashboard();
                            },
                            onChange1: () {
                              if (!compress) {
                                final nextPage = (pageController.page ?? 0).toInt() + 1;
                                if (nextPage < _totalPages && !compress) {
                                  pageController.animateToPage(
                                    nextPage,
                                    duration: const Duration(milliseconds: 300),
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
                              onSave: () {
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
                                icon: const Icon(Icons.chevron_right_rounded),
                                onPressed: () {
                                  dashboardController.animateToPage(
                                    1,
                                    duration: const Duration(milliseconds: 300),
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

  Widget _topbarPhone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Dashboard",
            style: MyFont.bold(22, color: MyColors.textMain),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_shopping_cart_rounded, color: MyColors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewOrderPage(sell: true, callback: () {}),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: MyColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _welcomePhone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: MyFont.bold(18, color: MyColors.textMain),
              children: [
                const TextSpan(text: "Welcome, "),
                TextSpan(
                  text: "${widget.info?.dbName}!",
                  style: MyFont.bold(18, color: MyColors.sidebarSelected),
                ),
              ],
            ),
          ),
          if (pendingPayment != 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  "Pending: ",
                  style: MyFont.medium(12, color: MyColors.textSecondary),
                ),
                Text(
                  "${pendingPayment < 0 ? '-' : ''}Rs. ${NumberFormat.decimalPattern().format(pendingPayment.abs())}",
                  style: MyFont.bold(14, color: pendingPayment > 0 ? MyColors.success : MyColors.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _topbar() {
    return Row(
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
                    builder: (context) => NewOrderPage(sell: true, callback: () {}),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white, size: 18),
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
                color: MyColors.primary,
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
            pageController.position.pixels + pointerSignal.scrollDelta.dy * 10,
          );
        }
      },
      child: PageView(
        clipBehavior: Clip.hardEdge,
        controller: pageController,
        scrollDirection: Axis.horizontal,
        children: [lineChart(), pieBarCharts()],
      ),
    );
  }

  Widget lineChart() {
    final isPhone = context.isPhone;
    return Container(
      margin: EdgeInsets.only(top: 8, right: isPhone ? 4 : 8, left: isPhone ? 4 : 0),
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 24, vertical: isPhone ? 4 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPhone) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${dailySales ? "Daily" : "Monthly"} ${!current[0] ? 'Sales' : 'Purchase'} Trend",
                  style: MyFont.bold(14, color: MyColors.textMain),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      current[0] = !current[0];
                      _saveSettings();
                      loadDashboard();
                    });
                  },
                  child: Text(
                    'Switch (${current[0] ? 'Sales' : 'Purchase'})',
                    style: MyFont.medium(11, color: MyColors.primary),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "KEY VISUALS",
                  style: MyFont.bold(10, color: MyColors.textSecondary),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                      icon: Icon(Icons.chevron_left_rounded, color: MyColors.textSecondary, size: 20),
                    ),
                    Text(
                      "Last $back ${dailySales ? "d" : "m"}",
                      style: MyFont.medium(11, color: MyColors.textSecondary),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                      icon: Icon(Icons.chevron_right_rounded, color: MyColors.textSecondary, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
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
                      "${dailySales ? "Daily" : "Monthly"} ${!current[0] ? 'Sales' : 'Purchase'} Trend",
                      style: MyFont.bold(20, color: MyColors.textMain),
                    ),
                  ],
                ),
                Column(
                  children: [
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
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        hoverColor: MyColors.textSecondary.withValues(alpha: 0.1),
                        onTap: () {
                          setState(() {
                            current[0] = !current[0];
                            _saveSettings();
                            loadDashboard();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Switch to ${current[0] ? 'Sales' : 'Purchase'} Data',
                            style: MyFont.medium(14, color: MyColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          SizedBox(height: isPhone ? 8 : 24),
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
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              boxShadow: UiHelper.myBoxShadow(),
              border: UiHelper.myBorder(),
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Status Overview",
                  overflow: TextOverflow.ellipsis,
                  style: MyFont.bold(24, color: MyColors.blue),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              boxShadow: UiHelper.myBoxShadow(),
              border: UiHelper.myBorder(),
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
