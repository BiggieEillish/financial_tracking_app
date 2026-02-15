import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/expense_group_repository.dart';
import '../../../core/repositories/budget_repository.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ExpenseGroupRepository expenseGroupRepository;
  final BudgetRepository budgetRepository;

  ReportsCubit({
    required this.expenseGroupRepository,
    required this.budgetRepository,
  }) : super(const ReportsInitial());

  Future<void> loadReports() async {
    try {
      emit(const ReportsLoading());

      final groups = await expenseGroupRepository.getAllExpenseGroups();
      final budgets = await budgetRepository.getAllBudgets();

      emit(ReportsLoaded(
        groups: groups,
        budgets: budgets,
        selectedPeriod: 'This Month',
      ));
    } catch (e) {
      emit(ReportsError('Failed to load reports: ${e.toString()}'));
    }
  }

  void changePeriod(String period) {
    if (state is ReportsLoaded) {
      final currentState = state as ReportsLoaded;
      emit(currentState.copyWith(selectedPeriod: period));
    }
  }
}
