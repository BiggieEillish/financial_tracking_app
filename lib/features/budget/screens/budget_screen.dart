import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database.dart';
import '../bloc/budget_list_cubit.dart';
import '../bloc/budget_list_state.dart';
import '../bloc/budget_alert_cubit.dart';
import '../bloc/budget_alert_state.dart';
import '../widgets/budget_alert_banner.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<BudgetListCubit>().loadBudgets(),
          ),
        ],
      ),
      body: BlocBuilder<BudgetListCubit, BudgetListState>(
        builder: (context, state) {
          if (state is BudgetListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BudgetListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(state.message, style: AppTextStyles.bodyText2),
              ),
            );
          }
          if (state is BudgetListLoaded) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<BudgetListCubit>().loadBudgets(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<BudgetAlertCubit, BudgetAlertState>(
                      builder: (context, alertState) {
                        if (alertState is BudgetAlertLoaded &&
                            alertState.alerts.isNotEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: BudgetAlertBanner(
                                alerts: alertState.alerts),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    _buildBudgetOverview(state),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBudgetCategories(context, state),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickActions(context),
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

  Widget _buildBudgetOverview(BudgetListLoaded state) {
    final totalBudget = state.totalBudget;
    final totalSpent = state.totalSpent;
    final remaining = totalBudget - totalSpent;
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overview', style: AppTextStyles.headline3),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Icon(Icons.pie_chart_rounded,
                      color: AppConstants.primaryColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Budget',
                    '${AppConstants.currencySymbol}${totalBudget.toStringAsFixed(2)}',
                    AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildOverviewItem(
                    'Spent',
                    '${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(2)}',
                    AppConstants.errorColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildOverviewItem(
                    'Left',
                    '${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)}',
                    remaining >= 0
                        ? AppConstants.successColor
                        : AppConstants.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: AppConstants.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 0.9
                      ? AppConstants.errorColor
                      : AppConstants.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}% of budget used',
              style: AppTextStyles.caption.copyWith(
                color: percentage > 0.9
                    ? AppConstants.errorColor
                    : AppConstants.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.bodyText1.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCategories(BuildContext context, BudgetListLoaded state) {
    if (state.budgets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.pie_chart_rounded,
                    size: 48, color: AppConstants.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No budgets set',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Create your first budget to start tracking',
                  style: AppTextStyles.bodyText2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        ...state.budgets
            .map((budget) => _buildBudgetCard(context, budget, state))
            .toList(),
      ],
    );
  }

  Widget _buildBudgetCard(
      BuildContext context, Budget budget, BudgetListLoaded state) {
    final spent = state.getSpentForCategory(budget.category);
    final remaining = budget.limit - spent;
    final percentage = (spent / budget.limit).clamp(0.0, 1.0);
    final isOverBudget = spent > budget.limit;
    final color = AppConstants.categoryColors[budget.category] ??
        AppConstants.textTertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: InkWell(
          onTap: () => context.push('/budget-detail', extra: budget),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
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
                            BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Icon(
                        AppConstants.categoryIcons[budget.category] ??
                            Icons.category_rounded,
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
                            budget.category,
                            style: AppTextStyles.bodyText1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${AppConstants.currencySymbol}${spent.toStringAsFixed(2)} / ${AppConstants.currencySymbol}${budget.limit.toStringAsFixed(2)}',
                            style: AppTextStyles.caption,
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
                        color: isOverBudget
                            ? AppConstants.errorColor.withOpacity(0.08)
                            : AppConstants.successColor.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Text(
                        isOverBudget
                            ? 'Over Budget'
                            : '${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)} left',
                        style: AppTextStyles.caption.copyWith(
                          color: isOverBudget
                              ? AppConstants.errorColor
                              : AppConstants.successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppConstants.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget
                          ? AppConstants.errorColor
                          : AppConstants.primaryColor,
                    ),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}% used',
                  style: AppTextStyles.caption.copyWith(
                    color: isOverBudget
                        ? AppConstants.errorColor
                        : AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Budget',
                Icons.add_chart_rounded,
                AppConstants.primaryColor,
                () async {
                  final result = await context.push('/add-budget');
                  if (result == true) {
                    context.read<BudgetListCubit>().loadBudgets();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildQuickActionCard(
                'View Reports',
                Icons.insights_rounded,
                AppConstants.secondaryColor,
                () => context.go('/?tab=reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.bodyText2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
