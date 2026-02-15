import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/budget_repository.dart';
import 'budget_form_state.dart';

class BudgetFormCubit extends Cubit<BudgetFormState> {
  final BudgetRepository _budgetRepository;
  final String userId;

  BudgetFormCubit(this._budgetRepository, {required this.userId})
      : super(BudgetFormInitial());

  Future<void> addBudget({
    required String category,
    required double limit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    emit(BudgetFormSubmitting());
    try {
      await _budgetRepository.addBudget(
        userId: userId,
        category: category,
        limit: limit,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      emit(BudgetFormSuccess());
    } catch (e) {
      emit(BudgetFormError('Failed to create budget: $e'));
    }
  }

  Future<void> deleteBudget(String id) async {
    emit(BudgetFormSubmitting());
    try {
      await _budgetRepository.deleteBudget(id);
      emit(BudgetFormSuccess());
    } catch (e) {
      emit(BudgetFormError('Failed to delete budget: $e'));
    }
  }
}
