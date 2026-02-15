import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/services/export_service.dart';
import '../bloc/reports_cubit.dart';
import '../bloc/reports_state.dart';
import '../widgets/export_dialog.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(state.message, style: AppTextStyles.bodyText2),
              ),
            );
          }
          if (state is ReportsLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<ReportsCubit>().loadReports(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(context, state),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSummaryCards(state),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickInsights(state),
                    const SizedBox(height: AppSpacing.lg),
                    _buildReportCategories(context),
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

  void _showExportDialog(BuildContext context) {
    final state = context.read<ReportsCubit>().state;
    if (state is! ReportsLoaded) return;

    showDialog(
      context: context,
      builder: (dialogContext) => ExportDialog(
        onExport: (format, startDate, endDate) async {
          final groups = state.filteredGroups.where((g) {
            return !g.group.date.isBefore(startDate) &&
                !g.group.date.isAfter(endDate);
          }).toList();

          try {
            final exportService = ExportService();
            if (format == 'CSV') {
              final file = await exportService.exportToCSV(groups);
              await exportService.shareFile(file);
            } else {
              final file = await exportService.exportToPDF(groups);
              await exportService.shareFile(file);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export failed: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ReportsLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((period) {
          final isSelected = state.selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (_) {
                context.read<ReportsCubit>().changePeriod(period);
              },
              selectedColor: AppConstants.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              backgroundColor: AppConstants.surfaceColor,
              side: BorderSide(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.borderColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(ReportsLoaded state) {
    final totalSpent = state.totalSpent;
    final totalBudget = state.totalBudget;
    final remaining = totalBudget - totalSpent;
    final averageSpending = state.averageSpending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Spent',
                '${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(2)}',
                Icons.payments_rounded,
                AppConstants.errorColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                'Total Budget',
                '${AppConstants.currencySymbol}${totalBudget.toStringAsFixed(2)}',
                Icons.account_balance_wallet_rounded,
                AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Remaining',
                '${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)}',
                Icons.savings_rounded,
                remaining >= 0
                    ? AppConstants.successColor
                    : AppConstants.warningColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                'Avg. per Expense',
                '${AppConstants.currencySymbol}${averageSpending.toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                AppConstants.secondaryColor,
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.bodyText1.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights(ReportsLoaded state) {
    final totalSpent = state.totalSpent;
    final totalBudget = state.totalBudget;
    final topCategory = state.topCategory ?? 'No expenses';
    final categorySpending = state.categorySpending;
    final expenseCount = state.filteredGroups.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Icon(Icons.lightbulb_rounded,
                      color: AppConstants.accentColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Quick Insights', style: AppTextStyles.headline3),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInsightItem(
              'Total Expenses',
              '$expenseCount transactions',
              Icons.receipt_long_rounded,
            ),
            _buildInsightItem(
              'Top Category',
              topCategory,
              AppConstants.categoryIcons[topCategory] ??
                  Icons.category_rounded,
              color: AppConstants.categoryColors[topCategory],
            ),
            if (totalBudget > 0)
              _buildInsightItem(
                'Budget Usage',
                '${((totalSpent / totalBudget) * 100).toStringAsFixed(1)}%',
                Icons.pie_chart_rounded,
                color: totalSpent > totalBudget
                    ? AppConstants.errorColor
                    : AppConstants.successColor,
              ),
            if (categorySpending.length > 1)
              _buildInsightItem(
                'Categories Used',
                '${categorySpending.length} categories',
                Icons.category_rounded,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon,
              color: color ?? AppConstants.textTertiary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyText2,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyText2.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Reports', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        _buildReportCard(
          'Spending Analytics',
          'View spending trends and patterns over time',
          Icons.trending_up_rounded,
          AppConstants.primaryColor,
          () => context.push('/spending-analytics'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildReportCard(
          'Category Breakdown',
          'See how much you spend in each category',
          Icons.pie_chart_rounded,
          AppConstants.secondaryColor,
          () => context.push('/category-breakdown'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildReportCard(
          'Budget Performance',
          'Compare your spending against your budgets',
          Icons.assessment_rounded,
          AppConstants.accentColor,
          () => context.push('/budget-performance'),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppConstants.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
