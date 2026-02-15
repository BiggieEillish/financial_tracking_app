import '../database/database.dart';

abstract class RecurringExpenseRepository {
  Future<List<RecurringExpense>> getActiveRecurringExpenses(String userId);
  Future<List<RecurringExpense>> getDueRecurringExpenses(
      String userId, DateTime beforeDate);
  Future<void> addRecurringExpense({
    required String userId,
    required double amount,
    required String category,
    required String description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextDueDate,
    String currency,
  });
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
    String currency,
  });
  Future<void> deleteRecurringExpense(String id);
  Future<int> processDueRecurringExpenses(String userId);
}
