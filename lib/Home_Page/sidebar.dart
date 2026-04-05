import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/profile.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';
import '../Database/db_info.dart';


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
   // {'title': 'Reports', 'icon': Icons.bar_chart_outlined},
    {'title': 'Settings', 'icon': Icons.settings_outlined},
    {'title': 'Logout', 'icon': Icons.logout},
  ];
  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      width: double.infinity,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        // shape: BoxShape.circle,
                      ),
                      child: widget.collaps ? Image.asset('assets/images/app_logo.png') : Image.asset('assets/images/odventory_logo.png')
                  ),
                  Column(
                    children: List.generate(tiles.length, (index) {
                      return listTile(
                        title: widget.collaps
                            ? null
                            : tiles[index]['title'] as String,
                        icon: tiles[index]['icon'] as IconData,
                        isSelected: widget.selectedIndex == index,
                        callBack: () {
                          widget.onItemSelected(index);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          ?widget.vCollaps ? null :
          widget.info != null ?
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
              child: Container(
                height: 60,
               // width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MyColors.primary,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [

                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipOval(
                        child: widget.info!.image != null
                            ? Image.memory(widget.info!.image!, fit: BoxFit.cover)
                            : const Icon(Icons.person),
                      ),
                    ),
                    ?widget.collaps? null:  const SizedBox(width: 10),
                    ?widget.collaps? null: Expanded(
                      child: Container(
                        height: double.infinity,
                        child: Center(
                          child: Text(
                            widget.info!.dbName,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            maxLines: 2,
                            style: MyFont.bold(16, color: MyColors.translucent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
         :
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.person, color: MyColors.translucent),
            ),
        ],
      ),
    );
  }

  Widget listTile({
    String? title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback callBack,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: callBack,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? MyColors.primary
                : MyColors.grey.withAlpha(0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(icon, color: isSelected ? Colors.white : MyColors.darkBlue),
              const SizedBox(width: 10),
              ?title != null
                  ? Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : MyColors.darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ],
          ),
        ),
      ),
    );
  }
}
