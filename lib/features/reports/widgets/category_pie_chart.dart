import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../shared/constants/app_constants.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<String, double> categorySpending;
  final double totalSpending;

  const CategoryPieChart({
    super.key,
    required this.categorySpending,
    required this.totalSpending,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categorySpending.isEmpty || widget.totalSpending <= 0) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No spending data available',
            style: AppTextStyles.bodyText1,
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _generateSections(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    final sections = <PieChartSectionData>[];
    int index = 0;

    widget.categorySpending.forEach((category, amount) {
      final percentage = (amount / widget.totalSpending) * 100;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 16.0 : 12.0;

      final color = AppConstants.categoryColors[category] ??
          Colors.grey;

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );
      index++;
    });

    return sections;
  }

  Widget _buildLegend() {
    final sortedEntries = widget.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: sortedEntries.map((entry) {
          final percentage = (entry.value / widget.totalSpending) * 100;
          final color = AppConstants.categoryColors[entry.key] ??
              Colors.grey;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
