import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';

class ExpenseItemData {
  final double amount;
  final String category;
  final String description;
  final int quantity;

  const ExpenseItemData({
    required this.amount,
    required this.category,
    required this.description,
    this.quantity = 1,
  });
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FinancialDatabase _database = FinancialDatabase();

  // Get database instance
  FinancialDatabase get database => _database;

  static const _uuid = Uuid();

  // Helper method to generate unique ID
  String _generateId() {
    return _uuid.v4();
  }

  // ExpenseGroup operations
  Future<String> addExpenseGroup({
    required String userId,
    required DateTime date,
    required List<ExpenseItemData> items,
    String? storeName,
    String? receiptImage,
    String currency = 'MYR',
    String? notes,
  }) async {
    try {
      final groupId = _generateId();
      final group = ExpenseGroupsCompanion.insert(
        id: groupId,
        userId: userId,
        date: date,
        storeName: Value(storeName),
        receiptImage: Value(receiptImage),
        currency: Value(currency),
        notes: Value(notes),
        createdAt: DateTime.now(),
      );
      await _database.insertExpenseGroup(group);

      for (final item in items) {
        final expenseItem = ExpenseItemsCompanion.insert(
          id: _generateId(),
          groupId: groupId,
          amount: item.amount,
          category: item.category,
          description: item.description,
          quantity: Value(item.quantity),
        );
        await _database.insertExpenseItem(expenseItem);
      }

      print('ExpenseGroup saved: $groupId with ${items.length} items');
      return groupId;
    } catch (e) {
      print('Error saving expense group: $e');
      rethrow;
    }
  }

  Future<List<ExpenseGroup>> getUserExpenseGroups(String userId) async {
    try {
      final groups = await _database.getExpenseGroupsByUserId(userId);
      groups.sort((a, b) => b.date.compareTo(a.date));
      print('Loaded ${groups.length} expense groups from database');
      return groups;
    } catch (e) {
      print('Error loading expense groups: $e');
      return [];
    }
  }

  Future<List<ExpenseGroup>> getUserExpenseGroupsByDateRange(
      String userId, DateTime start, DateTime end) async {
    try {
      final groups =
          await _database.getExpenseGroupsByDateRange(userId, start, end);
      groups.sort((a, b) => b.date.compareTo(a.date));
      return groups;
    } catch (e) {
      print('Error loading expense groups by date range: $e');
      return [];
    }
  }

  Future<List<ExpenseGroup>> getAllExpenseGroups() async {
    try {
      final groups = await _database.getAllExpenseGroups();
      groups.sort((a, b) => b.date.compareTo(a.date));
      print('Loaded ${groups.length} expense groups from database');
      return groups;
    } catch (e) {
      print('Error loading all expense groups: $e');
      return [];
    }
  }

  Future<List<ExpenseItem>> getItemsForGroup(String groupId) async {
    try {
      return await _database.getItemsForGroup(groupId);
    } catch (e) {
      print('Error loading items for group: $e');
      return [];
    }
  }

  Future<List<ExpenseItem>> getAllExpenseItems() async {
    try {
      return await _database.getAllExpenseItems();
    } catch (e) {
      print('Error loading all expense items: $e');
      return [];
    }
  }

  Future<void> updateExpenseGroup({
    required String id,
    DateTime? date,
    String? storeName,
    String? notes,
  }) async {
    try {
      final existingGroup = await _database.getExpenseGroupById(id);
      if (existingGroup == null) {
        throw Exception('ExpenseGroup not found');
      }

      final group = ExpenseGroupsCompanion(
        id: Value(id),
        userId: Value(existingGroup.userId),
        date: Value(date ?? existingGroup.date),
        storeName: Value(storeName ?? existingGroup.storeName),
        receiptImage: Value(existingGroup.receiptImage),
        currency: Value(existingGroup.currency),
        notes: Value(notes ?? existingGroup.notes),
        createdAt: Value(existingGroup.createdAt),
      );
      await _database.updateExpenseGroup(group);
      print('ExpenseGroup updated: $id');
    } catch (e) {
      print('Error updating expense group: $e');
      rethrow;
    }
  }

  Future<void> updateExpenseItem({
    required String id,
    double? amount,
    String? category,
    String? description,
    int? quantity,
  }) async {
    try {
      final items = await _database.getAllExpenseItems();
      final existingItem = items.firstWhere((i) => i.id == id);

      final item = ExpenseItemsCompanion(
        id: Value(id),
        groupId: Value(existingItem.groupId),
        amount: Value(amount ?? existingItem.amount),
        category: Value(category ?? existingItem.category),
        description: Value(description ?? existingItem.description),
        quantity: Value(quantity ?? existingItem.quantity),
      );
      await _database.updateExpenseItem(item);
      print('ExpenseItem updated: $id');
    } catch (e) {
      print('Error updating expense item: $e');
      rethrow;
    }
  }

