import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/expense_group_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final ExpenseGroupRepository _expenseGroupRepository;
  final String userId;

  DashboardCubit(this._expenseGroupRepository, {required this.userId})
      : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final groups = await _expenseGroupRepository.getExpenseGroups(userId);

      double totalSpent = 0.0;
      double thisMonthSpent = 0.0;
      final categoryTotals = <String, double>{};
      final now = DateTime.now();

      for (final group in groups) {
        for (final item in group.items) {
          final itemTotal = item.amount * item.quantity;
          totalSpent += itemTotal;

          if (group.group.date.year == now.year &&
              group.group.date.month == now.month) {
            thisMonthSpent += itemTotal;
          }

          categoryTotals[item.category] =
              (categoryTotals[item.category] ?? 0.0) + itemTotal;
        }
      }

      final recentGroups = groups.take(5).toList();

      emit(DashboardLoaded(
        recentGroups: recentGroups,
        totalSpent: totalSpent,
        thisMonthSpent: thisMonthSpent,
        categoryTotals: categoryTotals,
      ));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard: $e'));
    }
  }
}
