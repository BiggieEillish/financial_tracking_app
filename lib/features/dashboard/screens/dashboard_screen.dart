import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;
  Map<String, double> _categoryTotals = {};
  double _totalSpent = 0.0;
  double _thisMonthSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const userId = 'default_user';
      final expenses = await _databaseService.getUserExpenses(userId);

      // Calculate totals
      _totalSpent = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate this month's spending
      final now = DateTime.now();
      final thisMonthExpenses = expenses.where((expense) {
        return expense.date.year == now.year && expense.date.month == now.month;
      }).toList();
      _thisMonthSpent =
          thisMonthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate category totals
      _categoryTotals.clear();
      for (final expense in expenses) {
        _categoryTotals[expense.category] =
            (_categoryTotals[expense.category] ?? 0.0) + expense.amount;
      }

      // Get recent expenses (last 5)
      _expenses = expenses.take(5).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: AppTextStyles.headline2,
                    ),
                    const SizedBox(height: 16),

                    // Balance Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            'Total Spent',
                            '${AppConstants.currencySymbol}${_totalSpent.toStringAsFixed(2)}',
                            AppConstants.primaryColor,
                            Icons.account_balance_wallet,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBalanceCard(
                            'This Month',
                            '${AppConstants.currencySymbol}${_thisMonthSpent.toStringAsFixed(2)}',
                            AppConstants.successColor,
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Expenses
                    const Text(
                      'Recent Expenses',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: 16),

                    if (_expenses.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first expense to see it here!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._expenses.map((expense) => GestureDetector(
                            onTap: () => _navigateToExpenseDetail(expense),
                            child: _buildExpenseItem(
                              expense.description,
                              expense.category,
                              '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(2)}',
                              _getCategoryIcon(expense.category),
                              expense.date,
                            ),
                          )),

                    const SizedBox(height: 24),

                    // Categories Overview
                    if (_categoryTotals.isNotEmpty) ...[
                      const Text(
                        'Spending by Category',
                        style: AppTextStyles.headline3,
                      ),
                      const SizedBox(height: 16),
                      ..._buildCategoryProgressItems(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard(
      String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String title, String category, String amount,
      IconData icon, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.categoryColors[category]?.withOpacity(0.1) ??
                  Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppConstants.categoryColors[category] ?? Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$category • ${_formatDate(date)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryProgressItems() {
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = _totalSpent > 0 ? amount / _totalSpent : 0.0;
      final color = AppConstants.categoryColors[category] ?? Colors.grey;

      return _buildCategoryProgress(category, percentage, color, amount);
    }).toList();
  }

  Widget _buildCategoryProgress(
      String category, double progress, Color color, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)} (${(progress * 100).toInt()}%)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return AppConstants.categoryIcons[category] ?? Icons.category;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToExpenseDetail(Expense expense) {
    context.push('/expense-detail', extra: expense);
  }
}
