import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Home_Page/Dashboard_Panel/dashboard.dart';
import 'package:inventry_management/Home_Page/Products_Panel/products_page.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/transactions_page.dart';
import 'package:inventry_management/Signin/sign_page_redesign.dart';
import 'package:inventry_management/colors.dart';
import '../Database/database.dart';
import '../Database/db_info.dart';
import '../Database/person.dart';
import '../Database/backup.dart';
import '../Database/product_stock.dart';
import 'package:inventry_management/Home_Page/Expense_Tracking/expenses_page.dart';
import 'package:inventry_management/Home_Page/Orders_panel/orders_page.dart';
import 'package:inventry_management/Home_Page/Reports_Page/reports_page.dart';
import 'package:inventry_management/Home_Page/Settings_panel/settings_page.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
import 'Customers&Suppliers/persons_page.dart';
import 'mobile_bottom_nav.dart';
import 'logout_panel.dart';
import 'sidebar.dart';

class HomePage extends StatefulWidget {
  final String path; // database path
  final DBInfo? info;

  const HomePage({super.key, required this.path, this.info});

  static HomePageState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomePageState>();

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Person? filterPerson;

  void navigateTo(int index, {Person? person}) {
    setState(() {
      selectedIndex = index;
      filterPerson = person;
    });
  }

  int selectedIndex = !hideDashboard
      ? 0
      : !hideProducts
      ? 1
      : !hideCustomers
      ? 2
      : !hideSuppliers
      ? 3
      : !hideOrders
      ? 4
      : !hideTransactions
      ? 5
      : !hideExpenses
      ? 6
      : !hideReports
      ? 7
      : 8; // Settings (or last item if all others are hidden)

  final FocusNode _focusNode = FocusNode();

  void _handleLogout() {
    stopBackupScheduler();
    stopDailyOpeningStockScheduler();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SigninPageRedsign()),
      (route) => false,
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return Dashboard(info: widget.info);
      case 1:
        return StockDashboard();
      case 2:
        return PersonsPage(key: const ValueKey("customer"), isCustomer: true);
      case 3:
        return PersonsPage(key: const ValueKey("supplier"), isCustomer: false);
      case 4:
        return OrdersPage(
          key: ValueKey("orders_${filterPerson?.id ?? 'all'}"),
          initialPerson: filterPerson,
        );
      case 5:
        return TransactionsPage(
          key: ValueKey("transactions_${filterPerson?.id ?? 'all'}"),
          initialPerson: filterPerson,
        );
      case 6:
        return const ExpensesPage();
      case 7:
        return ReportsPage();
      case 8:
        return Builder(
          builder: (context) => SettingsPanel(
            update: () {
              setState(() {}); // rebuild HomePage
            },
          ),
        );
      case 9:
        return LogoutPanel();
      default:
        return const Center(child: Text("Page Not Found"));
    }
  }

  int get pagesCount => 10;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus(); // ensure focus is set for keyboard events

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (currentDB != null) {
        debugPrint("🏗️ STARTING HOME PAGE MAINTENANCE TASKS");

        try {
          int i = await pushCurrentStockAsOpeningStock(currentDB!);
          debugPrint("✅ Daily Opening Stock Noted: $i");
        } catch (e) {
          debugPrint("❌ Error pushing opening stock: $e");
        }

        startDailyOpeningStockScheduler(currentDB!);

        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && currentDB != null) {
            debugPrint("🚀 STARTING BACKUP SCHEDULER");
            startBackupScheduler(currentDB!);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;
    final isPhone = deviceType == AppDeviceType.phone;
    final isCube = deviceType == AppDeviceType.cube;

    final collapse = isCube || collapseSideBar;
    final collapsed = isPhone;
    final vCollapse = MediaQuery.of(context).size.height < 525;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
      ),
      child: Scaffold(
        backgroundColor: MyColors.mainBg,
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              final focus = FocusManager.instance.primaryFocus;

              if (focus?.context != null &&
                  focus!.context!.findAncestorWidgetOfExactType<EditableText>() != null) {
                return;
              }

              final key = event.logicalKey.keyLabel;
              final index = int.tryParse(key);
              if (index != null && index > 0 && index <= pagesCount) {
                setState(() => selectedIndex = index - 1);
              }
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: isPhone ? MyColors.mainBg : MyColors.sidebarBg,
            child: Stack(
              children: [
                if (!collapsed)
                  Hero(
                    tag: "sidebar",
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: collapse ? 60 : 175,
                        height: double.infinity,
                        child: SidebarPanel(
                          collaps: collapse,
                          selectedIndex: selectedIndex,
                          info: widget.info,
                          onItemSelected: (index) {
                            if (index == pagesCount - 1) {
                              _handleLogout();
                            } else {
                              setState(() {
                                selectedIndex = index % pagesCount;
                                filterPerson = null;
                              });
                            }
                          },
                          vCollaps: vCollapse,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: collapsed ? 0 : (collapse ? 60 : 175),
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: isPhone ? BorderRadius.zero : BorderRadius.circular(25),
                    child: Stack(
                      children: [
                        Hero(
                          tag: "main_page",
                          child: Container(
                            decoration: BoxDecoration(
                              color: MyColors.mainBg,
                              borderRadius: isPhone ? BorderRadius.zero : BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: isPhone ? 0 : 10,
                              right: isPhone ? 0 : 10,
                            ),
                            child: _getPage(selectedIndex),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (collapsed)
                  Align(
                    alignment: .bottomCenter,
                    child: MobileBottomNav(
                      selectedIndex: selectedIndex,
                      info: widget.info,
                      onItemSelected: (index) {
                        if (index == pagesCount - 1) {
                          _handleLogout();
                        } else {
                          setState(() {
                            selectedIndex = index % pagesCount;
                            filterPerson = null;
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
