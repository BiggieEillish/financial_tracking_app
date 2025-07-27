import 'package:drift/drift.dart';
import 'database.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FinancialDatabase _database = FinancialDatabase();

  // Get database instance
  FinancialDatabase get database => _database;

  // Helper method to generate simple ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Expense operations
  Future<void> addExpense({
    required String userId,
    required double amount,
    required String category,
    required String description,
    DateTime? date,
    String? receiptImage,
  }) async {
    try {
      final expense = ExpensesCompanion.insert(
        id: _generateId(),
        userId: userId,
        amount: amount,
        category: category,
        description: description,
        date: date ?? DateTime.now(),
        receiptImage: Value(receiptImage),
      );
      await _database.insertExpense(expense);
      print('Expense saved to database: $amount for $category');
    } catch (e) {
      print('Error saving expense: $e');
      rethrow;
    }
  }

  Future<List<Expense>> getUserExpenses(String userId) async {
    try {
      final expenses = await _database.getExpensesByUserId(userId);
      // Sort by date (most recent first)
      expenses.sort((a, b) => b.date.compareTo(a.date));
      print('Loaded ${expenses.length} expenses from database');
      return expenses;
    } catch (e) {
      print('Error loading expenses: $e');
      return [];
    }
  }

  Future<List<Expense>> getUserExpensesByDateRange(
      String userId, DateTime start, DateTime end) async {
    try {
      final expenses = await _database.getExpensesByDateRange(start, end);
      // Filter by user and sort by date (most recent first)
      final userExpenses =
          expenses.where((expense) => expense.userId == userId).toList();
      userExpenses.sort((a, b) => b.date.compareTo(a.date));
      return userExpenses;
    } catch (e) {
      print('Error loading expenses by date range: $e');
      return [];
    }
  }

  Future<List<Expense>> getAllExpenses() async {
    try {
      final expenses = await _database.getAllExpenses();
      // Sort by date (most recent first)
      expenses.sort((a, b) => b.date.compareTo(a.date));
      print('Loaded ${expenses.length} expenses from database');
      return expenses;
    } catch (e) {
      print('Error loading all expenses: $e');
      return [];
    }
  }

  // Update expense
  Future<void> updateExpense({
    required String id,
    required double amount,
    required String category,
    required String description,
    required DateTime date,
    String? receiptImage,
  }) async {
    try {
      // First get the existing expense to get the userId
      final existingExpense = await _database.getExpenseById(id);
      if (existingExpense == null) {
        throw Exception('Expense not found');
      }

      final expense = ExpensesCompanion(
        id: Value(id),
        userId: Value(existingExpense.userId), // Include the userId
        amount: Value(amount),
        category: Value(category),
        description: Value(description),
        date: Value(date),
        receiptImage: Value(receiptImage),
      );
      await _database.updateExpense(expense);
      print('Expense updated in database: $amount for $category');
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      await _database.deleteExpense(id);
      print('Expense deleted from database: $id');
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // Budget operations
  Future<List<Budget>> getAllBudgets() async {
    try {
      final budgets = await _database.getAllBudgets();
      print('Loaded ${budgets.length} budgets from database');
      return budgets;
    } catch (e) {
      print('Error loading budgets: $e');
      return [];
    }
  }

  Future<List<Budget>> getUserBudgets(String userId) async {
    try {
      final budgets = await _database.getBudgetsByUserId(userId);
      print('Loaded ${budgets.length} budgets for user from database');
      return budgets;
    } catch (e) {
      print('Error loading user budgets: $e');
      return [];
    }
  }

  Future<void> addBudget({
    required String userId,
    required String category,
    required double limit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final budget = BudgetsCompanion.insert(
        id: _generateId(),
        userId: userId,
        category: category,
        limit: limit,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      await _database.insertBudget(budget);
      print('Budget saved to database: $limit for $category');
    } catch (e) {
      print('Error saving budget: $e');
      rethrow;
    }
  }

  Future<void> updateBudget({
    required String id,
    required String category,
    required double limit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final existingBudget = await _database.getAllBudgets();
      final budgetToUpdate = existingBudget.firstWhere((b) => b.id == id);

      final budget = BudgetsCompanion(
        id: Value(id),
        userId: Value(budgetToUpdate.userId),
        category: Value(category),
        limit: Value(limit),
        periodStart: Value(periodStart),
        periodEnd: Value(periodEnd),
      );
      await _database.updateBudget(budget);
      print('Budget updated in database: $limit for $category');
    } catch (e) {
      print('Error updating budget: $e');
      rethrow;
    }
  }

  // Initialize default data
  Future<void> initializeDefaultData() async {
    // This will be implemented after code generation
    print('Database initialized');
  }

  // Close database
  Future<void> close() async {
    // This will be implemented after code generation
  }
}
