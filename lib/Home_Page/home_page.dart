import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/Dashboard_Panel/dashboard.dart';
import 'package:inventry_management/Home_Page/Products_Panel/products_page.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/transactions_page.dart';
import 'package:inventry_management/Signin/sign_page_redesign.dart';
import 'package:inventry_management/colors.dart';
import '../Database/database.dart';
import '../Database/db_info.dart';
import '../Database/person.dart';
import 'Customers&Suppliers/persons_page.dart';
import 'Orders_panel/orders_page.dart';
import 'Reports_Page/reports_page.dart';
import 'Settings_panel/settings_page.dart';
import 'bottom_navbar.dart';
import 'logout_panel.dart';
import 'sidebar.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final String path; // database path
  final DBInfo? info;

  const HomePage({super.key, required this.path,this.info,});

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
      : !hideReports
      ? 6
      : 7; // Settings (or last item if all others are hidden)

    final FocusNode _focusNode = FocusNode();

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
        return ReportsPage();
      case 7:
        return Builder(
          builder: (context) => SettingsPanel(
            update: () {
              print("Updated");
              setState(() {}); // rebuild HomePage
            },
          ),
        );
      case 8:
        return LogoutPanel();
      default:
        return const Center(child: Text("Page Not Found"));
    }
  }

  int get pagesCount => 9;



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _focusNode.requestFocus(); // ensure focus is set for keyboard events
  }
  @override
  Widget build(BuildContext context) {
    bool collapse = MediaQuery.of(context).size.width < 800;
    bool collapsed = MediaQuery.of(context).size.width < 500;
    bool vCollapse = MediaQuery.of(context).size.height < 525;

    return MediaQuery(
      // 👇 removes system insets (status bar, notch, etc.)
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
              // Skip if typing in a TextField or any editable field
              final focus = FocusManager.instance.primaryFocus;

              if (focus?.context != null &&
                  focus!.context!.findAncestorWidgetOfExactType<EditableText>() != null) {
                return;
              }

              final key = event.logicalKey.keyLabel; // "1", "2", "3", ...
              final index = int.tryParse(key);
              if (index != null && index > 0 && index <= pagesCount) {
                setState(() => selectedIndex = index - 1);
              }
            }
          },
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            //color: plainUi ? MyColors.lightestGrey : MyColors.light,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if(!collapsed)
                      Align(
                        alignment: .topLeft,
                        child: SizedBox(
                          width: collapse || collapseSideBar ? 60 : 175,
                          height: double.infinity,
                          child: SidebarPanel(
                            collaps: collapse || collapseSideBar,
                            selectedIndex: selectedIndex,
                            info: widget.info,
                            onItemSelected: (index) {
                              if(index == pagesCount-1){
                                //Navigator.pop(context);
                                 Navigator.of(context).pushAndRemoveUntil(
                                   MaterialPageRoute(builder: (_) => SigninPageRedsign()),
                                       (route) => false,
                                 );
                              }else {
                                setState(() {
                                  selectedIndex = index % pagesCount;
                                  filterPerson = null; // reset filter on manual switch
                                });
                              }
                            },
                            vCollaps: vCollapse,
                          ),
                        ),
                      ),

                      Positioned(
                        left: collapsed ? 0 : ( collapse ? 60 : collapseSideBar ? 80 : 200),
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: _getPage(selectedIndex),
                      ),
                    ],
                  ),
                ),
                if(collapsed)
                BottomNavPanel(
                  collaps: collapse,
                  selectedIndex: selectedIndex,
                  info: widget.info,
                  onItemSelected: (index) {
                    if(index == pagesCount-1){
                      Navigator.pop(context);
                    }else {
                      setState(() {
                        selectedIndex = index % pagesCount;
                        filterPerson = null; // reset filter on manual switch
                      });
                    }
                  },
                  //vCollaps: vCollapse,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
