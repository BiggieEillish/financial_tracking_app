import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/expense_group_with_items.dart';
import 'expense_filter_state.dart';

class ExpenseFilterCubit extends Cubit<ExpenseFilterState> {
  ExpenseFilterCubit() : super(const ExpenseFilterState());

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setCategory(String? category) {
    if (category == null) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(selectedCategory: category));
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    emit(state.copyWith(
      startDate: start,
      endDate: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    ));
  }

  void clearFilters() {
    emit(const ExpenseFilterState());
  }

  List<ExpenseGroupWithItems> filterGroups(List<ExpenseGroupWithItems> groups) {
    return groups.where((group) {
      // Filter by search query
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final matchesStore =
            group.group.storeName?.toLowerCase().contains(query) ?? false;
        final matchesItem = group.items
            .any((item) => item.description.toLowerCase().contains(query));
        if (!matchesStore && !matchesItem) {
          return false;
        }
      }

      // Filter by category
      if (state.selectedCategory != null) {
        if (!group.categories.contains(state.selectedCategory)) {
          return false;
        }
      }

      // Filter by date range
      if (state.startDate != null) {
        if (group.group.date.isBefore(state.startDate!)) {
          return false;
        }
      }

      if (state.endDate != null) {
        final endOfDay = DateTime(
          state.endDate!.year,
          state.endDate!.month,
          state.endDate!.day,
          23,
          59,
          59,
        );
        if (group.group.date.isAfter(endOfDay)) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
