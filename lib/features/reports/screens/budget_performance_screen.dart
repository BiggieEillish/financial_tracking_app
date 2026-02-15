import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database.dart';
import '../bloc/reports_cubit.dart';
import '../bloc/reports_state.dart';
import '../widgets/budget_bar_chart.dart';

class BudgetPerformanceScreen extends StatelessWidget {
  const BudgetPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Performance'),
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
            final performances = _getBudgetPerformances(state);
            final totalBudget = state.totalBudget;
            final totalSpent = state.totalSpent;
            final remaining = totalBudget - totalSpent;
            final performance =
                totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;
            final isOverBudget = totalSpent > totalBudget;

            return RefreshIndicator(
              onRefresh: () => context.read<ReportsCubit>().loadReports(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverallPerformance(totalBudget, totalSpent,
                        remaining, performance, isOverBudget),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBudgetChart(performances),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPerformanceSummary(performances),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBudgetPerformances(performances),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRecommendations(performances),
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

  List<_BudgetPerformance> _getBudgetPerformances(ReportsLoaded state) {
    final performances = <_BudgetPerformance>[];

    for (final budget in state.budgets) {
      final spent = state.categorySpending[budget.category] ?? 0.0;
      final percentage = (spent / budget.limit) * 100;
      final remaining = budget.limit - spent;
      final isOverBudget = spent > budget.limit;

      performances.add(_BudgetPerformance(
        budget: budget,
        spent: spent,
        percentage: percentage,
        remaining: remaining,
        isOverBudget: isOverBudget,
      ));
    }

    performances.sort((a, b) => b.percentage.compareTo(a.percentage));
    return performances;
  }

  Widget _buildOverallPerformance(double totalBudget, double totalSpent,
      double remaining, double performance, bool isOverBudget) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overall Performance', style: AppTextStyles.headline3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? AppConstants.errorColor.withOpacity(0.1)
                        : AppConstants.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Text(
                    '${performance.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: isOverBudget
                          ? AppConstants.errorColor
                          : AppConstants.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    'Total Budget',
                    '${AppConstants.currencySymbol}${totalBudget.toStringAsFixed(2)}',
                    AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPerformanceItem(
                    'Total Spent',
                    '${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(2)}',
                    AppConstants.errorColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPerformanceItem(
                    isOverBudget ? 'Over Budget' : 'Remaining',
                    '${AppConstants.currencySymbol}${remaining.abs().toStringAsFixed(2)}',
                    isOverBudget
                        ? AppConstants.errorColor
                        : AppConstants.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: (performance / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? AppConstants.errorColor
                    : AppConstants.primaryColor,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isOverBudget
                  ? 'You are ${AppConstants.currencySymbol}${remaining.abs().toStringAsFixed(2)} over your total budget'
                  : 'You have ${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)} remaining from your total budget',
              style: AppTextStyles.bodyText2.copyWith(
                color:
                    isOverBudget ? AppConstants.errorColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.bodyText1.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBudgetChart(List<_BudgetPerformance> performances) {
    if (performances.isEmpty) {
      return const SizedBox.shrink();
    }

    final barData = performances
        .map((p) => BudgetBarData(
              category: p.budget.category,
              budgetLimit: p.budget.limit,
              spent: p.spent,
            ))
        .toList();

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
            Text('Budget vs Spending', style: AppTextStyles.headline3),
            const SizedBox(height: AppSpacing.md),
            BudgetBarChart(data: barData),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(List<_BudgetPerformance> performances) {
    if (performances.isEmpty) {
      return Card(
        elevation: AppConstants.defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.assessment, size: 64, color: Colors.grey[400]),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No budgets set',
                style:
                    AppTextStyles.bodyText1.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Create budgets to see performance analysis',
                style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final onTrackCount = performances.where((p) => !p.isOverBudget).length;
    final overBudgetCount = performances.where((p) => p.isOverBudget).length;
    final bestPerforming = performances.last;
    final worstPerforming = performances.first;

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
            Text('Performance Summary', style: AppTextStyles.headline3),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'On Track',
                    '$onTrackCount budgets',
                    Icons.check_circle,
                    AppConstants.successColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSummaryCard(
                    'Over Budget',
                    '$overBudgetCount budgets',
                    Icons.warning,
                    AppConstants.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Best Performing',
                    bestPerforming.budget.category,
                    AppConstants.categoryIcons[
                            bestPerforming.budget.category] ??
                        Icons.star,
                    AppConstants.categoryColors[
                            bestPerforming.budget.category] ??
                        AppConstants.successColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSummaryCard(
                    'Needs Attention',
                    worstPerforming.budget.category,
                    AppConstants.categoryIcons[
                            worstPerforming.budget.category] ??
                        Icons.warning,
                    AppConstants.categoryColors[
                            worstPerforming.budget.category] ??
                        AppConstants.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
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

  Widget _buildBudgetPerformances(List<_BudgetPerformance> performances) {
    if (performances.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget Performance Details', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.md),
        ...performances.map((performance) => _buildPerformanceCard(performance)),
      ],
    );
  }

  Widget _buildPerformanceCard(_BudgetPerformance performance) {
    final color =
        AppConstants.categoryColors[performance.budget.category] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.circular),
                  ),
                  child: Icon(
                    AppConstants.categoryIcons[performance.budget.category] ??
                        Icons.category,
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
                        performance.budget.category,
                        style: AppTextStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${performance.spent.toStringAsFixed(2)} / ${AppConstants.currencySymbol}${performance.budget.limit.toStringAsFixed(2)}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: performance.isOverBudget
                        ? AppConstants.errorColor.withOpacity(0.1)
                        : AppConstants.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Text(
                    '${performance.percentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption.copyWith(
                      color: performance.isOverBudget
                          ? AppConstants.errorColor
                          : AppConstants.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: (performance.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                performance.isOverBudget ? AppConstants.errorColor : color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              performance.isOverBudget
                  ? 'Over budget by ${AppConstants.currencySymbol}${performance.remaining.abs().toStringAsFixed(2)}'
                  : '${AppConstants.currencySymbol}${performance.remaining.toStringAsFixed(2)} remaining',
              style: AppTextStyles.caption.copyWith(
                color: performance.isOverBudget
                    ? AppConstants.errorColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(List<_BudgetPerformance> performances) {
    if (performances.isEmpty) {
      return const SizedBox.shrink();
    }

    final overBudgetCategories =
        performances.where((p) => p.isOverBudget).toList();
    final recommendations = <String>[];

    if (overBudgetCategories.isNotEmpty) {
      recommendations.add(
          'Review spending in ${overBudgetCategories.first.budget.category} - you\'re ${overBudgetCategories.first.percentage.toStringAsFixed(1)}% over budget');
    }

    if (performances.length > 1) {
      final bestPerforming = performances.last;
      recommendations.add(
          'Great job with ${bestPerforming.budget.category} - you\'re ${(100 - bestPerforming.percentage).toStringAsFixed(1)}% under budget');
    }

    if (recommendations.isEmpty) {
      recommendations.add(
          'You\'re doing well! Keep up the good work with your budgeting.');
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
            Row(
              children: [
                Icon(Icons.lightbulb,
                    color: AppConstants.warningColor, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text('Recommendations', style: AppTextStyles.headline3),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...recommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppConstants.successColor, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: AppTextStyles.bodyText2
                              .copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _BudgetPerformance {
  final Budget budget;
  final double spent;
  final double percentage;
  final double remaining;
  final bool isOverBudget;

  _BudgetPerformance({
    required this.budget,
    required this.spent,
    required this.percentage,
    required this.remaining,
    required this.isOverBudget,
  });
}
