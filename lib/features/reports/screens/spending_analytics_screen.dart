import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/models/expense_group_with_items.dart';
import '../bloc/reports_cubit.dart';
import '../bloc/reports_state.dart';
import '../widgets/spending_line_chart.dart';

class SpendingAnalyticsScreen extends StatefulWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  State<SpendingAnalyticsScreen> createState() =>
      _SpendingAnalyticsScreenState();
}

class _SpendingAnalyticsScreenState extends State<SpendingAnalyticsScreen> {
  String _selectedChartType = 'Daily';
  final List<String> _chartTypes = ['Daily', 'Weekly', 'Monthly'];

  Map<String, double> _getSpendingByPeriod(List<ExpenseGroupWithItems> groups) {
    final spendingByPeriod = <String, double>{};

    for (final group in groups) {
      String periodKey;
      final date = group.group.date;

      switch (_selectedChartType) {
        case 'Daily':
          periodKey = '${date.day}/${date.month}';
          break;
        case 'Weekly':
          final weekStart =
              date.subtract(Duration(days: date.weekday - 1));
          periodKey = 'Week ${weekStart.day}/${weekStart.month}';
          break;
        case 'Monthly':
          periodKey = '${date.month}/${date.year}';
          break;
        default:
          periodKey = '${date.day}/${date.month}';
      }

      spendingByPeriod[periodKey] =
          (spendingByPeriod[periodKey] ?? 0.0) + group.totalAmount;
    }

    return spendingByPeriod;
  }

  List<MapEntry<String, double>> _getSortedSpendingData(
      List<ExpenseGroupWithItems> groups) {
    final spendingData = _getSpendingByPeriod(groups);
    final sortedData = spendingData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sortedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ReportsCubit>().loadReports(),
          ),
        ],
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportsError) {
            return Center(child: Text(state.message));
          }
          if (state is ReportsLoaded) {
            final groups = state.filteredGroups;
            final spendingData = _getSortedSpendingData(groups);
            final spendingByPeriod = _getSpendingByPeriod(groups);
            final totalSpending = state.totalSpent;
            final avgSpending = spendingByPeriod.isNotEmpty
                ? totalSpending / spendingByPeriod.length
                : 0.0;
            final maxSpending = spendingByPeriod.isNotEmpty
                ? spendingByPeriod.values.reduce((a, b) => a > b ? a : b)
                : 0.0;
            final highestPeriod = spendingByPeriod.isNotEmpty
                ? spendingByPeriod.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key
                : 'No data';

            return RefreshIndicator(
              onRefresh: () => context.read<ReportsCubit>().loadReports(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChartTypeSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAnalyticsSummary(
                        totalSpending, avgSpending, maxSpending, highestPeriod),
                    const SizedBox(height: AppSpacing.lg),
                    SpendingLineChart(data: spendingData),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSpendingTrends(spendingData),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chart Type',
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedChartType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                items: _chartTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedChartType = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary(double totalSpending, double avgSpending,
      double maxSpending, String highestPeriod) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analytics Summary', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Spending',
                '${AppConstants.currencySymbol}${totalSpending.toStringAsFixed(2)}',
                Icons.payments,
                AppConstants.errorColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildAnalyticsCard(
                'Average per ${_selectedChartType.toLowerCase()}',
                '${AppConstants.currencySymbol}${avgSpending.toStringAsFixed(2)}',
                Icons.trending_up,
                AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Highest ${_selectedChartType.toLowerCase()}',
                '${AppConstants.currencySymbol}${maxSpending.toStringAsFixed(2)}',
                Icons.trending_up,
                AppConstants.warningColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildAnalyticsCard(
                'Peak Period',
                highestPeriod,
                Icons.calendar_today,
                AppConstants.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.bodyText2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrends(List<MapEntry<String, double>> spendingData) {
    if (spendingData.length < 2) {
      return const SizedBox.shrink();
    }

    final recentSpending =
        spendingData.take(3).fold(0.0, (sum, entry) => sum + entry.value);
    final olderSpending = spendingData
        .skip(3)
        .take(3)
        .fold(0.0, (sum, entry) => sum + entry.value);

    final trend = recentSpending > olderSpending ? 'increasing' : 'decreasing';
    final trendPercentage = olderSpending > 0
        ? ((recentSpending - olderSpending) / olderSpending * 100).abs()
        : 0.0;

    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trend == 'increasing'
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: trend == 'increasing'
                      ? AppConstants.errorColor
                      : AppConstants.successColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Spending Trend', style: AppTextStyles.headline3),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your spending is $trend by ${trendPercentage.toStringAsFixed(1)}% compared to previous periods.',
              style: AppTextStyles.bodyText2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              trend == 'increasing'
                  ? 'Consider reviewing your spending habits to stay within budget.'
                  : 'Great job! You\'re spending less than before.',
              style: AppTextStyles.bodyText2.copyWith(
                color: trend == 'increasing'
                    ? AppConstants.errorColor
                    : AppConstants.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
