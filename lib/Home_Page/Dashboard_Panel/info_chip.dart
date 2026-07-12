import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';

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
          if(i>0) {
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
          }
          return SizedBox.shrink();
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
    
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    if (data.title.toLowerCase().contains('purchase') || data.title.toLowerCase().contains('sales') || data.title.toLowerCase().contains('income')) {
      icon = Icons.shopping_cart_outlined;
      iconColor = const Color(0xFF4318FF);
      iconBgColor = const Color(0xFFF4F7FE);
    } else if (data.title.toLowerCase().contains('order')) {
      icon = Icons.access_time_rounded;
      iconColor = const Color(0xFFFFB547);
      iconBgColor = const Color(0xFFFFF8ED);
    } else {
      icon = Icons.warning_amber_rounded;
      iconColor = const Color(0xFF01B574);
      iconBgColor = const Color(0xFFE6FAF5);
    }

    return Container(
      height: 120,
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          hoverColor: MyColors.primary.withOpacity(0.1),
          splashColor: MyColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.title,
                        style: MyFont.medium(14, color: MyColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.prefix}${_format(data.value)} ${data.title.contains('Items') || data.title.contains('Orders') ? (data.value == 1 ? (data.title.contains('Items') ? 'Item' : 'Order') : (data.title.contains('Items') ? 'Items' : 'Orders')) : ''}',
                        style: MyFont.bold(20, color: MyColors.textMain),
                      ),
                      if (data.trendText.isNotEmpty)
                        Text(
                          data.trendText,
                          style: MyFont.medium(12, color: MyColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

