import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_filter_cubit.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_filter_state.dart';
import '../../../helpers/test_data.dart';

void main() {
  late ExpenseFilterCubit cubit;

  setUp(() {
    cubit = ExpenseFilterCubit();
  });

  tearDown(() {
    cubit.close();
  });

  group('ExpenseFilterCubit', () {
    test('initial state has empty filters', () {
      expect(cubit.state.searchQuery, isEmpty);
      expect(cubit.state.selectedCategory, isNull);
      expect(cubit.state.startDate, isNull);
      expect(cubit.state.endDate, isNull);
    });

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'setSearchQuery updates search query',
      build: () => cubit,
      act: (cubit) => cubit.setSearchQuery('coffee'),
      expect: () => [
        const ExpenseFilterState(searchQuery: 'coffee'),
      ],
    );

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'setSearchQuery can be called multiple times',
      build: () => cubit,
      act: (cubit) async {
        cubit.setSearchQuery('coffee');
        cubit.setSearchQuery('lunch');
      },
      expect: () => [
        const ExpenseFilterState(searchQuery: 'coffee'),
        const ExpenseFilterState(searchQuery: 'lunch'),
      ],
    );

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'setCategory updates selected category',
      build: () => cubit,
      act: (cubit) => cubit.setCategory('Food'),
      expect: () => [
        const ExpenseFilterState(selectedCategory: 'Food'),
      ],
    );

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'setCategory with null clears category',
      build: () => cubit,
      seed: () => const ExpenseFilterState(selectedCategory: 'Food'),
      act: (cubit) => cubit.setCategory(null),
      expect: () => [
        const ExpenseFilterState(selectedCategory: null),
      ],
    );

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'setDateRange updates date range',
      build: () => cubit,
      act: (cubit) => cubit.setDateRange(
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 28),
      ),
      expect: () => [
        ExpenseFilterState(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
        ),
      ],
    );

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'setDateRange with nulls clears dates',
      build: () => cubit,
      seed: () => ExpenseFilterState(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
      ),
      act: (cubit) => cubit.setDateRange(null, null),
      expect: () => [
        const ExpenseFilterState(
          startDate: null,
          endDate: null,
        ),
      ],
    );

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'clearFilters resets to initial state',
      build: () => cubit,
      seed: () => ExpenseFilterState(
        searchQuery: 'coffee',
        selectedCategory: 'Food',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
      ),
      act: (cubit) => cubit.clearFilters(),
      expect: () => [const ExpenseFilterState()],
    );

    test('filterGroups returns all groups when no filters', () {
      final groups = TestData.sampleExpenseGroups();
      final filtered = cubit.filterGroups(groups);
      expect(filtered.length, equals(groups.length));
    });

    test('filterGroups filters by search query (case insensitive)', () {
      final groups = TestData.sampleExpenseGroups();
      cubit.setSearchQuery('lunch');
      final filtered = cubit.filterGroups(groups);
      expect(filtered.length, equals(1));
      expect(filtered.first.items.first.description, contains('Lunch'));
    });

    test('filterGroups filters by search query matching store name', () {
      final groups = [
        TestData.makeExpenseGroupWithItems(
          id: 'g1',
          description: 'Coffee',
          category: 'Food',
          storeName: 'Starbucks',
        ),
        TestData.makeExpenseGroupWithItems(
          id: 'g2',
          description: 'Groceries',
          category: 'Food',
          storeName: 'Giant',
        ),
      ];
      cubit.setSearchQuery('starbucks');
      final filtered = cubit.filterGroups(groups);
      expect(filtered.length, equals(1));
      expect(filtered.first.displayName, contains('Starbucks'));
    });

    test('filterGroups filters by category', () {
      final groups = TestData.sampleExpenseGroups();
      cubit.setCategory('Food');
      final filtered = cubit.filterGroups(groups);
      expect(filtered.length, equals(2));
      expect(filtered.every((g) => g.primaryCategory == 'Food'), isTrue);
    });

    test('filterGroups filters by start date', () {
      final groups = TestData.sampleExpenseGroups();
      cubit.setDateRange(DateTime(2026, 2, 13), null);
      final filtered = cubit.filterGroups(groups);
      expect(
        filtered.every((g) => g.group.date.isAfter(DateTime(2026, 2, 12))),
        isTrue,
      );
    });

    test('filterGroups filters by end date', () {
      final groups = TestData.sampleExpenseGroups();
      cubit.setDateRange(null, DateTime(2026, 2, 14));
      final filtered = cubit.filterGroups(groups);
      expect(
        filtered.every((g) => g.group.date.isBefore(DateTime(2026, 2, 15))),
        isTrue,
      );
    });

    test('filterGroups filters by date range', () {
      final groups = TestData.sampleExpenseGroups();
      cubit.setDateRange(DateTime(2026, 2, 10), DateTime(2026, 2, 15));
      final filtered = cubit.filterGroups(groups);
      expect(
        filtered.every((g) =>
            g.group.date.isAfter(DateTime(2026, 2, 9)) &&
            g.group.date.isBefore(DateTime(2026, 2, 16))),
        isTrue,
      );
    });

    test('filterGroups applies multiple filters simultaneously', () {
      final groups = TestData.sampleExpenseGroups();
      cubit.setSearchQuery('coffee');
      cubit.setCategory('Food');
      cubit.setDateRange(DateTime(2026, 2, 1), DateTime(2026, 2, 28));
      final filtered = cubit.filterGroups(groups);
      expect(filtered.length, equals(1));
      expect(filtered.first.items.first.description, contains('Coffee'));
      expect(filtered.first.primaryCategory, equals('Food'));
    });

    test('filterGroups returns empty list when no matches', () {
      final groups = TestData.sampleExpenseGroups();
      cubit.setSearchQuery('nonexistent');
      final filtered = cubit.filterGroups(groups);
      expect(filtered, isEmpty);
    });

    test('filterGroups handles empty groups list', () {
      cubit.setSearchQuery('coffee');
      final filtered = cubit.filterGroups([]);
      expect(filtered, isEmpty);
    });

    test('filterGroups includes groups on end date boundary', () {
      final groups = [
        TestData.makeExpenseGroupWithItems(
          id: 'g1',
          date: DateTime(2026, 2, 15, 12, 0, 0),
          description: 'Lunch',
        ),
        TestData.makeExpenseGroupWithItems(
          id: 'g2',
          date: DateTime(2026, 2, 15, 23, 30, 0),
          description: 'Dinner',
        ),
      ];
      cubit.setDateRange(DateTime(2026, 2, 15), DateTime(2026, 2, 15));
      final filtered = cubit.filterGroups(groups);
      expect(filtered.length, equals(2));
    });

    blocTest<ExpenseFilterCubit, ExpenseFilterState>(
      'can set multiple filters in sequence',
      build: () => cubit,
      act: (cubit) async {
        cubit.setSearchQuery('lunch');
        cubit.setCategory('Food');
        cubit.setDateRange(DateTime(2026, 2, 1), DateTime(2026, 2, 28));
      },
      expect: () => [
        const ExpenseFilterState(searchQuery: 'lunch'),
        const ExpenseFilterState(
          searchQuery: 'lunch',
          selectedCategory: 'Food',
        ),
        ExpenseFilterState(
          searchQuery: 'lunch',
          selectedCategory: 'Food',
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
        ),
      ],
    );
  });
}
