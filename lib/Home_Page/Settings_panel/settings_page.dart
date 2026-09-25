import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Home_Page/Settings_panel/backup_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/pagination_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/performance_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/sidebar_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/scalling_settings.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';

class SettingsPanel extends StatefulWidget {
  final VoidCallback? update;
  const SettingsPanel({super.key,this.update});

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
    return Stack(
      children: [
        Align(
            alignment: Alignment.topLeft,
            child: _topbar()),
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(
              children: [SizedBox(height: 50,),
                SizedBox(
                  width: 1050,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        Column(
                          children: [
                            // ThemeSelector(update: widget.update,refresh: () => setState(() {}),),
                            // SizedBox(height: 20,),
                            ScalingSettings(),
                            SizedBox(height: 20,),
                            PerformanceSettings(),
                            SizedBox(height: 20,),
                            SidebarSettings(update: widget.update, refresh: () => setState(() {})),
                          ],
                        ),
                        Column(
                          children: [
                            PaginationSettingsWidget(),
                            SizedBox(height: 20,),
                            DataBackup(),
                          ],
                        )

                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                )
              ],
            ),
          ),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: Text("Developed by NESCO Industries", style: MyFont.bold(14, color: MyColors.textMain))),

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
              style: MyFont.bold(30, color: MyColors.blue),
            ),
          ),
          Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }

}
