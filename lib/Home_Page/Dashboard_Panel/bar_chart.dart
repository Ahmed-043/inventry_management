import 'dart:math' as Math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../Database/dashboard_info.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../charts_smart_steps.dart';
import '../../colors.dart';


class BarChartWidget extends StatelessWidget {
  final List<SalesData> data;
  final String title;

  const BarChartWidget({super.key, required this.data, this.title = ""});

  @override
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    double rawMaxY = data
        .map((e) => e.total.isFinite ? e.total : 0.0)
        .reduce((a, b) => a > b ? a : b);

// target ~5 ticks
    final step = niceStep(rawMaxY == 0 ? 10 : rawMaxY, 5);

// snap maxY to next nice multiple
    final maxY = (rawMaxY <= 0)
        ? step * 5
        : (rawMaxY / step).ceil() * step;
    final interval = maxY / 5;
    return LayoutBuilder(builder: (context, constraints){
      double barWidth = constraints.maxWidth/(data.length * 2);
      if(barWidth > 100){
        barWidth = 100;
      }// safety limits
      return Container(
        padding: const EdgeInsets.only(top: 40),
        width: double.infinity,
        height: double.infinity,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            // ❌ No border
            borderData: FlBorderData(show: false),
            // ❌ No grid
            gridData: FlGridData(show: false),
            // ❌ No top & right titles
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

              // ✅ Left titles width = 30
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: maxY / 5,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: MyFont.semiBold(12, color: MyColors.grey),
                  ),
                ),
              ),

              // ✅ Bottom titles
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) return const SizedBox.shrink();
                    return SizedBox(
                      width: barWidth*1.8,
                      child: Text(
                        data[index].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: MyFont.semiBold(12, color: MyColors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ✅ Bars expanded + spacing = 10
            barGroups: List.generate(data.length, (index) {
              return BarChartGroupData(
                x: index,
                barsSpace: 10,
                barRods: [
                  BarChartRodData(
                    toY: data[index].total.clamp(0, maxY),
                    color: MyColors.info,
                    width: barWidth*1.35, // expanded look (DO NOT use double.infinity)
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${formatAxis(rod.toY)}',
                    MyFont.semiBold(
                      12,
                      color: Colors.white, // ← tooltip text color
                    ),
                  );
                },
              ),
            ),

          ),
        ),
      );
    });
  }

}