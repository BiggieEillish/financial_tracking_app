import '../database/database.dart';
import '../database/database_service.dart';
import 'recurring_expense_repository.dart';

class RecurringExpenseRepositoryImpl implements RecurringExpenseRepository {
  final DatabaseService _databaseService;

  RecurringExpenseRepositoryImpl(this._databaseService);

  @override
  Future<List<RecurringExpense>> getActiveRecurringExpenses(String userId) {
    return _databaseService.getActiveRecurringExpenses(userId);
  }

  @override
  Future<List<RecurringExpense>> getDueRecurringExpenses(
      String userId, DateTime beforeDate) {
    return _databaseService.getDueRecurringExpenses(userId, beforeDate);
  }

  @override
  Future<void> addRecurringExpense({
    required String userId,
    required double amount,
    required String category,
    required String description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextDueDate,
    String currency = 'MYR',
  }) {
    return _databaseService.addRecurringExpense(
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
  }

  @override
  Future<void> updateRecurringExpense({
    required String id,
    required String userId,
    required double amount,
    required String category,
    required String description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextDueDate,
    required bool isActive,
    String currency = 'MYR',
  }) {
    return _databaseService.updateRecurringExpense(
      id: id,
      userId: userId,
      amount: amount,
      category: category,
      description: description,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      nextDueDate: nextDueDate,
      isActive: isActive,
      currency: currency,
    );
  }

  @override
  Future<void> deleteRecurringExpense(String id) {
    return _databaseService.deleteRecurringExpense(id);
  }

  @override
  Future<int> processDueRecurringExpenses(String userId) {
    return _databaseService.processDueRecurringExpenses(userId);
  }
}
