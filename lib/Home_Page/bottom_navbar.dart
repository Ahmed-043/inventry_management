import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/profile.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';
import '../Database/db_info.dart';

class BottomNavPanel extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool collaps;
  final DBInfo? info;

  const BottomNavPanel({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.collaps,
    this.info,
  });

  @override
  State<BottomNavPanel> createState() => _BottomNavPanelState();
}

class _BottomNavPanelState extends State<BottomNavPanel> {
  final tiles = [
    {'title': 'Dashboard', 'icon': Icons.home_rounded},
    {'title': 'Products', 'icon': Icons.inventory_2_outlined},
    {'title': 'Customers', 'icon': Icons.people_alt_outlined},
    {'title': 'Suppliers', 'icon': Icons.local_shipping_outlined},
    {'title': 'Orders', 'icon': Icons.production_quantity_limits_rounded},
    {'title': 'Transactions', 'icon': Icons.mobile_friendly_rounded},
    {'title': 'Settings', 'icon': Icons.settings_outlined},
    {'title': 'Logout', 'icon': Icons.logout},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: MyColors.light,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, -2),
            color: Colors.black.withAlpha(20),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tiles.length, (index) {
                  return navTile(
                    title: widget.collaps
                        ? null
                        : tiles[index]['title'] as String,
                    icon: tiles[index]['icon'] as IconData,
                    isSelected: widget.selectedIndex == index,
                    onTap: () => widget.onItemSelected(index),
                  );
                }),
              ),
            ),
          ),

          if (widget.info != null) profileTile(),
        ],
      ),
    );
  }

  Widget navTile({
    String? title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? MyColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : MyColors.darkBlue),
              if (title != null) ...[
                const SizedBox(width: 6),
                Text(
                  title,
                  style: MyFont.bold(
                    14,
                    color: isSelected ? Colors.white : MyColors.darkBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget profileTile() {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
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
          width: widget.collaps ? 40 : 160,
          height: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: MyColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: .center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipOval(
                  child: widget.info!.image != null
                      ? Image.memory(
                          widget.info!.image!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
              ),
              if (!widget.collaps) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.info!.dbName,
                    overflow: TextOverflow.ellipsis,
                    style: MyFont.bold(14, color: MyColors.translucent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
