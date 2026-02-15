import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../shared/constants/app_constants.dart';

class BudgetBarData {
  final String category;
  final double budgetLimit;
  final double spent;

  BudgetBarData({
    required this.category,
    required this.budgetLimit,
    required this.spent,
  });

  bool get isOverBudget => spent > budgetLimit;
}

class BudgetBarChart extends StatelessWidget {
  final List<BudgetBarData> data;

  const BudgetBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No budget data available',
            style: AppTextStyles.bodyText1,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final budgetData = data[group.x.toInt()];
                    final isSpent = rodIndex == 1;
                    return BarTooltipItem(
                      isSpent
                          ? 'Spent: ${AppConstants.currencySymbol}${budgetData.spent.toStringAsFixed(2)}'
                          : 'Budget: ${AppConstants.currencySymbol}${budgetData.budgetLimit.toStringAsFixed(2)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Transform.rotate(
                          angle: data.length > 4 ? -0.5 : 0,
                          child: Text(
                            data[index].category,
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: _calculateInterval(),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${AppConstants.currencySymbol}${value.toInt()}',
                        style: AppTextStyles.caption,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateInterval(),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              barGroups: _generateBarGroups(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Budget', AppConstants.primaryColor),
        const SizedBox(width: AppSpacing.lg),
        _buildLegendItem('Spent (Under)', AppConstants.successColor),
        const SizedBox(width: AppSpacing.lg),
        _buildLegendItem('Spent (Over)', AppConstants.errorColor),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(data.length, (index) {
      final budgetData = data[index];
      final spentColor = budgetData.isOverBudget
          ? AppConstants.errorColor
          : AppConstants.successColor;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: budgetData.budgetLimit,
            color: AppConstants.primaryColor,
            width: 12,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: budgetData.spent,
            color: spentColor,
            width: 12,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    double maxValue = 0;
    for (final item in data) {
      final max = item.budgetLimit > item.spent
          ? item.budgetLimit
          : item.spent;
      if (max > maxValue) maxValue = max;
    }
    return maxValue * 1.2; // Add 20% padding
  }

  double _calculateInterval() {
    final maxY = _getMaxY();
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    return 2000;
  }
}
