import '../models/expense_group_with_items.dart';

abstract class ExpenseGroupRepository {
  Future<List<ExpenseGroupWithItems>> getExpenseGroups(String userId);
  Future<List<ExpenseGroupWithItems>> getExpenseGroupsByDateRange(
      String userId, DateTime start, DateTime end);
  Future<List<ExpenseGroupWithItems>> getAllExpenseGroups();
  Future<ExpenseGroupWithItems?> getExpenseGroupById(String groupId);
  Future<String> addExpenseGroup({
    required String userId,
    required DateTime date,
    required List<ExpenseGroupItemData> items,
    String? storeName,
    String? receiptImage,
    String currency,
    String? notes,
  });
  Future<void> updateExpenseGroup({
    required String groupId,
    DateTime? date,
    String? storeName,
    String? notes,
  });
  Future<void> updateExpenseItem({
    required String itemId,
    double? amount,
    String? category,
    String? description,
    int? quantity,
  });
  Future<void> addItemToGroup({
    required String groupId,
    required double amount,
    required String category,
    required String description,
    int quantity,
  });
  Future<void> deleteExpenseGroup(String groupId);
  Future<void> deleteExpenseItem(String itemId);
}

class ExpenseGroupItemData {
  final double amount;
  final String category;
  final String description;
  final int quantity;

  const ExpenseGroupItemData({
    required this.amount,
    required this.category,
    required this.description,
    this.quantity = 1,
  });
}
