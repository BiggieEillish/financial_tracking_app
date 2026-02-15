import '../database/database.dart';
import '../database/database_service.dart';
import 'budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final DatabaseService _databaseService;

  BudgetRepositoryImpl(this._databaseService);

  @override
  Future<List<Budget>> getAllBudgets() {
    return _databaseService.getAllBudgets();
  }

  @override
  Future<List<Budget>> getUserBudgets(String userId) {
    return _databaseService.getUserBudgets(userId);
  }

  @override
  Future<void> addBudget({
    required String userId,
    required String category,
    required double limit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return _databaseService.addBudget(
      userId: userId,
      category: category,
      limit: limit,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  @override
  Future<void> updateBudget({
    required String id,
    required String category,
    required double limit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return _databaseService.updateBudget(
      id: id,
      category: category,
      limit: limit,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  @override
  Future<void> deleteBudget(String id) {
    return _databaseService.deleteBudget(id);
  }
}
