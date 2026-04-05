import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../Database/dashboard_info.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';

class DonutChart extends StatelessWidget {
  final List<SalesData> data;
  final double size;

  const DonutChart({
    super.key,
    required this.data,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, e) => sum + e.total);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = (constraints.maxWidth < constraints.maxHeight
                  ? (constraints.maxWidth)
                  : constraints.maxHeight) / 2;
              return Container(
              height: chartSize,
              width: chartSize,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 4,
                  centerSpaceRadius: chartSize * 0.65,
                  sections: List.generate(data.length, (i) {
                    final percent =
                    total == 0 ? 0 : (data[i].total / total) * 100;
                    return PieChartSectionData(
                      value: data[i].total,
                      color: _colorByIndex(i),
                      radius: chartSize * 0.25,
                      title: percent < 1
                          ? ''
                          : '${percent.toStringAsFixed(0)}%',
                      titleStyle: MyFont.bold(
                        chartSize * 0.085,
                        color: Colors.white,
                      ),
                      showTitle: true,
                    );
                  }),
                ),
              ),
            ) ;
          },
          ),
        ),

        const SizedBox(height: 10),
        // Legend
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            textDirection: TextDirection.rtl, // Add this
            children: List.generate(data.length, (i) {
              return SizedBox(
                width: 100,
                child: _LegendItem(
                  color: _colorByIndex(i),
                  label: data[i].label,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Color _colorByIndex(int index) {
    if (index == 0) return MyColors.success;
    if (index == 1) return MyColors.warning;
    if (index == 2) return MyColors.error;
    return MyColors.lightGrey;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: MyFont.normal(15, color: MyColors.grey),
        ),
      ],
    );
  }
}
