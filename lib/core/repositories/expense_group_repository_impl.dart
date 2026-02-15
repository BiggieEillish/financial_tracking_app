import '../database/database_service.dart';
import '../database/database.dart';
import '../models/expense_group_with_items.dart';
import 'expense_group_repository.dart';

class ExpenseGroupRepositoryImpl implements ExpenseGroupRepository {
  final DatabaseService _databaseService;

  ExpenseGroupRepositoryImpl(this._databaseService);

  Future<List<ExpenseGroupWithItems>> _assembleGroupsWithItems(
      List<ExpenseGroup> groups) async {
    if (groups.isEmpty) return [];

    // Batch load all items to avoid N+1
    final allItems = await _databaseService.getAllExpenseItems();
    final itemsByGroup = <String, List<ExpenseItem>>{};
    for (final item in allItems) {
      itemsByGroup.putIfAbsent(item.groupId, () => []).add(item);
    }

    return groups.map((group) {
      return ExpenseGroupWithItems(
        group: group,
        items: itemsByGroup[group.id] ?? [],
      );
    }).toList();
  }

  @override
  Future<List<ExpenseGroupWithItems>> getExpenseGroups(String userId) async {
    final groups = await _databaseService.getUserExpenseGroups(userId);
    return _assembleGroupsWithItems(groups);
  }

  @override
  Future<List<ExpenseGroupWithItems>> getExpenseGroupsByDateRange(
      String userId, DateTime start, DateTime end) async {
    final groups = await _databaseService.getUserExpenseGroupsByDateRange(
        userId, start, end);
    return _assembleGroupsWithItems(groups);
  }

  @override
  Future<List<ExpenseGroupWithItems>> getAllExpenseGroups() async {
    final groups = await _databaseService.getAllExpenseGroups();
    return _assembleGroupsWithItems(groups);
  }

  @override
  Future<ExpenseGroupWithItems?> getExpenseGroupById(String groupId) async {
    final groups = await _databaseService.getAllExpenseGroups();
    final group = groups.where((g) => g.id == groupId).firstOrNull;
    if (group == null) return null;

    final items = await _databaseService.getItemsForGroup(groupId);
    return ExpenseGroupWithItems(group: group, items: items);
  }

  @override
  Future<String> addExpenseGroup({
    required String userId,
    required DateTime date,
    required List<ExpenseGroupItemData> items,
    String? storeName,
    String? receiptImage,
    String currency = 'MYR',
    String? notes,
  }) {
    return _databaseService.addExpenseGroup(
      userId: userId,
      date: date,
      items: items
          .map((i) => ExpenseItemData(
                amount: i.amount,
                category: i.category,
                description: i.description,
                quantity: i.quantity,
              ))
          .toList(),
      storeName: storeName,
      receiptImage: receiptImage,
      currency: currency,
      notes: notes,
    );
  }

  @override
  Future<void> updateExpenseGroup({
    required String groupId,
    DateTime? date,
    String? storeName,
    String? notes,
  }) {
    return _databaseService.updateExpenseGroup(
      id: groupId,
      date: date,
      storeName: storeName,
      notes: notes,
    );
  }

  @override
  Future<void> updateExpenseItem({
    required String itemId,
    double? amount,
    String? category,
    String? description,
    int? quantity,
  }) {
    return _databaseService.updateExpenseItem(
      id: itemId,
      amount: amount,
      category: category,
      description: description,
      quantity: quantity,
    );
  }

  @override
  Future<void> addItemToGroup({
    required String groupId,
    required double amount,
    required String category,
    required String description,
    int quantity = 1,
  }) {
    return _databaseService.addItemToGroup(
      groupId: groupId,
      amount: amount,
      category: category,
      description: description,
      quantity: quantity,
    );
  }

  @override
  Future<void> deleteExpenseGroup(String groupId) {
    return _databaseService.deleteExpenseGroup(groupId);
  }

  @override
  Future<void> deleteExpenseItem(String itemId) {
    return _databaseService.deleteExpenseItem(itemId);
  }
}
