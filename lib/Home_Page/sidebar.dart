import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Home_Page/profile.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/db_info.dart';
import '../Shared_Widgets/app_cursor_overlay.dart';

bool collapseSideBar = false;

class SidebarPanel extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool collaps;
  final bool vCollaps;
  final DBInfo? info;

  const SidebarPanel({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.collaps,
    required this.vCollaps,
    this.info,
  });

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {

  final tiles = [
    {'title': 'Dashboard', 'icon': Icons.home_rounded},
    {'title': 'Products', 'icon': Icons.inventory_2_outlined},
    {'title': 'Customers', 'icon': Icons.people_alt_outlined},
    {'title': 'Suppliers', 'icon': Icons.local_shipping_outlined},
    {'title': 'Orders', 'icon': Icons.production_quantity_limits_rounded},
    {'title': 'Transactions', 'icon': Icons.mobile_friendly_rounded},
    {'title': 'Reports', 'icon': Icons.bar_chart_outlined},
    {'title': 'Settings', 'icon': Icons.settings_outlined},
    {'title': 'Logout', 'icon': Icons.logout},
  ];

  bool _isItemHidden(int index) {
    switch (index) {
      case 0: return hideDashboard;
      case 1: return hideProducts;
      case 2: return hideCustomers;
      case 3: return hideSuppliers;
      case 4: return hideOrders;
      case 5: return hideTransactions;
      case 6: return hideReports;
      case 7: return hideSettings;
      default: return false;
    }
  }
  bool collapseButton = false;

  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.sidebarBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        collapseSideBar = !collapseSideBar;
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool('collapseSidebar', collapseSideBar);
                        widget.onItemSelected(selected);
                      },
                      child: MouseRegion(
                        onEnter: (_){
                          setState(() {
                            collapseButton = true;
                          });
                        },
                        onExit: (_){
                          setState(() {
                            collapseButton = false;
                          });
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18,vertical: 10),
                            width: double.infinity,
                             height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: collapseButton
                                ? Icon(collapseSideBar ? Icons.arrow_forward_ios_outlined : Icons.arrow_back_rounded,color: MyColors.translucent,)
                                : Image.asset(widget.collaps ? 'assets/images/app_logo.png': 'assets/images/odventory_logo.png',
                              color: MyColors.translucent.withOpacity(0.8), alignment: Alignment.center,)
                        ),
                      ),
                    ),
                   // const SizedBox(height: 20),
                    Column(
                      children: [
                        for (int index = 0; index < tiles.length - 1; index++)
                          if (!_isItemHidden(index))
                            listTile(
                              title: widget.collaps
                                  ? null
                                  : tiles[index]['title'] as String,
                              icon: tiles[index]['icon'] as IconData,
                              isSelected: widget.selectedIndex == index,
                              callBack: () {
                                selected = index;
                                widget.onItemSelected(index);
                              },
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                listTile(
                  title: widget.collaps ? null : 'Logout',
                  icon: Icons.logout,
                  isSelected: false,
                  callBack: () {
                    widget.onItemSelected(tiles.length - 1);
                  },
                ),
                const SizedBox(height: 10),
                if (!widget.vCollaps && widget.info != null)
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ProfileSettings(
                            info: widget.info!,
                            onSave: () {
                              Navigator.pop(context);
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.all(widget.collaps ? 4 : 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: MyColors.translucent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          if(widget.info!.image != null)
                            Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: MemoryImage(widget.info!.image!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (!widget.collaps)
                           ...[
                             const SizedBox(width: 10),
                             Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.info!.dbName,
                                    style: MyFont.bold(14, color: MyColors.translucent),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Pro Plan - Active',
                                    style: MyFont.normal(12, color: MyColors.translucent.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            ),]
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget listTile({
    String? title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback callBack,
  }) {
    return ScaledContainer(
      scale: 1.1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.collaps ? 8 : 12, vertical: 6),
        child: MouseRegion(
          onEnter: (_) => isClickable = true,
          onExit: (_) => isClickable = false,
          child: InkWell(
            onTap: callBack,
            hoverColor: MyColors.translucent.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? MyColors.sidebarSelected : MyColors.translucent.withAlpha(0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child:
              (title == null)
               ? Center(
                child: Icon(
                  icon,
                  color: isSelected ? MyColors.translucent : MyColors.translucent.withOpacity(0.6),
                  size: 20,
                ),
              )
              : Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? MyColors.translucent : MyColors.translucent.withOpacity(0.6),
                    size: 20,
                  ),
                  if (title != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: MyFont.semiBold(
                        14,
                        color: isSelected ? MyColors.translucent : MyColors.translucent.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
