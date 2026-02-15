import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/recurring_expense_repository.dart';
import 'recurring_expense_state.dart';

class RecurringExpenseCubit extends Cubit<RecurringExpenseState> {
  final RecurringExpenseRepository _recurringExpenseRepository;
  final String userId;

  RecurringExpenseCubit(this._recurringExpenseRepository,
      {required this.userId})
      : super(RecurringExpenseInitial());

  Future<void> loadRecurringExpenses() async {
    emit(RecurringExpenseLoading());
    try {
      final expenses =
          await _recurringExpenseRepository.getActiveRecurringExpenses(userId);
      emit(RecurringExpenseLoaded(expenses));
    } catch (e) {
      emit(RecurringExpenseError('Failed to load recurring expenses: $e'));
    }
  }

  Future<void> addRecurringExpense({
    required double amount,
    required String category,
    required String description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextDueDate,
    String currency = 'MYR',
  }) async {
    try {
      await _recurringExpenseRepository.addRecurringExpense(
        userId: userId,
        amount: amount,
        category: category,
        description: description,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        nextDueDate: nextDueDate,
        currency: currency,
      );
      await loadRecurringExpenses();
    } catch (e) {
      emit(RecurringExpenseError('Failed to add recurring expense: $e'));
    }
  }

  Future<void> deleteRecurringExpense(String id) async {
    try {
      await _recurringExpenseRepository.deleteRecurringExpense(id);
      await loadRecurringExpenses();
    } catch (e) {
      emit(RecurringExpenseError('Failed to delete recurring expense: $e'));
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    try {
      final currentState = state;
      if (currentState is RecurringExpenseLoaded) {
        final expense =
            currentState.recurringExpenses.firstWhere((e) => e.id == id);
        await _recurringExpenseRepository.updateRecurringExpense(
          id: expense.id,
          userId: expense.userId,
          amount: expense.amount,
          category: expense.category,
          description: expense.description,
          frequency: expense.frequency,
          startDate: expense.startDate,
          endDate: expense.endDate,
          nextDueDate: expense.nextDueDate,
          isActive: isActive,
          currency: expense.currency,
        );
        await loadRecurringExpenses();
      }
    } catch (e) {
      emit(RecurringExpenseError('Failed to update recurring expense: $e'));
    }
  }
}
