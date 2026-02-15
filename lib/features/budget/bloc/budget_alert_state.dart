import 'package:equatable/equatable.dart';
import '../../../core/services/notification_service.dart';

abstract class BudgetAlertState extends Equatable {
  const BudgetAlertState();

  @override
  List<Object?> get props => [];
}

class BudgetAlertInitial extends BudgetAlertState {}

class BudgetAlertLoading extends BudgetAlertState {}

class BudgetAlertLoaded extends BudgetAlertState {
  final List<BudgetAlert> alerts;

  const BudgetAlertLoaded(this.alerts);

  @override
  List<Object?> get props => [alerts];
}

class BudgetAlertError extends BudgetAlertState {
  final String message;

  const BudgetAlertError(this.message);

  @override
  List<Object?> get props => [message];
}
