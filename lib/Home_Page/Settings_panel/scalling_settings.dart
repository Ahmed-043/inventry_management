import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Database/database.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
import '../../main.dart';

class ScalingSettings extends StatefulWidget {
  const ScalingSettings({super.key});

  @override
  State<ScalingSettings> createState() => _ScalingSettingsState();
}

class _ScalingSettingsState extends State<ScalingSettings> {
  double _currentScale = uiScale;

  Future<void> _updateScale(double value) async {
    setState(() {
      _currentScale = value;
      uiScale = value;
      uiScaleNotifier.value = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('uiScale', value);
  }

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
          Text('UI Scaling', style: MyFont.semiBold(20, color: MyColors.black)),
          const SizedBox(height: 4),
          Text(
            "Adjust the overall size of the user interface elements.",
            style: MyFont.semiBold(12, color: MyColors.grey),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scale: ${(_currentScale * 100).toInt()}%',
                style: MyFont.semiBold(16, color: MyColors.black),
              ),
              UiHelper.myButton(
                callback: () => _updateScale(1.0),
                filled: false,
                borderRadius: 8,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: MyColors.primary,
                child: Text('Reset to 100%', style: MyFont.normal(12, color: MyColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MyColors.primary,
              inactiveTrackColor: MyColors.lightGrey,
              thumbColor: MyColors.primary,
              overlayColor: MyColors.primary.withAlpha(32),
              valueIndicatorColor: MyColors.primary,
              valueIndicatorTextStyle: MyFont.normal(12, color: Colors.white),
            ),
            child: Slider(
              value: _currentScale,
              min: 0.5,
              max: 1.25,
              divisions: 15,
              label: '${(_currentScale * 100).toInt()}%',
              onChanged: (value) {
                setState(() {
                  _currentScale = value;
                  uiScale = value;
                });
              },
              onChangeEnd: (value) {
                _updateScale(value);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('50%', style: MyFont.normal(12, color: MyColors.grey)),
              SizedBox(width: 25),
              Text('100%', style: MyFont.normal(12, color: MyColors.grey)),
              Text('125%', style: MyFont.normal(12, color: MyColors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MyColors.light,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MyColors.warning.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: MyColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changes are applied immediately. Some elements might require a page navigation to refresh completely.',
                    style: MyFont.normal(12, color: MyColors.dark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
