import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventry_management/main.dart';

import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';

class PerformanceSettings extends StatefulWidget {
  const PerformanceSettings({super.key});

  @override
  State<PerformanceSettings> createState() => _PerformanceSettingsState();
}

class _PerformanceSettingsState extends State<PerformanceSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'Performance Settings',
            style: MyFont.semiBold(20,color: MyColors.black),
          ),
          const SizedBox(height: 4),
          Text(
            "Optimize the application for speed and efficiency.",
            style: MyFont.semiBold(12,color: MyColors.grey),

          ),
          performanceModeToggle(),
        ],
      ),
    );
  }
  Widget performanceModeToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        'Performance Mode',
        style: MyFont.semiBold(16,color: MyColors.dark),
      ),
      subtitle:  Text(
        'Enable a streamlined experience by reducing visual effects and background processes.',
        style: MyFont.semiBold(12,color: MyColors.grey),
      ),
      trailing: Switch(
        value: performanceMode,
        onChanged: (val) {
          performanceMode = val;
          performanceModeNotifier.value = val;
          SharedPreferences.getInstance().then((prefs) {
            prefs.setBool('performanceMode', performanceMode);
          });
          setState(() {});
        },
        activeColor: Colors.white,
        activeTrackColor: MyColors.primary, // Matches the orange in your image
      ),
    );
  }
}

