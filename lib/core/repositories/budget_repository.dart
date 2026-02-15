import '../database/database.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getAllBudgets();
  Future<List<Budget>> getUserBudgets(String userId);
  Future<void> addBudget({
    required String userId,
    required String category,
    required double limit,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
  Future<void> updateBudget({
    required String id,
    required String category,
    required double limit,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
  Future<void> deleteBudget(String id);
}
