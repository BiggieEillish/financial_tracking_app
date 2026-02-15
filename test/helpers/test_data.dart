import 'package:financial_planner_ui_demo/core/database/database.dart';
import 'package:financial_planner_ui_demo/core/models/expense_group_with_items.dart';

class TestData {
  static const testUserId = 'test_user_123';

  static ExpenseGroup makeExpenseGroup({
    String id = 'group_1',
    String userId = testUserId,
    DateTime? date,
    String? storeName,
    String? receiptImage,
    String currency = 'MYR',
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseGroup(
      id: id,
      userId: userId,
      date: date ?? DateTime(2026, 2, 15),
      storeName: storeName,
      receiptImage: receiptImage,
      currency: currency,
      notes: notes,
      createdAt: createdAt ?? DateTime(2026, 2, 15),
    );
  }

  static ExpenseItem makeExpenseItem({
    String id = 'item_1',
    String groupId = 'group_1',
    double amount = 25.50,
    String category = 'Food',
    String description = 'Lunch',
    int quantity = 1,
  }) {
    return ExpenseItem(
      id: id,
      groupId: groupId,
      amount: amount,
      category: category,
      description: description,
      quantity: quantity,
    );
  }

  static Budget makeBudget({
    String id = 'budget_1',
    String userId = testUserId,
    String category = 'Food',
    double limit = 500.0,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return Budget(
      id: id,
      userId: userId,
      category: category,
      limit: limit,
      periodStart: periodStart ?? DateTime(2026, 2, 1),
      periodEnd: periodEnd ?? DateTime(2026, 2, 28),
    );
  }

  static RecurringExpense makeRecurringExpense({
    String id = 'recurring_1',
    String userId = testUserId,
    double amount = 50.0,
    String category = 'Utilities',
    String description = 'Internet Bill',
    String frequency = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    bool isActive = true,
    String currency = 'MYR',
  }) {
    return RecurringExpense(
      id: id,
      userId: userId,
      amount: amount,
      category: category,
      description: description,
      frequency: frequency,
      startDate: startDate ?? DateTime(2026, 1, 1),
      endDate: endDate,
      nextDueDate: nextDueDate ?? DateTime(2026, 3, 1),
      isActive: isActive,
      currency: currency,
    );
  }

  /// Convenience method that creates an ExpenseGroupWithItems with a single item.
  static ExpenseGroupWithItems makeExpenseGroupWithItems({
    String id = 'group_1',
    String userId = testUserId,
    DateTime? date,
    String? storeName,
    String? receiptImage,
    String currency = 'MYR',
    String? notes,
    double amount = 25.50,
    String category = 'Food',
    String description = 'Lunch',
    int quantity = 1,
  }) {
    return ExpenseGroupWithItems(
      group: makeExpenseGroup(
        id: id,
        userId: userId,
        date: date,
        storeName: storeName,
        receiptImage: receiptImage,
        currency: currency,
        notes: notes,
      ),
      items: [
        makeExpenseItem(
          id: '${id}_item',
          groupId: id,
          amount: amount,
          category: category,
          description: description,
          quantity: quantity,
        ),
      ],
    );
  }

  static List<ExpenseGroupWithItems> sampleExpenseGroups() {
    return [
      ExpenseGroupWithItems(
        group: makeExpenseGroup(
          id: 'g1',
          date: DateTime(2026, 2, 15),
          storeName: 'Cafe',
        ),
        items: [
          makeExpenseItem(
            id: 'i1',
            groupId: 'g1',
            amount: 25.50,
            category: 'Food',
            description: 'Lunch at cafe',
            quantity: 1,
          ),
        ],
      ),
      ExpenseGroupWithItems(
        group: makeExpenseGroup(
          id: 'g2',
          date: DateTime(2026, 2, 14),
        ),
        items: [
          makeExpenseItem(
            id: 'i2',
            groupId: 'g2',
            amount: 45.00,
            category: 'Transport',
            description: 'Grab ride',
            quantity: 1,
          ),
        ],
      ),
      ExpenseGroupWithItems(
        group: makeExpenseGroup(
          id: 'g3',
          date: DateTime(2026, 2, 10),
          storeName: 'Shoe Store',
        ),
        items: [
          makeExpenseItem(
            id: 'i3',
            groupId: 'g3',
            amount: 120.00,
            category: 'Shopping',
            description: 'New shoes',
            quantity: 1,
          ),
        ],
      ),
      ExpenseGroupWithItems(
        group: makeExpenseGroup(
          id: 'g4',
          date: DateTime(2026, 2, 13),
          storeName: 'Coffee Shop',
        ),
        items: [
          makeExpenseItem(
            id: 'i4',
            groupId: 'g4',
            amount: 15.00,
            category: 'Food',
            description: 'Coffee',
            quantity: 1,
          ),
        ],
      ),
      ExpenseGroupWithItems(
        group: makeExpenseGroup(
          id: 'g5',
          date: DateTime(2026, 1, 28),
        ),
        items: [
          makeExpenseItem(
            id: 'i5',
            groupId: 'g5',
            amount: 200.00,
            category: 'Utilities',
            description: 'Electric bill',
            quantity: 1,
          ),
        ],
      ),
    ];
  }

  static List<Budget> sampleBudgets() {
    return [
      makeBudget(
        id: 'b1',
        category: 'Food',
        limit: 500.0,
      ),
      makeBudget(
        id: 'b2',
        category: 'Transport',
        limit: 300.0,
      ),
      makeBudget(
        id: 'b3',
        category: 'Shopping',
        limit: 200.0,
      ),
    ];
  }
}
