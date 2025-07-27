import 'package:flutter/material.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database.dart';

class CategoryBreakdownScreen extends StatefulWidget {
  const CategoryBreakdownScreen({super.key});

  @override
  State<CategoryBreakdownScreen> createState() =>
      _CategoryBreakdownScreenState();
}

class _CategoryBreakdownScreenState extends State<CategoryBreakdownScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String _selectedPeriod = 'All Time';

  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'All Time',
  ];

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
          SnackBar(content: Text('Error loading category breakdown: $e')),
        );
      }
    }
  }

  List<Expense> _getFilteredExpenses() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final startOfQuarter =
        DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    switch (_selectedPeriod) {
      case 'This Week':
        return _expenses.where((e) => e.date.isAfter(startOfWeek)).toList();
      case 'This Month':
        return _expenses.where((e) => e.date.isAfter(startOfMonth)).toList();
      case 'Last Month':
        final endOfLastMonth = DateTime(now.year, now.month, 1);
        return _expenses
            .where((e) =>
                e.date.isAfter(startOfLastMonth) &&
                e.date.isBefore(endOfLastMonth))
            .toList();
      case 'This Quarter':
        return _expenses.where((e) => e.date.isAfter(startOfQuarter)).toList();
      case 'This Year':
        return _expenses.where((e) => e.date.isAfter(startOfYear)).toList();
      case 'All Time':
      default:
        return _expenses;
    }
  }

  Map<String, double> _getCategorySpending() {
    final filteredExpenses = _getFilteredExpenses();
    final categorySpending = <String, double>{};

    for (final expense in filteredExpenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0.0) + expense.amount;
    }

    return categorySpending;
  }

  List<MapEntry<String, double>> _getSortedCategoryData() {
    final categorySpending = _getCategorySpending();
    final sortedData = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedData;
  }

  double _getTotalSpending() {
    return _getFilteredExpenses()
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  String _getTopCategory() {
    final sortedData = _getSortedCategoryData();
    if (sortedData.isEmpty) return 'No expenses';
    return sortedData.first.key;
  }

  double _getTopCategoryPercentage() {
    final sortedData = _getSortedCategoryData();
    if (sortedData.isEmpty) return 0.0;
    final totalSpending = _getTotalSpending();
    if (totalSpending == 0) return 0.0;
    return (sortedData.first.value / totalSpending) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Breakdown'),
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
                    _buildPeriodSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSummaryCards(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCategoryChart(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCategoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
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
                value: _selectedPeriod,
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
                    setState(() => _selectedPeriod = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalSpending = _getTotalSpending();
    final topCategory = _getTopCategory();
    final topCategoryPercentage = _getTopCategoryPercentage();
    final categoryCount = _getCategorySpending().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: AppTextStyles.headline3,
        ),
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

  Widget _buildCategoryChart() {
    final sortedData = _getSortedCategoryData();
    final totalSpending = _getTotalSpending();

    if (sortedData.isEmpty) {
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
                Icons.pie_chart,
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
            Text(
              'Category Distribution',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildPieChart(sortedData, totalSpending),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 1,
                    child: _buildChartLegend(sortedData, totalSpending),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, double>> data, double total) {
    return CustomPaint(
      size: const Size(150, 150),
      painter: PieChartPainter(data, total),
    );
  }

  Widget _buildChartLegend(List<MapEntry<String, double>> data, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.take(5).map((entry) {
        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
        final color = AppConstants.categoryColors[entry.key] ?? Colors.grey;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryList() {
    final sortedData = _getSortedCategoryData();
    final totalSpending = _getTotalSpending();

    if (sortedData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Details',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: AppSpacing.md),
        ...sortedData.map((entry) {
          final percentage =
              totalSpending > 0 ? (entry.value / totalSpending) * 100 : 0.0;
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
        }).toList(),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double total;

  PieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = 0;

    for (final entry in data) {
      final sweepAngle = total > 0 ? (entry.value / total) * 2 * 3.14159 : 0.0;
      final color = AppConstants.categoryColors[entry.key] ?? Colors.grey;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
