import 'package:equatable/equatable.dart';

abstract class BudgetFormState extends Equatable {
  const BudgetFormState();

  @override
  List<Object?> get props => [];
}

class BudgetFormInitial extends BudgetFormState {}

class BudgetFormSubmitting extends BudgetFormState {}

class BudgetFormSuccess extends BudgetFormState {}

class BudgetFormError extends BudgetFormState {
  final String message;

  const BudgetFormError(this.message);

  @override
  List<Object?> get props => [message];
}
