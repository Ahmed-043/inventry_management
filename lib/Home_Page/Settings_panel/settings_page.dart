import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Home_Page/Settings_panel/backup_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/pagination_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/performance_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/sidebar_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/scalling_settings.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';

class SettingsPanel extends StatefulWidget {
  final VoidCallback? update;
  const SettingsPanel({super.key, this.update});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  TextEditingController pageSizeController = TextEditingController(
    text: productsPerPage.toString(),
  );
  TextEditingController cardSizeController = TextEditingController(
    text: cardSize.toString(),
  );

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isPhone;

    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: _topbar(),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: isPhone ? 40 : 50),
                SizedBox(
                  width: isPhone ? double.infinity : 1050,
                  child: Padding(
                    padding: EdgeInsets.all(isPhone ? 6.0 : 10.0),
                    child: Column(
                      children: [
                        ScalingSettings(),
                        const SizedBox(height: 16),
                        PerformanceSettings(),
                        const SizedBox(height: 16),
                        SidebarSettings(update: widget.update, refresh: () => setState(() {})),
                        const SizedBox(height: 16),
                        PaginationSettingsWidget(),
                        const SizedBox(height: 16),
                        DataBackup(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Developed by NESCO Industries",
              style: MyFont.bold(12, color: MyColors.textMain),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Settings",
              style: MyFont.bold(context.isPhone ? 22 : 30, color: MyColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
