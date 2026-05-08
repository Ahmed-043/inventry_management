import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/Dashboard_Panel/dashboard.dart';
import 'package:inventry_management/Home_Page/Products_Panel/products_page.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/transactions_page.dart';
import 'package:inventry_management/Signin/sign_page_redesign.dart';
import 'package:inventry_management/colors.dart';
import '../Database/database.dart';
import '../Database/db_info.dart';
import 'Customers&Suppliers/persons_page.dart';
import 'Orders_panel/orders_page.dart';
import 'Settings_panel/settings_page.dart';
import 'bottom_navbar.dart';
import 'logout_panel.dart';
import 'sidebar.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final String path; // database path
  final DBInfo? info;

  const HomePage({super.key, required this.path,this.info,});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  int selectedIndex = 0; // track sidebar selection here
  final FocusNode _focusNode = FocusNode();

  late final pages = [
    Dashboard(info: widget.info,),
    //Center(child: Text("Stock Page")),
    StockDashboard(),
    //Center(child: Text("Customers Page")),
    PersonsPage(key: ValueKey("customer"),isCustomer: true),
    //Center(child: Text("Suppliers Page")),
    PersonsPage(key: ValueKey("supplier"),isCustomer: false),
    //Center(child: Text("Orders")),
    OrdersPage(),
    //Center(child: Text("Transactions")),
    TransactionsPage(),
   // Center(child: Text("Reports Page")),
   // Center(child: Text("Settings Page")),
    Builder(
      builder: (context) => SettingsPanel(
        update: () {
          print("Updated");
          setState(() {}); // rebuild HomePage
        },
      ),
    ),
    //Center(child: Text("Logout Page")),
    LogoutPanel(),
  ];



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
              if (index != null && index > 0 && index <= pages.length) {
                setState(() => selectedIndex = index - 1);
              }
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: plainUi ? MyColors.lightestGrey : MyColors.light,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if(!collapsed)
                      Container(
                        width: collapse ? 60 : 180,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(
                           // right: BorderSide(color: MyColors.lightGrey,width: 2)
                          )
                        ),
                        child: SidebarPanel(
                          collaps: collapse,
                          selectedIndex: selectedIndex,
                          info: widget.info,
                          onItemSelected: (index) {
                            if(index == pages.length-1){
                              //Navigator.pop(context);
                               Navigator.of(context).pushAndRemoveUntil(
                                 MaterialPageRoute(builder: (_) => SigninPageRedsign()),
                                     (route) => false,
                               );
                            }else {
                              setState(() => selectedIndex = index% pages.length); // to avoid overflow
                            }
                          },
                          vCollaps: vCollapse,
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: pages[selectedIndex],
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
                    if(index == pages.length-1){
                      Navigator.pop(context);
                    }else {
                      setState(() => selectedIndex = index% pages.length); // to avoid overflow
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
