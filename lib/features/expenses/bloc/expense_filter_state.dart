import 'package:equatable/equatable.dart';

class ExpenseFilterState extends Equatable {
  final String searchQuery;
  final String? selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExpenseFilterState({
    this.searchQuery = '',
    this.selectedCategory,
    this.startDate,
    this.endDate,
  });

  ExpenseFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCategory = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return ExpenseFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  @override
  List<Object?> get props => [searchQuery, selectedCategory, startDate, endDate];
}
