import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/constants/app_constants.dart';
import '../bloc/reports_cubit.dart';
import '../bloc/reports_state.dart';
import '../widgets/category_pie_chart.dart';

class CategoryBreakdownScreen extends StatelessWidget {
  const CategoryBreakdownScreen({super.key});

  static const List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'All Time',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Breakdown'),
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
            final categorySpending = state.categorySpending;
            final totalSpending = state.totalSpent;
            final sortedData = categorySpending.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            String topCategory = 'No expenses';
            double topCategoryPercentage = 0.0;
            if (sortedData.isNotEmpty && totalSpending > 0) {
              topCategory = sortedData.first.key;
              topCategoryPercentage =
                  (sortedData.first.value / totalSpending) * 100;
            }

            return RefreshIndicator(
              onRefresh: () => context.read<ReportsCubit>().loadReports(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(context, state),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSummaryCards(totalSpending, topCategory,
                        topCategoryPercentage, categorySpending.length),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCategoryChart(categorySpending, totalSpending),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCategoryList(sortedData, totalSpending),
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

  Widget _buildPeriodSelector(BuildContext context, ReportsLoaded state) {
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
              'Time Period',
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
                value: state.selectedPeriod,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                items: _periods.map((period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<ReportsCubit>().changePeriod(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalSpending, String topCategory,
      double topCategoryPercentage, int categoryCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Spending',
                '${AppConstants.currencySymbol}${totalSpending.toStringAsFixed(2)}',
                Icons.payments,
                AppConstants.errorColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSummaryCard(
                'Categories Used',
                '$categoryCount categories',
                Icons.category,
                AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Top Category',
                topCategory,
                AppConstants.categoryIcons[topCategory] ?? Icons.category,
                AppConstants.categoryColors[topCategory] ??
                    AppConstants.secondaryColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSummaryCard(
                'Top Category %',
                '${topCategoryPercentage.toStringAsFixed(1)}%',
                Icons.pie_chart,
                AppConstants.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
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

  Widget _buildCategoryChart(
      Map<String, double> categorySpending, double totalSpending) {
    if (categorySpending.isEmpty) {
      return Card(
        elevation: AppConstants.defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.pie_chart, size: 64, color: Colors.grey[400]),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No spending data',
                style:
                    AppTextStyles.bodyText1.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add some expenses to see category breakdown',
                style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
            Text('Category Distribution', style: AppTextStyles.headline3),
            const SizedBox(height: AppSpacing.md),
            CategoryPieChart(
              categorySpending: categorySpending,
              totalSpending: totalSpending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(
      List<MapEntry<String, double>> sortedData, double totalSpending) {
    if (sortedData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Details', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.md),
        ...sortedData.map((entry) {
          final percentage = totalSpending > 0
              ? (entry.value / totalSpending) * 100
              : 0.0;
          final color = AppConstants.categoryColors[entry.key] ?? Colors.grey;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.circular),
                    ),
                    child: Icon(
                      AppConstants.categoryIcons[entry.key] ?? Icons.category,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% of total spending',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${entry.value.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyText1.copyWith(
                          color: AppConstants.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
