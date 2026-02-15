import 'package:equatable/equatable.dart';
import '../../../core/models/expense_group_with_items.dart';

abstract class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

class ExpenseListInitial extends ExpenseListState {}

class ExpenseListLoading extends ExpenseListState {}

class ExpenseListLoaded extends ExpenseListState {
  final List<ExpenseGroupWithItems> groups;

  const ExpenseListLoaded(this.groups);

  @override
  List<Object?> get props => [groups];
}

class ExpenseListError extends ExpenseListState {
  final String message;

  const ExpenseListError(this.message);

  @override
  List<Object?> get props => [message];
}
