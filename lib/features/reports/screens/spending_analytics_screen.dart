import 'package:flutter/material.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database.dart';

class SpendingAnalyticsScreen extends StatefulWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  State<SpendingAnalyticsScreen> createState() =>
      _SpendingAnalyticsScreenState();
}

class _SpendingAnalyticsScreenState extends State<SpendingAnalyticsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String _selectedChartType = 'Daily';

  final List<String> _chartTypes = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _databaseService.getAllExpenses();
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Map<String, double> _getSpendingByPeriod() {
    final now = DateTime.now();
    final spendingByPeriod = <String, double>{};

    for (final expense in _expenses) {
      String periodKey;

      switch (_selectedChartType) {
        case 'Daily':
          periodKey = '${expense.date.day}/${expense.date.month}';
          break;
        case 'Weekly':
          final weekStart =
              expense.date.subtract(Duration(days: expense.date.weekday - 1));
          periodKey = 'Week ${weekStart.day}/${weekStart.month}';
          break;
        case 'Monthly':
          periodKey = '${expense.date.month}/${expense.date.year}';
          break;
        default:
          periodKey = '${expense.date.day}/${expense.date.month}';
      }

      spendingByPeriod[periodKey] =
          (spendingByPeriod[periodKey] ?? 0.0) + expense.amount;
    }

    return spendingByPeriod;
  }

  List<MapEntry<String, double>> _getSortedSpendingData() {
    final spendingData = _getSpendingByPeriod();
    final sortedData = spendingData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sortedData;
  }

  double _getAverageSpending() {
    final spendingData = _getSpendingByPeriod();
    if (spendingData.isEmpty) return 0.0;

    final total = spendingData.values.fold(0.0, (sum, amount) => sum + amount);
    return total / spendingData.length;
  }

  double _getMaxSpending() {
    final spendingData = _getSpendingByPeriod();
    if (spendingData.isEmpty) return 0.0;
    return spendingData.values.reduce((a, b) => a > b ? a : b);
  }

  String _getHighestSpendingPeriod() {
    final spendingData = _getSpendingByPeriod();
    if (spendingData.isEmpty) return 'No data';

    final maxEntry =
        spendingData.entries.reduce((a, b) => a.value > b.value ? a : b);
    return maxEntry.key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChartTypeSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAnalyticsSummary(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSpendingChart(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSpendingTrends(),
                  ],
                ),
              ),
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

  Widget _buildAnalyticsSummary() {
    final averageSpending = _getAverageSpending();
    final maxSpending = _getMaxSpending();
    final highestPeriod = _getHighestSpendingPeriod();
    final totalSpending =
        _expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Summary',
          style: AppTextStyles.headline3,
        ),
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
                '${AppConstants.currencySymbol}${averageSpending.toStringAsFixed(2)}',
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

  Widget _buildSpendingChart() {
    final spendingData = _getSortedSpendingData();

    if (spendingData.isEmpty) {
      return Card(
        elevation: AppConstants.defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No spending data',
                style:
                    AppTextStyles.bodyText1.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add some expenses to see spending trends',
                style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final maxValue = spendingData.fold(
        0.0, (max, entry) => entry.value > max ? entry.value : max);

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
            Text(
              '${_selectedChartType} Spending Trend',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: spendingData.map((entry) {
                  final height = maxValue > 0 ? (entry.value / maxValue) : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${AppConstants.currencySymbol}${entry.value.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height * 120,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.key,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrends() {
    final spendingData = _getSortedSpendingData();
    if (spendingData.length < 2) {
      return const SizedBox.shrink();
    }

    // Calculate trend
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
                Text(
                  'Spending Trend',
                  style: AppTextStyles.headline3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your spending is ${trend} by ${trendPercentage.toStringAsFixed(1)}% compared to previous periods.',
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
