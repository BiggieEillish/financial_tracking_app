import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../bloc/expense_list_cubit.dart';
import '../bloc/expense_list_state.dart';
import '../bloc/expense_filter_cubit.dart';
import '../bloc/expense_filter_state.dart';
import '../widgets/expense_search_bar.dart';
import '../widgets/expense_filter_sheet.dart';
import '../widgets/expense_group_card.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat_rounded),
            onPressed: () => context.push('/recurring-expenses'),
            tooltip: 'Recurring Expenses',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            onPressed: () => context.go('/receipt-scanner'),
            tooltip: 'Scan Receipt',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ExpenseListCubit>().loadExpenses(),
          ),
          BlocBuilder<ExpenseFilterCubit, ExpenseFilterState>(
            builder: (context, filterState) {
              final hasFilters = filterState.selectedCategory != null ||
                  filterState.startDate != null ||
                  filterState.endDate != null;
              return IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: hasFilters ? AppConstants.primaryColor : null,
                ),
                onPressed: () => _showFilterSheet(context, filterState),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-expense');
          if (result == true && context.mounted) {
            context.read<ExpenseListCubit>().loadExpenses();
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          BlocBuilder<ExpenseFilterCubit, ExpenseFilterState>(
            builder: (context, filterState) {
              return ExpenseSearchBar(
                query: filterState.searchQuery,
                onChanged: (query) =>
                    context.read<ExpenseFilterCubit>().setSearchQuery(query),
                onClear: () =>
                    context.read<ExpenseFilterCubit>().setSearchQuery(''),
              );
            },
          ),
          BlocBuilder<ExpenseFilterCubit, ExpenseFilterState>(
            builder: (context, filterState) {
              return _buildActiveFilterChips(context, filterState);
            },
          ),
          Expanded(
            child: BlocBuilder<ExpenseListCubit, ExpenseListState>(
              builder: (context, state) {
                if (state is ExpenseListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ExpenseListError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(state.message,
                          style: AppTextStyles.bodyText2),
                    ),
                  );
                }
                if (state is ExpenseListLoaded) {
                  return BlocBuilder<ExpenseFilterCubit, ExpenseFilterState>(
                    builder: (context, filterState) {
                      final filtered = context
                          .read<ExpenseFilterCubit>()
                          .filterGroups(state.groups);

                      if (filtered.isEmpty) {
                        return _buildEmptyState(filterState);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final group = filtered[index];
                          return ExpenseGroupCard(
                            group: group,
                            onTap: () => context.push(
                                '/expense-group-detail',
                                extra: group),
                          );
                        },
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(
      BuildContext context, ExpenseFilterState filterState) {
    final chips = <Widget>[];

    if (filterState.selectedCategory != null) {
      chips.add(Chip(
        label: Text(filterState.selectedCategory!),
        avatar: Icon(
          AppConstants.categoryIcons[filterState.selectedCategory] ??
              Icons.category_rounded,
          size: 16,
        ),
        onDeleted: () => context.read<ExpenseFilterCubit>().setCategory(null),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ));
    }

    if (filterState.startDate != null || filterState.endDate != null) {
      final start = filterState.startDate;
      final end = filterState.endDate;
      String label = '';
      if (start != null && end != null) {
        label = '${start.day}/${start.month} - ${end.day}/${end.month}';
      } else if (start != null) {
        label = 'From ${start.day}/${start.month}';
      } else if (end != null) {
        label = 'Until ${end.day}/${end.month}';
      }
      chips.add(Chip(
        label: Text(label),
        avatar: const Icon(Icons.calendar_today_rounded, size: 16),
        onDeleted: () =>
            context.read<ExpenseFilterCubit>().setDateRange(null, null),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: chips,
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<ExpenseFilterCubit>().clearFilters(),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ExpenseFilterState filterState) {
    final hasFilters = filterState.searchQuery.isNotEmpty ||
        filterState.selectedCategory != null ||
        filterState.startDate != null ||
        filterState.endDate != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_rounded,
              size: 64,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilters ? 'No matching expenses' : 'No expenses yet',
              style: AppTextStyles.headline3.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters'
                  : 'Add your first expense to get started!',
              style: AppTextStyles.bodyText2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ExpenseFilterState filterState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ExpenseFilterSheet(
        selectedCategory: filterState.selectedCategory,
        startDate: filterState.startDate,
        endDate: filterState.endDate,
        onApply: (category, start, end) {
          context.read<ExpenseFilterCubit>().setCategory(category);
          context.read<ExpenseFilterCubit>().setDateRange(start, end);
        },
      ),
    );
  }
}
