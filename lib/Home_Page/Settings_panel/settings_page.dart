import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Home_Page/Settings_panel/backup_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/pagination_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/performance_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/sidebar_settings.dart';
import 'package:inventry_management/Home_Page/Settings_panel/theme_settings.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';

class SettingsPanel extends StatefulWidget {
  final VoidCallback? update;
  const SettingsPanel({super.key,this.update});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  Timer? timer;
  TextEditingController pageSizeController = TextEditingController(
    text: productsPerPage.toString(),
  );
  TextEditingController cardSizeController = TextEditingController(
    text: cardSize.toString(),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topbar(),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
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
                        ThemeSelector(update: widget.update,refresh: () => setState(() {}),),
                        SizedBox(height: 20,),
                        PaginationSettingsWidget(),
                        SizedBox(height: 20,),

                        SidebarSettings(update: widget.update, refresh: () => setState(() {})),

                      ],
                    ),
                    Column(
                      children: [
                        PerformanceSettings(),
                        SizedBox(height: 20,),
                        SizedBox(height: 20,),
                        DataBackup(),
                      ],
                    )

                  ],
                ),
              ),
            ),
          ),
        )
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
