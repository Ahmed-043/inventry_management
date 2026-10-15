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
    minY = (minY / interval).floor() * interval;
    maxY = (maxY / interval).ceil() * interval;

    if (minY == maxY) {
      minY -= interval;
      maxY += interval;
    }

    final double computedMaxY = (values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b) * 1.05
        : 100.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final neededWidth = data.length * 45.0;
        final chartWidth = neededWidth > (availableWidth - 50)
            ? neededWidth
            : (availableWidth - 50);

        final double xInterval = neededWidth > (availableWidth - 50)
            ? 1.0
            : (data.length > 15 ? 2.0 : 1.0);

        return Row(
          children: [
            // Fixed Left Y-Axis Titles
            SizedBox(
              width: 40,
              child: LineChart(
                LineChartData(
                  minY: minY.toDouble(),
                  maxY: computedMaxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            formatAxis(value),
                            style: MyFont.semiBold(11, color: MyColors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [FlSpot(0, 0)],
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Graph Line & X-Axis Dates
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: chartWidth,
                  child: LineChart(
                    LineChartData(
                      minY: minY.toDouble(),
                      maxY: computedMaxY,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: MyColors.lightGrey.withValues(alpha: 0.6),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: xInterval,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  months[index],
                                  style: MyFont.semiBold(11, color: MyColors.grey),
                                  textAlign: TextAlign.center,
                                ),
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
                          color: MyColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: MyColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
