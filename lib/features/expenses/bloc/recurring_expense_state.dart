import 'package:equatable/equatable.dart';
import '../../../core/database/database.dart';

abstract class RecurringExpenseState extends Equatable {
  const RecurringExpenseState();

  @override
  List<Object?> get props => [];
}

class RecurringExpenseInitial extends RecurringExpenseState {}

class RecurringExpenseLoading extends RecurringExpenseState {}

class RecurringExpenseLoaded extends RecurringExpenseState {
  final List<RecurringExpense> recurringExpenses;

  const RecurringExpenseLoaded(this.recurringExpenses);

  @override
  List<Object?> get props => [recurringExpenses];
}

class RecurringExpenseError extends RecurringExpenseState {
  final String message;

  const RecurringExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
