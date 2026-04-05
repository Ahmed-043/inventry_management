import 'package:flutter/material.dart';

import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';

class ChipData {
  final String title;
  final String prefix;
  final String trendText;
  final double value;
  final double trend;

  const ChipData({
    required this.title,
    this.prefix = '',
    required this.value,
    required this.trend,
    this.trendText = '',
  });
}
class DashboardChipsWidget extends StatefulWidget {
  final List<ChipData> chips;
  final List<bool> current;
  final VoidCallback onChange;
  final VoidCallback onChange1;
  final VoidCallback onChange2;
  final VoidCallback onChange3;
  const DashboardChipsWidget({
    super.key,
    required this.chips,
    required this.current,
    required this.onChange,
    required this.onChange1,
    required this.onChange2,
    required this.onChange3,
  });

  @override
  State<DashboardChipsWidget> createState() => _DashboardChipsWidgetState();
}

class _DashboardChipsWidgetState extends State<DashboardChipsWidget> {
  @override
  Widget build(BuildContext context) {
    final pairCount = (widget.chips.length / 2).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(pairCount, (i) {
          final first = i * 2;
          final second = first + 1;

          return _DashboardChip(
            primary: widget.chips[first],
            alternate: second < widget.chips.length
                ? widget.chips[second]
                : null,
            showAlternate: widget.current[i],
            onToggle: () {
                widget.current[i] = !widget.current[i];
                if(i == 0){
                  widget.onChange.call();
                }
                else if (i == 1){
                  widget.onChange1.call();
                }
                else if(i == 2){
                  widget.onChange2.call();
                }
                else if(i == 3){
                  widget.onChange3.call();
                }

            },
          );
        }),
      ),
    );
  }
}

class _DashboardChip extends StatelessWidget {
  final ChipData primary;
  final ChipData? alternate;
  final bool showAlternate;
  final VoidCallback onToggle;

  const _DashboardChip({
    required this.primary,
    this.alternate,
    required this.showAlternate,
    required this.onToggle,
  });

  ChipData get _active =>
      showAlternate && alternate != null ? alternate! : primary;

  String _format(double n) {
    final v = n.abs();
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final data = _active;

    return Container(
      height: 120,
      width: 270,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: UiHelper.myDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(data.title,
                    style: MyFont.semiBold(18, color: MyColors.grey)),
                Text(
                  '${data.prefix}${_format(data.value)}',
                  style: MyFont.bold(22, color: MyColors.dark),
                ),
                Text(
                  data.trendText,
                  style: MyFont.semiBold(12, color: MyColors.success),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

