import 'package:equatable/equatable.dart';
import '../../../core/database/database.dart';
import '../../../core/models/expense_group_with_items.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  final List<ExpenseGroupWithItems> groups;
  final List<Budget> budgets;
  final String selectedPeriod;

  const ReportsLoaded({
    required this.groups,
    required this.budgets,
    required this.selectedPeriod,
  });

  @override
  List<Object?> get props => [groups, budgets, selectedPeriod];

  ReportsLoaded copyWith({
    List<ExpenseGroupWithItems>? groups,
    List<Budget>? budgets,
    String? selectedPeriod,
  }) {
    return ReportsLoaded(
      groups: groups ?? this.groups,
      budgets: budgets ?? this.budgets,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }

  List<ExpenseGroupWithItems> get filteredGroups {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (selectedPeriod) {
      case 'This Week':
        final weekday = now.weekday;
        startDate = DateTime(now.year, now.month, now.day - weekday + 1);
        endDate = DateTime(now.year, now.month, now.day + (7 - weekday), 23, 59, 59);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'This Quarter':
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStartMonth = (currentQuarter - 1) * 3 + 1;
        startDate = DateTime(now.year, quarterStartMonth, 1);
        endDate = DateTime(now.year, quarterStartMonth + 3, 0, 23, 59, 59);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'All Time':
        return groups;
      default:
        return groups;
    }

    return groups.where((group) {
      return group.group.date.isAfter(startDate!.subtract(const Duration(seconds: 1))) &&
             group.group.date.isBefore(endDate!.add(const Duration(seconds: 1)));
    }).toList();
  }

  double get totalSpent {
    double total = 0.0;
    for (final group in filteredGroups) {
      for (final item in group.items) {
        total += item.amount * item.quantity;
      }
    }
    return total;
  }

  double get totalBudget {
    return budgets.fold<double>(
      0.0,
      (sum, budget) => sum + budget.limit,
    );
  }

  Map<String, double> get categorySpending {
    final Map<String, double> spending = {};
    for (final group in filteredGroups) {
      for (final item in group.items) {
        final itemTotal = item.amount * item.quantity;
        spending[item.category] = (spending[item.category] ?? 0.0) + itemTotal;
      }
    }
    return spending;
  }

  String? get topCategory {
    if (categorySpending.isEmpty) return null;

    String? top;
    double maxAmount = 0.0;

    categorySpending.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        top = category;
      }
    });

    return top;
  }

  int get totalItemCount {
    int count = 0;
    for (final group in filteredGroups) {
      count += group.items.length;
    }
    return count;
  }

  double get averageSpending {
    if (filteredGroups.isEmpty) return 0.0;
    return totalSpent / filteredGroups.length;
  }
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
