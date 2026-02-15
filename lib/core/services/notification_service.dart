import '../database/database.dart';

enum AlertLevel { warning, critical }

class BudgetWithSpent {
  final Budget budget;
  final double spent;

  const BudgetWithSpent({required this.budget, required this.spent});
}

class BudgetAlert {
  final String category;
  final double limit;
  final double spent;
  final double percentage;
  final AlertLevel level;

  const BudgetAlert({
    required this.category,
    required this.limit,
    required this.spent,
    required this.percentage,
    required this.level,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Checks budget thresholds and returns alerts for budgets at or above 80%.
  ///
  /// Returns a [BudgetAlert] with [AlertLevel.warning] when spending is
  /// between 80% and 99% of the limit, and [AlertLevel.critical] when
  /// spending reaches 100% or more.
  List<BudgetAlert> checkBudgetThresholds(List<BudgetWithSpent> budgets) {
    final List<BudgetAlert> alerts = [];

    for (final item in budgets) {
      if (item.budget.limit <= 0) continue;

      final percentage = (item.spent / item.budget.limit) * 100;

      if (percentage >= 100) {
        alerts.add(BudgetAlert(
          category: item.budget.category,
          limit: item.budget.limit,
          spent: item.spent,
          percentage: percentage,
          level: AlertLevel.critical,
        ));
      } else if (percentage >= 80) {
        alerts.add(BudgetAlert(
          category: item.budget.category,
          limit: item.budget.limit,
          spent: item.spent,
          percentage: percentage,
          level: AlertLevel.warning,
        ));
      }
    }

    return alerts;
  }
}
