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
          if (!performanceMode) ...[
            UiHelper.switchTile(
              title: 'Cursor Overlay',
              subtitle: 'Enable custom cursor and trail effects.',
              value: cursorOverlay,
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onChanged: (val) {
                cursorOverlay = val;
                cursorOverlayNotifier.value = val;
                _saveSetting('cursorOverlay', val);
                setState(() {});
              },
            ),
            UiHelper.switchTile(
              title: 'Blur Effects',
              subtitle: 'Enable background blur effects for dialogs and transitions.',
              value: blurEffects,
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onChanged: (val) {
                blurEffects = val;
                blurEffectsNotifier.value = val;
                _saveSetting('blurEffects', val);
                setState(() {});
              },
            ),
          ],
          UiHelper.switchTile(
            title: 'Performance Mode',
            subtitle: 'Enable a streamlined experience by reducing visual effects and background processes.',
            value: performanceMode,
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onChanged: (val) {
              performanceMode = val;
              performanceModeNotifier.value = val;
              if (val) {
                cursorOverlay = false;
                blurEffects = false;
                cursorOverlayNotifier.value = false;
                blurEffectsNotifier.value = false;
              } else {
                cursorOverlay = true;
                blurEffects = true;
                cursorOverlayNotifier.value = true;
                blurEffectsNotifier.value = true;
              }
              _savePerformanceSettings();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void _saveSetting(String key, bool value) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(key, value);
    });
  }

  void _savePerformanceSettings() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('performanceMode', performanceMode);
      prefs.setBool('cursorOverlay', cursorOverlay);
      prefs.setBool('blurEffects', blurEffects);
    });
  }
}

