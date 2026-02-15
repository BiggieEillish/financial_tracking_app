import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/budget_repository.dart';
import '../../../core/repositories/expense_group_repository.dart';
import '../../../core/services/notification_service.dart';
import 'budget_alert_state.dart';

class BudgetAlertCubit extends Cubit<BudgetAlertState> {
  final BudgetRepository _budgetRepository;
  final ExpenseGroupRepository _expenseGroupRepository;
  final NotificationService _notificationService = NotificationService();

  BudgetAlertCubit(this._budgetRepository, this._expenseGroupRepository)
      : super(BudgetAlertInitial());

  /// Loads all budgets for [userId], calculates the amount spent per category
  /// within each budget's period, and emits alerts for any that exceed
  /// warning (80%) or critical (100%) thresholds.
  Future<void> checkAlerts(String userId) async {
    emit(BudgetAlertLoading());
    try {
      final budgets = await _budgetRepository.getUserBudgets(userId);

      final List<BudgetWithSpent> budgetsWithSpent = [];

      for (final budget in budgets) {
        final groups = await _expenseGroupRepository.getExpenseGroupsByDateRange(
          userId,
          budget.periodStart,
          budget.periodEnd,
        );

        // Sum items matching this budget's category across all groups
        double spent = 0.0;
        for (final group in groups) {
          for (final item in group.items) {
            if (item.category == budget.category) {
              spent += item.amount * item.quantity;
            }
          }
        }

        budgetsWithSpent.add(BudgetWithSpent(
          budget: budget,
          spent: spent,
        ));
      }

      final alerts =
          _notificationService.checkBudgetThresholds(budgetsWithSpent);

      if (alerts.isNotEmpty) {
        emit(BudgetAlertLoaded(alerts));
      } else {
        emit(BudgetAlertLoaded(const []));
      }
    } catch (e) {
      emit(BudgetAlertError('Failed to check budget alerts: $e'));
    }
  }
}
