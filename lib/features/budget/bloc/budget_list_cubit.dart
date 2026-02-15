import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/budget_repository.dart';
import '../../../core/repositories/expense_group_repository.dart';
import 'budget_list_state.dart';

class BudgetListCubit extends Cubit<BudgetListState> {
  final BudgetRepository _budgetRepository;
  final ExpenseGroupRepository _expenseGroupRepository;

  BudgetListCubit(this._budgetRepository, this._expenseGroupRepository)
      : super(BudgetListInitial());

  Future<void> loadBudgets() async {
    emit(BudgetListLoading());
    try {
      final budgets = await _budgetRepository.getAllBudgets();
      final expenseGroups = await _expenseGroupRepository.getAllExpenseGroups();
      emit(BudgetListLoaded(budgets: budgets, expenseGroups: expenseGroups));
    } catch (e) {
      emit(BudgetListError('Failed to load budgets: $e'));
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _budgetRepository.deleteBudget(id);
      await loadBudgets();
    } catch (e) {
      emit(BudgetListError('Failed to delete budget: $e'));
    }
  }
}
