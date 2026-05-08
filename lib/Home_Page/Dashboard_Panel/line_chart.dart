import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';
import '../../Database/dashboard_info.dart';
import 'package:inventry_management/charts_smart_steps.dart';

class SalesTrendChart extends StatelessWidget {
  final List<SalesData> data; // recent most first

  const SalesTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final months = data.map((e) => e.label).toList();
    final values = data.map((e) => e.total).toList();

    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i].toDouble()),
    );
    var minY = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    var maxY = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

    final range = (maxY - minY).abs();

    final interval = niceStep(
      (range == 0 ? maxY : range).toDouble(),
      range < maxY * 0.2 ? 4 : 9,
    );
    // align minY and maxY to interval multiples
    minY = (minY / interval).floor() * interval;
    maxY = (maxY / interval).ceil() * interval;

    // safety for identical values
    if (minY == maxY) {
      minY -= interval;
      maxY += interval;
    }

    return LineChart(
      LineChartData(
        // minY: 0, // start from zero
        maxY: (values.isNotEmpty
            ? values.reduce((a, b) => a > b ? a : b) * 1
            : 100),

        gridData: FlGridData(
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: MyColors.lightGrey.withAlpha(150),
              strokeWidth: 1, // solid line
              dashArray: null, // remove dashes
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  formatAxis(value),
                  style: MyFont.semiBold(12, color: MyColors.grey),
                );
              },
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  months[index],
                  style: MyFont.semiBold(12, color: MyColors.grey),
                  textAlign: TextAlign.end,
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => MyColors.grey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                //final index = spot.x.toInt();
                return LineTooltipItem(
                  NumberFormat.decimalPattern().format(spot.y.toInt()),
                  const TextStyle(color: MyColors.translucent),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            //isStepLineChart: true,
            color: MyColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true,color: MyColors.primary.withAlpha(50)),
          ),
        ],
      ),
    );
  }
}
