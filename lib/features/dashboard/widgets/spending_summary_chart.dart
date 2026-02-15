import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../shared/constants/app_constants.dart';

class SpendingSummaryChart extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const SpendingSummaryChart({
    super.key,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_rounded,
                  size: 36, color: AppConstants.textTertiary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No spending data',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }

    final processedData = _processTopCategories();
    final total = processedData.values.reduce((a, b) => a + b);

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              borderData: FlBorderData(show: false),
              sections: _generateSections(processedData, total),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCompactLegend(processedData, total),
      ],
    );
  }

  Map<String, double> _processTopCategories() {
    if (categoryTotals.length <= 5) {
      return Map.from(categoryTotals);
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = Map.fromEntries(sortedEntries.take(5));

    final otherTotal = sortedEntries
        .skip(5)
        .fold<double>(0, (sum, entry) => sum + entry.value);

    if (otherTotal > 0) {
      top5['Other'] = otherTotal;
    }

    return top5;
  }

  List<PieChartSectionData> _generateSections(
    Map<String, double> data,
    double total,
  ) {
    return data.entries.map((entry) {
      final color = entry.key == 'Other'
          ? AppConstants.textTertiary
          : (AppConstants.categoryColors[entry.key] ?? AppConstants.textTertiary);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 36,
      );
    }).toList();
  }

  Widget _buildCompactLegend(Map<String, double> data, double total) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: data.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = entry.key == 'Other'
            ? AppConstants.textTertiary
            : (AppConstants.categoryColors[entry.key] ?? AppConstants.textTertiary);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${entry.key} ${percentage.toStringAsFixed(0)}%',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
