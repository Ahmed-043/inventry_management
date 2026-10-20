import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/db_info.dart';
import 'package:inventry_management/Home_Page/Expense_Tracking/add_expense_dialog.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/new_order_page.dart';
import 'package:inventry_management/Home_Page/Products_Panel/add_new_product_panel.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/new_transaction_button.dart';
import 'package:inventry_management/Home_Page/Transactions_Panels/new_transaction_page.dart';
import 'package:inventry_management/Home_Page/profile.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

class MobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final DBInfo? info;

  const MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.info,
  });

  bool _isItemHidden(int index) {
    switch (index) {
      case 0:
        return hideDashboard;
      case 1:
        return hideProducts;
      case 2:
        return hideCustomers;
      case 3:
        return hideSuppliers;
      case 4:
        return hideOrders;
      case 5:
        return hideTransactions;
      case 6:
        return hideExpenses;
      case 7:
        return hideReports;
      case 8:
        return hideSettings;
      default:
        return false;
    }
  }

  void _showQuickActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: MyColors.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "Quick Actions",
                style: MyFont.bold(18, color: MyColors.darkBlue),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (!hideOrders)
                    _actionTile(
                      ctx,
                      icon: Icons.add_shopping_cart_rounded,
                      color: Colors.blue,
                      label: "New Order",
                      onTap: () {
                        Navigator.pop(ctx);
                        UiHelper.pushPage(context: context, page: NewOrderPage(callback: () {}));
                      },
                    ),
                  if (!hideProducts)
                    _actionTile(
                      ctx,
                      icon: Icons.add_box_rounded,
                      color: Colors.green,
                      label: "New Product",
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => const Dialog(
                            backgroundColor: Colors.transparent,
                            child: InputNewProduct(),
                          ),
                        );
                      },
                    ),
                  if (!hideTransactions)
                    _actionTile(
                      ctx,
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.orange,
                      label: "New Transaction",
                      onTap: () {
                        Navigator.pop(ctx);
                        UiHelper.pushPage(
                          context: context,
                          opaque: false,
                          barrierColor: Colors.black54,
                          page: AddNewTransactionDialog(
                            action: NewTransactionDialog(
                              onSave: () {},
                            ),
                          ),
                        );
                      },
                    ),
                  if (!hideExpenses)
                    _actionTile(
                      ctx,
                      icon: Icons.receipt_long_rounded,
                      color: Colors.purple,
                      label: "New Expense",
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => const Dialog(
                            backgroundColor: Colors.transparent,
                            child: AddExpenseDialog(),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: MyFont.medium(11, color: MyColors.darkBlue),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MyColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "All Modules",
                  style: MyFont.bold(18, color: MyColors.darkBlue),
                ),
                const SizedBox(height: 12),
                _menuTile(ctx, 2, "Customers", Icons.people_alt_outlined),
                _menuTile(ctx, 3, "Suppliers", Icons.local_shipping_outlined),
                _menuTile(ctx, 5, "Transactions", Icons.mobile_friendly_rounded),
                _menuTile(ctx, 6, "Expenses", Icons.account_balance_wallet_outlined),
                _menuTile(ctx, 7, "Reports", Icons.bar_chart_outlined),
                _menuTile(ctx, 8, "Settings", Icons.settings_outlined),
                const Divider(height: 24),
                if (info != null)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: MyColors.primary,
                      backgroundImage: info!.image != null ? MemoryImage(info!.image!) : null,
                      child: info!.image == null ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(info!.dbName, style: MyFont.bold(14, color: MyColors.darkBlue)),
                    subtitle: Text("Profile Settings", style: MyFont.medium(12, color: MyColors.grey)),
                    onTap: () {
                      //Navigator.pop(ctx);
                      UiHelper.pushPage(
                        opaque: false,
                          barrierDismissible:  true,
                          context: context, page: ProfileSettings(
                        info: info!,
                        onSave: () {},
                      ));
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text("Logout", style: MyFont.bold(14, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onItemSelected(9);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuTile(BuildContext ctx, int index, String title, IconData icon) {
    if (_isItemHidden(index)) return const SizedBox.shrink();
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? MyColors.primary : MyColors.darkBlue),
      title: Text(
        title,
        style: MyFont.bold(14, color: isSelected ? MyColors.primary : MyColors.darkBlue),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(ctx);
        onItemSelected(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: blurEffects ? 0.65 : 0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left 2 Slots
                if (!_isItemHidden(0))
                  Expanded(child: _navItem(0, Icons.space_dashboard_rounded, "Dashboard")),
                if (!_isItemHidden(1))
                  Expanded(child: _navItem(1, Icons.inventory_2_rounded, "Products")),

                // Center FAB (+)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _showQuickActionSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MyColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MyColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),

                // Right 2 Slots
                if (!_isItemHidden(4))
                  Expanded(child: _navItem(4, Icons.shopping_bag_rounded, "Orders")),
                Expanded(
                  child: InkWell(
                    onTap: () => _showMoreMenu(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_rounded,
                            color: MyColors.grey,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "More",
                            style: MyFont.bold(10, color: MyColors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    if (_isItemHidden(index)) return const SizedBox.shrink();
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? MyColors.primary : MyColors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: MyFont.bold(
                10,
                color: isSelected ? MyColors.primary : MyColors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
