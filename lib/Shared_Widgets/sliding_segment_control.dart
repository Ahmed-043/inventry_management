import 'package:flutter/cupertino.dart';
import '../Database/orders.dart';
import '../colors.dart';
import 'fonts.dart';
import 'package:flutter/material.dart';

class StatusSegmentedControl extends StatelessWidget {
  final String selected;
  final List<TwoValue> options;
  final ValueChanged<String> onChanged;
  final double fontSize;

  const StatusSegmentedControl({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
    this.fontSize = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOption =
    options.firstWhere((o) => o.first == selected, orElse: () => options[0]);

    return CupertinoSlidingSegmentedControl<String>(
      backgroundColor: Colors.white,
      thumbColor: selectedOption.second is Color
          ? selectedOption.second
          : Colors.grey.shade300,
      groupValue: selected,
      children: {
        for (var option in options)
          option.first: _buildSegmentChild(option, selected == option.first),
      },
      onValueChanged: (String? value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _buildSegmentChild(TwoValue option, bool isSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (option.second is IconData)
          Icon(
            option.second,
            size: fontSize + 2,
            color: isSelected
                ? MyColors.translucent
                : MyColors.black,
          ),
        if (option.second is IconData) const SizedBox(width: 4),
        Text(
          option.first,
          style: MyFont.normal(
            fontSize,
            color: isSelected
                ? MyColors.translucent
                : MyColors.black,
          ),
        ),
      ],
    );
  }
}
