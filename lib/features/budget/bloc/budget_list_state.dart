import 'package:equatable/equatable.dart';
import '../../../core/database/database.dart';
import '../../../core/models/expense_group_with_items.dart';

abstract class BudgetListState extends Equatable {
  const BudgetListState();

  @override
  List<Object?> get props => [];
}

class BudgetListInitial extends BudgetListState {}

class BudgetListLoading extends BudgetListState {}

class BudgetListLoaded extends BudgetListState {
  final List<Budget> budgets;
  final List<ExpenseGroupWithItems> expenseGroups;

  const BudgetListLoaded({required this.budgets, required this.expenseGroups});

  double get totalBudget =>
      budgets.fold(0.0, (sum, budget) => sum + budget.limit);

  double get totalSpent {
    double total = 0.0;
    for (final group in expenseGroups) {
      for (final item in group.items) {
        total += item.amount * item.quantity;
      }
    }
    return total;
  }

  double getSpentForCategory(String category) {
    double total = 0.0;
    for (final group in expenseGroups) {
      for (final item in group.items) {
        if (item.category == category) {
          total += item.amount * item.quantity;
        }
      }
    }
    return total;
  }

  @override
  List<Object?> get props => [budgets, expenseGroups];
}

class BudgetListError extends BudgetListState {
  final String message;

  const BudgetListError(this.message);

  @override
  List<Object?> get props => [message];
}
