import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/spending_summary_chart.dart';
import '../../budget/bloc/budget_alert_cubit.dart';
import '../../budget/bloc/budget_alert_state.dart';
import '../../budget/widgets/budget_alert_banner.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<DashboardCubit>().loadDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: AppConstants.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text(state.message, style: AppTextStyles.bodyText2),
                  ],
                ),
              ),
            );
          }
          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<DashboardCubit>().loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget alerts
                    BlocBuilder<BudgetAlertCubit, BudgetAlertState>(
                      builder: (context, alertState) {
                        if (alertState is BudgetAlertLoaded &&
                            alertState.alerts.isNotEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child:
                                BudgetAlertBanner(alerts: alertState.alerts),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Greeting
                    Text(
                      '${_greeting()}!',
                      style: AppTextStyles.headline2,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Here\'s your spending overview',
                      style: AppTextStyles.bodyText2,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Spending hero cards
                    _buildSpendingCards(state),
                    const SizedBox(height: AppSpacing.lg),

                    // Quick actions
                    _buildQuickActions(context),
                    const SizedBox(height: AppSpacing.lg),

                    // Recent expenses
                    _buildSectionHeader('Recent Expenses', onSeeAll: () {
                      // Navigate to expenses tab
                      context.go('/?tab=expenses');
                    }),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.recentGroups.isEmpty)
                      _buildEmptyRecentExpenses()
                    else
                      ...state.recentGroups.map((group) => _buildExpenseItem(
                            context,
                            group.displayName,
                            group.primaryCategory,
                            group.totalAmount,
                            AppConstants.categoryIcons[
                                    group.primaryCategory] ??
                                Icons.category_rounded,
                            group.group.date,
                            onTap: () => context.push(
                                '/expense-group-detail',
                                extra: group),
                          )),
                    const SizedBox(height: AppSpacing.lg),

                    // Category breakdown
                    if (state.categoryTotals.isNotEmpty) ...[
                      _buildSectionHeader('Spending by Category'),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              SpendingSummaryChart(
                                  categoryTotals: state.categoryTotals),
                              const SizedBox(height: AppSpacing.md),
                              ..._buildCategoryProgressItems(
                                  state.categoryTotals, state.totalSpent),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
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

  Widget _buildSpendingCards(DashboardLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildHeroCard(
            label: 'Total Spent',
            amount: state.totalSpent,
            icon: Icons.account_balance_wallet_rounded,
            gradient: const [AppConstants.primaryColor, AppConstants.primaryDark],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildHeroCard(
            label: 'This Month',
            amount: state.thisMonthSpent,
            icon: Icons.calendar_today_rounded,
            gradient: const [AppConstants.secondaryColor, Color(0xFF4338CA)],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required String label,
    required double amount,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
            style: AppTextStyles.amountMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionChip(
          label: 'Add Expense',
          icon: Icons.add_rounded,
          color: AppConstants.primaryColor,
          onTap: () => context.push('/add-expense'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildActionChip(
          label: 'Scan Receipt',
          icon: Icons.document_scanner_rounded,
          color: AppConstants.secondaryColor,
          onTap: () => context.go('/receipt-scanner'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildActionChip(
          label: 'Budget',
          icon: Icons.pie_chart_rounded,
          color: AppConstants.accentColor,
          onTap: () => context.go('/?tab=budget'),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headline3),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyRecentExpenses() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 48, color: AppConstants.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No expenses yet',
                style: AppTextStyles.bodyText1.copyWith(
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add your first expense to see it here',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(
    BuildContext context,
    String title,
    String category,
    double amount,
    IconData icon,
    DateTime date, {
    VoidCallback? onTap,
  }) {
    final color = AppConstants.categoryColors[category] ?? AppConstants.textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Icon(icon, color: color, size: 20),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$category \u2022 ${_formatDate(date)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text(
              '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryProgressItems(
      Map<String, double> categoryTotals, double totalSpent) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = totalSpent > 0 ? amount / totalSpent : 0.0;
      final color = AppConstants.categoryColors[category] ?? AppConstants.textTertiary;

      return _buildCategoryProgress(category, percentage, color, amount);
    }).toList();
  }

  Widget _buildCategoryProgress(
      String category, double progress, Color color, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(
                  AppConstants.categoryIcons[category] ?? Icons.category_rounded,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category,
                  style: AppTextStyles.bodyText2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
                style: AppTextStyles.bodyText2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppConstants.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
