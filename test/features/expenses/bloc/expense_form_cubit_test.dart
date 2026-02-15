import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/core/repositories/expense_group_repository.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_form_cubit.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_form_state.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockExpenseGroupRepository mockExpenseGroupRepository;
  late ExpenseFormCubit cubit;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const ExpenseGroupItemData(
      amount: 0,
      category: '',
      description: '',
    ));
    registerFallbackValue(<ExpenseGroupItemData>[]);
  });

  setUp(() {
    mockExpenseGroupRepository = MockExpenseGroupRepository();
    cubit = ExpenseFormCubit(
      mockExpenseGroupRepository,
      userId: TestData.testUserId,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ExpenseFormCubit', () {
    test('initial state is ExpenseFormInitial', () {
      expect(cubit.state, equals(ExpenseFormInitial()));
    });

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'emits [Submitting, Success] when addExpense succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.addExpenseGroup(
              userId: any(named: 'userId'),
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: any(named: 'storeName'),
              receiptImage: any(named: 'receiptImage'),
              currency: any(named: 'currency'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async => 'group_id');
        return cubit;
      },
      act: (cubit) => cubit.addExpense(
        amount: 25.50,
        category: 'Food',
        description: 'Lunch',
      ),
      expect: () => [
        ExpenseFormSubmitting(),
        ExpenseFormSuccess(),
      ],
      verify: (_) {
        verify(() => mockExpenseGroupRepository.addExpenseGroup(
              userId: TestData.testUserId,
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: null,
              receiptImage: null,
              currency: any(named: 'currency'),
              notes: null,
            )).called(1);
      },
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'emits [Submitting, Success] when addExpense with all parameters succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.addExpenseGroup(
              userId: any(named: 'userId'),
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: any(named: 'storeName'),
              receiptImage: any(named: 'receiptImage'),
              currency: any(named: 'currency'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async => 'group_id');
        return cubit;
      },
      act: (cubit) => cubit.addExpense(
        amount: 50.00,
        category: 'Transport',
        description: 'Taxi',
        date: DateTime(2026, 2, 15),
        receiptImage: 'path/to/receipt.jpg',
      ),
      expect: () => [
        ExpenseFormSubmitting(),
        ExpenseFormSuccess(),
      ],
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'emits [Submitting, Error] when addExpense fails',
      build: () {
        when(() => mockExpenseGroupRepository.addExpenseGroup(
              userId: any(named: 'userId'),
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: any(named: 'storeName'),
              receiptImage: any(named: 'receiptImage'),
              currency: any(named: 'currency'),
              notes: any(named: 'notes'),
            )).thenThrow(Exception('Database error'));
        return cubit;
      },
      act: (cubit) => cubit.addExpense(
        amount: 25.50,
        category: 'Food',
        description: 'Lunch',
      ),
      expect: () => [
        ExpenseFormSubmitting(),
        isA<ExpenseFormError>()
            .having((state) => state.message, 'message', contains('Failed to add expense')),
      ],
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'emits [Submitting, Success] when updateExpense succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.updateExpenseItem(
              itemId: any(named: 'itemId'),
              amount: any(named: 'amount'),
              category: any(named: 'category'),
              description: any(named: 'description'),
              quantity: any(named: 'quantity'),
            )).thenAnswer((_) async => Future.value());
        when(() => mockExpenseGroupRepository.updateExpenseGroup(
              groupId: any(named: 'groupId'),
              date: any(named: 'date'),
              storeName: any(named: 'storeName'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async => Future.value());
        return cubit;
      },
      act: (cubit) => cubit.updateExpense(
        itemId: 'item_1',
        groupId: 'group_1',
        amount: 30.00,
        category: 'Food',
        description: 'Updated lunch',
        date: DateTime(2026, 2, 15),
      ),
      expect: () => [
        ExpenseFormSubmitting(),
        ExpenseFormSuccess(),
      ],
      verify: (_) {
        verify(() => mockExpenseGroupRepository.updateExpenseItem(
              itemId: 'item_1',
              amount: 30.00,
              category: 'Food',
              description: 'Updated lunch',
              quantity: null,
            )).called(1);
        verify(() => mockExpenseGroupRepository.updateExpenseGroup(
              groupId: 'group_1',
              date: DateTime(2026, 2, 15),
              storeName: null,
              notes: null,
            )).called(1);
      },
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'emits [Submitting, Error] when updateExpense fails',
      build: () {
        when(() => mockExpenseGroupRepository.updateExpenseItem(
              itemId: any(named: 'itemId'),
              amount: any(named: 'amount'),
              category: any(named: 'category'),
              description: any(named: 'description'),
              quantity: any(named: 'quantity'),
            )).thenThrow(Exception('Update failed'));
        return cubit;
      },
      act: (cubit) => cubit.updateExpense(
        itemId: 'item_1',
        groupId: 'group_1',
        amount: 30.00,
        category: 'Food',
        description: 'Updated lunch',
        date: DateTime(2026, 2, 15),
      ),
      expect: () => [
        ExpenseFormSubmitting(),
        isA<ExpenseFormError>()
            .having((state) => state.message, 'message', contains('Failed to update expense')),
      ],
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'emits [Submitting, Success] when addExpensesFromReceipt succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.addExpenseGroup(
              userId: any(named: 'userId'),
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: any(named: 'storeName'),
              receiptImage: any(named: 'receiptImage'),
              currency: any(named: 'currency'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async => 'group_id');
        return cubit;
      },
      act: (cubit) => cubit.addExpensesFromReceipt(
        items: [
          const ReceiptExpenseData(
            amount: 15.00,
            category: 'Food',
            description: 'Coffee',
          ),
          const ReceiptExpenseData(
            amount: 25.00,
            category: 'Food',
            description: 'Sandwich',
          ),
        ],
        storeName: 'Starbucks',
        date: DateTime(2026, 2, 15),
        receiptImage: 'path/to/receipt.jpg',
      ),
      expect: () => [
        ExpenseFormSubmitting(),
        ExpenseFormSuccess(),
      ],
      verify: (_) {
        verify(() => mockExpenseGroupRepository.addExpenseGroup(
              userId: TestData.testUserId,
              date: DateTime(2026, 2, 15),
              items: any(named: 'items'),
              storeName: 'Starbucks',
              receiptImage: 'path/to/receipt.jpg',
              currency: any(named: 'currency'),
              notes: null,
            )).called(1);
      },
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'emits [Submitting, Error] when addExpensesFromReceipt fails',
      build: () {
        when(() => mockExpenseGroupRepository.addExpenseGroup(
              userId: any(named: 'userId'),
              date: any(named: 'date'),
              items: any(named: 'items'),
              storeName: any(named: 'storeName'),
              receiptImage: any(named: 'receiptImage'),
              currency: any(named: 'currency'),
              notes: any(named: 'notes'),
            )).thenThrow(Exception('Receipt save failed'));
        return cubit;
      },
      act: (cubit) => cubit.addExpensesFromReceipt(
        items: [
          const ReceiptExpenseData(
            amount: 15.00,
            category: 'Food',
            description: 'Coffee',
          ),
        ],
        date: DateTime(2026, 2, 15),
      ),
      expect: () => [
        ExpenseFormSubmitting(),
        isA<ExpenseFormError>()
            .having((state) => state.message, 'message', contains('Failed to save receipt items')),
      ],
    );
  });
}
