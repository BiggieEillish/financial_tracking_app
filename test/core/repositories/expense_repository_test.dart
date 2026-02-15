import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/core/repositories/expense_group_repository.dart';
import 'package:financial_planner_ui_demo/core/repositories/expense_group_repository_impl.dart';
import 'package:financial_planner_ui_demo/core/models/expense_group_with_items.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockDatabaseService mockDatabaseService;
  late ExpenseGroupRepositoryImpl repository;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    repository = ExpenseGroupRepositoryImpl(mockDatabaseService);
  });

  group('ExpenseGroupRepositoryImpl', () {
    group('getExpenseGroups', () {
      test('returns expense groups from database service', () async {
        final groups = [
          TestData.makeExpenseGroup(id: 'g1'),
          TestData.makeExpenseGroup(id: 'g2'),
        ];
        final items = [
          TestData.makeExpenseItem(id: 'i1', groupId: 'g1'),
          TestData.makeExpenseItem(id: 'i2', groupId: 'g2'),
        ];

        when(() => mockDatabaseService.getUserExpenseGroups(any()))
            .thenAnswer((_) async => groups);
        when(() => mockDatabaseService.getAllExpenseItems())
            .thenAnswer((_) async => items);

        final result = await repository.getExpenseGroups(TestData.testUserId);

        expect(result, isA<List<ExpenseGroupWithItems>>());
        expect(result.length, 2);
        expect(result[0].group.id, 'g1');
        expect(result[1].group.id, 'g2');
        verify(() => mockDatabaseService.getUserExpenseGroups(TestData.testUserId))
            .called(1);
      });

      test('returns empty list when no groups', () async {
        when(() => mockDatabaseService.getUserExpenseGroups(any()))
            .thenAnswer((_) async => []);

        final result = await repository.getExpenseGroups(TestData.testUserId);

        expect(result, isEmpty);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.getUserExpenseGroups(any()))
            .thenThrow(Exception('DB error'));

        expect(
          () => repository.getExpenseGroups(TestData.testUserId),
          throwsException,
        );
      });
    });

    group('getExpenseGroupsByDateRange', () {
      test('returns expense groups within date range', () async {
        final groups = [TestData.makeExpenseGroup()];
        final items = [TestData.makeExpenseItem()];
        final start = DateTime(2026, 2, 1);
        final end = DateTime(2026, 2, 28);

        when(() => mockDatabaseService.getUserExpenseGroupsByDateRange(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => groups);
        when(() => mockDatabaseService.getAllExpenseItems())
            .thenAnswer((_) async => items);

        final result = await repository.getExpenseGroupsByDateRange(
          TestData.testUserId,
          start,
          end,
        );

        expect(result, isA<List<ExpenseGroupWithItems>>());
        expect(result.length, 1);
        verify(() => mockDatabaseService.getUserExpenseGroupsByDateRange(
              TestData.testUserId,
              start,
              end,
            )).called(1);
      });
    });

    group('getAllExpenseGroups', () {
      test('returns all expense groups', () async {
        final groups = TestData.sampleExpenseGroups()
            .map((g) => g.group)
            .toList();
        final items = TestData.sampleExpenseGroups()
            .expand((g) => g.items)
            .toList();

        when(() => mockDatabaseService.getAllExpenseGroups())
            .thenAnswer((_) async => groups);
        when(() => mockDatabaseService.getAllExpenseItems())
            .thenAnswer((_) async => items);

        final result = await repository.getAllExpenseGroups();

        expect(result, isA<List<ExpenseGroupWithItems>>());
        expect(result.length, 5);
      });
    });

    group('getExpenseGroupById', () {
      test('returns single expense group with items', () async {
        final group = TestData.makeExpenseGroup(id: 'g1');
        final items = [
          TestData.makeExpenseItem(id: 'i1', groupId: 'g1'),
          TestData.makeExpenseItem(id: 'i2', groupId: 'g1'),
        ];

        when(() => mockDatabaseService.getAllExpenseGroups())
            .thenAnswer((_) async => [group]);
        when(() => mockDatabaseService.getItemsForGroup('g1'))
            .thenAnswer((_) async => items);

        final result = await repository.getExpenseGroupById('g1');

        expect(result, isNotNull);
        expect(result!.group.id, 'g1');
        expect(result.items.length, 2);
        verify(() => mockDatabaseService.getItemsForGroup('g1')).called(1);
      });

      test('returns null when group not found', () async {
        when(() => mockDatabaseService.getAllExpenseGroups())
            .thenAnswer((_) async => []);

        final result = await repository.getExpenseGroupById('nonexistent');

        expect(result, isNull);
      });
    });

    group('addExpenseGroup', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.addExpenseGroup(
              userId: any(named: 'userId'),
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: any(named: 'storeName'),
              receiptImage: any(named: 'receiptImage'),
              currency: any(named: 'currency'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async => 'group_123');

        final result = await repository.addExpenseGroup(
          userId: TestData.testUserId,
          date: DateTime(2026, 2, 15),
          items: [
            ExpenseGroupItemData(
              amount: 25.50,
              category: 'Food',
              description: 'Lunch',
              quantity: 1,
            ),
          ],
          storeName: 'Cafe',
          currency: 'MYR',
        );

        expect(result, 'group_123');
        verify(() => mockDatabaseService.addExpenseGroup(
              userId: TestData.testUserId,
              date: DateTime(2026, 2, 15),
              items: any(named: 'items'),
              storeName: 'Cafe',
              receiptImage: null,
              currency: 'MYR',
              notes: null,
            )).called(1);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.addExpenseGroup(
              userId: any(named: 'userId'),
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: any(named: 'storeName'),
              receiptImage: any(named: 'receiptImage'),
              currency: any(named: 'currency'),
              notes: any(named: 'notes'),
            )).thenThrow(Exception('Add failed'));

        expect(
          () => repository.addExpenseGroup(
            userId: TestData.testUserId,
            date: DateTime(2026, 2, 15),
            items: [
              ExpenseGroupItemData(
                amount: 25.50,
                category: 'Food',
                description: 'Lunch',
                quantity: 1,
              ),
            ],
          ),
          throwsException,
        );
      });
    });

    group('updateExpenseGroup', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.updateExpenseGroup(
              id: any(named: 'id'),
              date: any(named: 'date'),
              storeName: any(named: 'storeName'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async {});

        await repository.updateExpenseGroup(
          groupId: 'group_1',
          date: DateTime(2026, 2, 16),
          storeName: 'Updated Store',
          notes: 'Updated notes',
        );

        verify(() => mockDatabaseService.updateExpenseGroup(
              id: 'group_1',
              date: DateTime(2026, 2, 16),
              storeName: 'Updated Store',
              notes: 'Updated notes',
            )).called(1);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.updateExpenseGroup(
              id: any(named: 'id'),
              date: any(named: 'date'),
              storeName: any(named: 'storeName'),
              notes: any(named: 'notes'),
            )).thenThrow(Exception('Update failed'));

        expect(
          () => repository.updateExpenseGroup(
            groupId: 'group_1',
            date: DateTime(2026, 2, 16),
          ),
          throwsException,
        );
      });
    });

    group('updateExpenseItem', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.updateExpenseItem(
              id: any(named: 'id'),
              amount: any(named: 'amount'),
              category: any(named: 'category'),
              description: any(named: 'description'),
              quantity: any(named: 'quantity'),
            )).thenAnswer((_) async {});

        await repository.updateExpenseItem(
          itemId: 'item_1',
          amount: 30.00,
          category: 'Food',
          description: 'Updated lunch',
          quantity: 2,
        );

        verify(() => mockDatabaseService.updateExpenseItem(
              id: 'item_1',
              amount: 30.00,
              category: 'Food',
              description: 'Updated lunch',
              quantity: 2,
            )).called(1);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.updateExpenseItem(
              id: any(named: 'id'),
              amount: any(named: 'amount'),
              category: any(named: 'category'),
              description: any(named: 'description'),
              quantity: any(named: 'quantity'),
            )).thenThrow(Exception('Update failed'));

        expect(
          () => repository.updateExpenseItem(
            itemId: 'item_1',
            amount: 30.00,
          ),
          throwsException,
        );
      });
    });

    group('deleteExpenseGroup', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.deleteExpenseGroup(any()))
            .thenAnswer((_) async {});

        await repository.deleteExpenseGroup('group_1');

        verify(() => mockDatabaseService.deleteExpenseGroup('group_1'))
            .called(1);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.deleteExpenseGroup(any()))
            .thenThrow(Exception('Delete failed'));

        expect(
          () => repository.deleteExpenseGroup('group_1'),
          throwsException,
        );
      });
    });

    group('deleteExpenseItem', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.deleteExpenseItem(any()))
            .thenAnswer((_) async {});

        await repository.deleteExpenseItem('item_1');

        verify(() => mockDatabaseService.deleteExpenseItem('item_1'))
            .called(1);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.deleteExpenseItem(any()))
            .thenThrow(Exception('Delete failed'));

        expect(
          () => repository.deleteExpenseItem('item_1'),
          throwsException,
        );
      });
    });

    group('addItemToGroup', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.addItemToGroup(
              groupId: any(named: 'groupId'),
              amount: any(named: 'amount'),
              category: any(named: 'category'),
              description: any(named: 'description'),
              quantity: any(named: 'quantity'),
            )).thenAnswer((_) async {});

        await repository.addItemToGroup(
          groupId: 'group_1',
          amount: 15.00,
          category: 'Food',
          description: 'Coffee',
          quantity: 1,
        );

        verify(() => mockDatabaseService.addItemToGroup(
              groupId: 'group_1',
              amount: 15.00,
              category: 'Food',
              description: 'Coffee',
              quantity: 1,
            )).called(1);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.addItemToGroup(
              groupId: any(named: 'groupId'),
              amount: any(named: 'amount'),
              category: any(named: 'category'),
              description: any(named: 'description'),
              quantity: any(named: 'quantity'),
            )).thenThrow(Exception('Add item failed'));

        expect(
          () => repository.addItemToGroup(
            groupId: 'group_1',
            amount: 15.00,
            category: 'Food',
            description: 'Coffee',
          ),
          throwsException,
        );
      });
    });
  });
}
