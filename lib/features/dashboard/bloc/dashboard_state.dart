import 'package:equatable/equatable.dart';
import '../../../core/models/expense_group_with_items.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<ExpenseGroupWithItems> recentGroups;
  final double totalSpent;
  final double thisMonthSpent;
  final Map<String, double> categoryTotals;

  const DashboardLoaded({
    required this.recentGroups,
    required this.totalSpent,
    required this.thisMonthSpent,
    required this.categoryTotals,
  });

  @override
  List<Object?> get props =>
      [recentGroups, totalSpent, thisMonthSpent, categoryTotals];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
