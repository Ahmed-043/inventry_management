import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../colors.dart';

class SidebarSettings extends StatefulWidget {
  final VoidCallback? update, refresh;
  const SidebarSettings({super.key, this.update, this.refresh});

  @override
  State<SidebarSettings> createState() => _SidebarSettingsState();
}

class _SidebarSettingsState extends State<SidebarSettings> {

  bool _sidebarExpanded = true;
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyColors.translucent,
          border: UiHelper.myBorder(),
          boxShadow: UiHelper.myBoxShadow(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sidebar Settings',
                        style: MyFont.semiBold(20, color: MyColors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Toggle visibility of sidebar items to declutter your workspace.",
                        style: MyFont.semiBold(12, color: MyColors.grey),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  splashRadius: 18,
                  icon: AnimatedRotation(
                    turns: _sidebarExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                  onPressed: () {
                    setState(() {
                      _sidebarExpanded = !_sidebarExpanded;
                    });
                  },
                ),
              ],
            ),

            if (_sidebarExpanded) ...[
              const SizedBox(height: 10),

              UiHelper.switchTile(
                title: 'Dashboard',
                decoration: BoxDecoration(color: MyColors.translucent),
                value: !hideDashboard,
                onChanged: (val) {
                  hideDashboard = !val;
                  _savePref('hideDashboard', !val);
                },
              ),

              UiHelper.switchTile(
                title: 'Products',
                decoration: BoxDecoration(color: MyColors.translucent),
                value: !hideProducts,
                onChanged: (val) {
                  hideProducts = !val;
                  _savePref('hideProducts', !val);
                },
              ),

              UiHelper.switchTile(
                title: 'Customers',
                decoration: BoxDecoration(color: MyColors.translucent),
                value: !hideCustomers,
                onChanged: (val) {
                  hideCustomers = !val;
                  _savePref('hideCustomers', !val);
                },
              ),

              UiHelper.switchTile(
                title: 'Suppliers',
                decoration: BoxDecoration(color: MyColors.translucent),
                value: !hideSuppliers,
                onChanged: (val) {
                  hideSuppliers = !val;
                  _savePref('hideSuppliers', !val);
                },
              ),

              UiHelper.switchTile(
                title: 'Orders',
                decoration: BoxDecoration(color: MyColors.translucent),
                value: !hideOrders,
                onChanged: (val) {
                  hideOrders = !val;
                  _savePref('hideOrders', !val);
                },
              ),

              UiHelper.switchTile(
                title: 'Transactions',
                decoration: BoxDecoration(color: MyColors.translucent),
                value: !hideTransactions,
                onChanged: (val) {
                  hideTransactions = !val;
                  _savePref('hideTransactions', !val);
                },
              ),

              UiHelper.switchTile(
                title: 'Reports',
                decoration: BoxDecoration(color: MyColors.translucent),
                value: !hideReports,
                onChanged: (val) {
                  hideReports = !val;
                  _savePref('hideReports', !val);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }


  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {});
    if (widget.update != null) widget.update!();
    if (widget.refresh != null) widget.refresh!();
  }
}
