import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/expense_group_repository.dart';
import 'expense_list_state.dart';

class ExpenseListCubit extends Cubit<ExpenseListState> {
  final ExpenseGroupRepository _expenseGroupRepository;
  final String userId;

  ExpenseListCubit(this._expenseGroupRepository, {required this.userId})
      : super(ExpenseListInitial());

  Future<void> loadExpenses() async {
    emit(ExpenseListLoading());
    try {
      final groups = await _expenseGroupRepository.getExpenseGroups(userId);
      emit(ExpenseListLoaded(groups));
    } catch (e) {
      emit(ExpenseListError('Failed to load expenses: $e'));
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _expenseGroupRepository.deleteExpenseGroup(groupId);
      await loadExpenses();
    } catch (e) {
      emit(ExpenseListError('Failed to delete expense: $e'));
    }
  }
}