  Future<void> addItemToGroup({
    required String groupId,
    required double amount,
    required String category,
    required String description,
    int quantity = 1,
  }) async {
    try {
      final item = ExpenseItemsCompanion.insert(
        id: _generateId(),
        groupId: groupId,
        amount: amount,
        category: category,
        description: description,
        quantity: Value(quantity),
      );
      await _database.insertExpenseItem(item);
    } catch (e) {
      print('Error adding item to group: $e');
      rethrow;
    }
  }

  Future<void> deleteExpenseGroup(String id) async {
    try {
      // Cascade delete items first
      await _database.deleteItemsForGroup(id);
      await _database.deleteExpenseGroup(id);
      print('ExpenseGroup deleted (with items): $id');
    } catch (e) {
      print('Error deleting expense group: $e');
      rethrow;
    }
  }

  Future<void> deleteExpenseItem(String id) async {
    try {
      await _database.deleteExpenseItem(id);
      print('ExpenseItem deleted: $id');
    } catch (e) {
      print('Error deleting expense item: $e');
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

  // Delete budget
  Future<void> deleteBudget(String id) async {
    try {
      await _database.deleteBudget(id);
      print('Budget deleted from database: $id');
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  // Recurring expense operations
  Future<List<RecurringExpense>> getActiveRecurringExpenses(
      String userId) async {
    try {
      return await _database.getActiveRecurringExpenses(userId);
    } catch (e) {
      print('Error loading recurring expenses: $e');
      return [];
    }
  }

  Future<List<RecurringExpense>> getDueRecurringExpenses(
      String userId, DateTime beforeDate) async {
    try {
      return await _database.getDueRecurringExpenses(userId, beforeDate);
    } catch (e) {
      print('Error loading due recurring expenses: $e');
      return [];
    }
  }

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
  }) async {
    try {
      final expense = RecurringExpensesCompanion.insert(
        id: _generateId(),
        userId: userId,
        amount: amount,
        category: category,
        description: description,
        frequency: frequency,
        startDate: startDate,
        nextDueDate: nextDueDate,
        endDate: Value(endDate),
        currency: Value(currency),
      );
      await _database.insertRecurringExpense(expense);
    } catch (e) {
      print('Error saving recurring expense: $e');
      rethrow;
    }
  }

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
  }) async {
    try {
      final expense = RecurringExpensesCompanion(
        id: Value(id),
        userId: Value(userId),
        amount: Value(amount),
        category: Value(category),
        description: Value(description),
        frequency: Value(frequency),
        startDate: Value(startDate),
        endDate: Value(endDate),
        nextDueDate: Value(nextDueDate),
        isActive: Value(isActive),
        currency: Value(currency),
      );
      await _database.updateRecurringExpense(expense);
    } catch (e) {
      print('Error updating recurring expense: $e');
      rethrow;
    }
  }

  Future<void> deleteRecurringExpense(String id) async {
    try {
      await _database.deleteRecurringExpense(id);
    } catch (e) {
      print('Error deleting recurring expense: $e');
      rethrow;
    }
  }

  /// Process due recurring expenses: creates expense groups for any
  /// recurring expenses whose nextDueDate has passed.
  Future<int> processDueRecurringExpenses(String userId) async {
    try {
      final now = DateTime.now();
      final dueExpenses = await getDueRecurringExpenses(userId, now);
      int created = 0;

      for (final recurring in dueExpenses) {
        // Create an expense group with a single item
        await addExpenseGroup(
          userId: userId,
          date: recurring.nextDueDate,
          items: [
            ExpenseItemData(
              amount: recurring.amount,
              category: recurring.category,
              description: '${recurring.description} (recurring)',
            ),
          ],
          currency: recurring.currency,
        );

        // Calculate next due date
        final nextDate = _calculateNextDueDate(
            recurring.nextDueDate, recurring.frequency);

        // Check if we should deactivate (past end date)
        final shouldDeactivate = recurring.endDate != null &&
            nextDate.isAfter(recurring.endDate!);

        await updateRecurringExpense(
          id: recurring.id,
          userId: recurring.userId,
          amount: recurring.amount,
          category: recurring.category,
          description: recurring.description,
          frequency: recurring.frequency,
          startDate: recurring.startDate,
          endDate: recurring.endDate,
          nextDueDate: nextDate,
          isActive: !shouldDeactivate,
          currency: recurring.currency,
        );

        created++;
      }

      return created;
    } catch (e) {
      print('Error processing recurring expenses: $e');
      return 0;
    }
  }

  DateTime _calculateNextDueDate(DateTime current, String frequency) {
    switch (frequency) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      default:
        return current.add(const Duration(days: 30));
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
