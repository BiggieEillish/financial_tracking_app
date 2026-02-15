import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/expense_group_repository.dart';
import '../../../core/services/category_classifier_service.dart';
import 'expense_form_state.dart';

class ExpenseFormCubit extends Cubit<ExpenseFormState> {
  final ExpenseGroupRepository _expenseGroupRepository;
  final CategoryClassifierService? _classifierService;
  final String userId;

  ExpenseFormCubit(
    this._expenseGroupRepository, {
    required this.userId,
    CategoryClassifierService? classifierService,
  })  : _classifierService = classifierService,
        super(ExpenseFormInitial());

  Future<void> addExpense({
    required double amount,
    required String category,
    required String description,
    DateTime? date,
    String? receiptImage,
  }) async {
    emit(ExpenseFormSubmitting());
    try {
      await _expenseGroupRepository.addExpenseGroup(
        userId: userId,
        date: date ?? DateTime.now(),
        items: [
          ExpenseGroupItemData(
            amount: amount,
            category: category,
            description: description,
          ),
        ],
        receiptImage: receiptImage,
      );
      _classifierService?.trainOnExpense(description, category);
      _classifierService?.persistModel();
      emit(ExpenseFormSuccess());
    } catch (e) {
      emit(ExpenseFormError('Failed to add expense: $e'));
    }
  }

  Future<void> updateExpense({
    required String itemId,
    required String groupId,
    required double amount,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    emit(ExpenseFormSubmitting());
    try {
      await _expenseGroupRepository.updateExpenseItem(
        itemId: itemId,
        amount: amount,
        category: category,
        description: description,
      );
      await _expenseGroupRepository.updateExpenseGroup(
        groupId: groupId,
        date: date,
      );
      _classifierService?.trainOnExpense(description, category);
      _classifierService?.persistModel();
      emit(ExpenseFormSuccess());
    } catch (e) {
      emit(ExpenseFormError('Failed to update expense: $e'));
    }
  }

  Future<void> updateExpenseGroupWithItems({
    required String groupId,
    required DateTime date,
    required List<ExpenseItemUpdate> itemUpdates,
  }) async {
    emit(ExpenseFormSubmitting());
    try {
      for (final update in itemUpdates) {
        await _expenseGroupRepository.updateExpenseItem(
          itemId: update.itemId,
          amount: update.amount,
          category: update.category,
          description: update.description,
        );
        _classifierService?.trainOnExpense(update.description, update.category);
      }
      await _expenseGroupRepository.updateExpenseGroup(
        groupId: groupId,
        date: date,
      );
      _classifierService?.persistModel();
      emit(ExpenseFormSuccess());
    } catch (e) {
      emit(ExpenseFormError('Failed to update expense: $e'));
    }
  }

  Future<void> addExpensesFromReceipt({
    required List<ReceiptExpenseData> items,
    required DateTime date,
    String? receiptImage,
    String? storeName,
  }) async {
    emit(ExpenseFormSubmitting());
    try {
      await _expenseGroupRepository.addExpenseGroup(
        userId: userId,
        date: date,
        items: items
            .map((item) => ExpenseGroupItemData(
                  amount: item.amount,
                  category: item.category,
                  description: item.description,
                ))
            .toList(),
        storeName: storeName,
        receiptImage: receiptImage,
      );
      for (final item in items) {
        _classifierService?.trainOnExpense(item.description, item.category);
      }
      _classifierService?.persistModel();
      emit(ExpenseFormSuccess());
    } catch (e) {
      emit(ExpenseFormError('Failed to save receipt items: $e'));
    }
  }
}

class ExpenseItemUpdate {
  final String itemId;
  final double amount;
  final String category;
  final String description;

  const ExpenseItemUpdate({
    required this.itemId,
    required this.amount,
    required this.category,
    required this.description,
  });
}

class ReceiptExpenseData {
  final double amount;
  final String category;
  final String description;

  const ReceiptExpenseData({
    required this.amount,
    required this.category,
    required this.description,
  });
}
