import 'package:equatable/equatable.dart';

abstract class ExpenseFormState extends Equatable {
  const ExpenseFormState();

  @override
  List<Object?> get props => [];
}

class ExpenseFormInitial extends ExpenseFormState {}

class ExpenseFormSubmitting extends ExpenseFormState {}

class ExpenseFormSuccess extends ExpenseFormState {}

class ExpenseFormError extends ExpenseFormState {
  final String message;

  const ExpenseFormError(this.message);

  @override
  List<Object?> get props => [message];
}
